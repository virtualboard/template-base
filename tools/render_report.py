#!/usr/bin/env python3
"""Render a VirtualBoard HTML report with strict, context-aware escaping."""

from __future__ import annotations

import argparse
import base64
import html
import json
import math
import os
import re
import tempfile
from dataclasses import dataclass, field
from html.parser import HTMLParser
from pathlib import Path
from typing import Any
from urllib.parse import urlsplit


PLACEHOLDER_RE = re.compile(r"{{([A-Z][A-Z0-9_]*)}}")
SECTION_RE = re.compile(
    r"{{#([A-Z][A-Z0-9_]*)}}(.*?){{/\1}}",
    flags=re.DOTALL,
)
INCLUDE_RE = re.compile(r"{{INCLUDE:\s*([^}]+?)\s*}}")
SAFE_NAME_RE = re.compile(r"^[A-Z][A-Z0-9_]*$")
SAFE_TEMPLATE_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*\.html$")

RAW_HTML_NAMES = {
    "REPORT_TITLE_HTML",
    "NAV_LINKS",
    "MAIN_CONTENT",
    "MATURITY_BAND",
    "FOOTER_NOTE_BLOCK",
}

TOKEN_RE = re.compile(r"^[A-Za-z0-9_-]+(?: [A-Za-z0-9_-]+)*$")
DATA_IMAGE_RE = re.compile(
    r"^data:image/(?:png|jpeg|gif|webp);base64,([A-Za-z0-9+/]+={0,2})$"
)
ATTRIBUTE_RE = re.compile(
    r"\b(?P<name>[A-Za-z_:][A-Za-z0-9_.:-]*)\s*=\s*"
    r"(?P<quote>[\"'])(?P<value>.*?)(?P=quote)",
    re.DOTALL,
)
SCRIPT_RE = re.compile(r"<script\b[^>]*>(.*?)</script\s*>", re.IGNORECASE | re.DOTALL)

SAFE_HTML_TAGS = {
    "a", "blockquote", "br", "code", "div", "em", "h3", "h4", "hr",
    "li", "ol", "p", "pre", "span", "strong", "table", "tbody", "td",
    "th", "thead", "tr", "ul",
}
VOID_HTML_TAGS = {"br", "hr"}


class RenderError(ValueError):
    """Raised when a template or data document violates the render contract."""


@dataclass(frozen=True)
class Context:
    scalars: dict[str, Any] = field(default_factory=dict)
    html: dict[str, str] = field(default_factory=dict)
    json_values: dict[str, Any] = field(default_factory=dict)
    urls: dict[str, str] = field(default_factory=dict)
    numbers: dict[str, int | float] = field(default_factory=dict)
    tokens: dict[str, str] = field(default_factory=dict)
    lists: dict[str, list[dict[str, Any]]] = field(default_factory=dict)

    def merged(self, child: "Context") -> "Context":
        return Context(
            scalars={**self.scalars, **child.scalars},
            html={**self.html, **child.html},
            json_values={**self.json_values, **child.json_values},
            urls={**self.urls, **child.urls},
            numbers={**self.numbers, **child.numbers},
            tokens={**self.tokens, **child.tokens},
            lists={**self.lists, **child.lists},
        )


def _safe_url(value: str, label: str) -> str:
    if value != value.strip() or any(ord(character) < 0x20 for character in value):
        raise RenderError(f"{label} contains whitespace or control characters")
    data_match = DATA_IMAGE_RE.fullmatch(value)
    if data_match:
        try:
            base64.b64decode(data_match.group(1), validate=True)
        except ValueError as exc:
            raise RenderError(f"{label} contains invalid base64 image data") from exc
        return value
    if value.startswith("//") or "\\" in value:
        raise RenderError(f"{label} is not an allowed URL")
    parsed = urlsplit(value)
    if parsed.scheme:
        if parsed.scheme not in {"http", "https"} or not parsed.netloc:
            raise RenderError(f"{label} uses a forbidden URL scheme")
    elif parsed.netloc:
        raise RenderError(f"{label} is a protocol-relative URL")
    return value


class _SafeHTML(HTMLParser):
    """Validate and normalize a deliberately small markup fragment."""

    def __init__(self, label: str):
        super().__init__(convert_charrefs=False)
        self.label = label
        self.output: list[str] = []
        self.stack: list[str] = []

    def _attributes(self, tag: str, attrs: list[tuple[str, str | None]]) -> str:
        rendered: list[str] = []
        seen: set[str] = set()
        for raw_name, raw_value in attrs:
            name = raw_name.lower()
            if name in seen or raw_value is None:
                raise RenderError(f"{self.label} has an invalid {name!r} attribute")
            seen.add(name)
            value = raw_value
            if name == "href" and tag == "a":
                value = _safe_url(value, f"{self.label}.{name}")
            elif name in {"class", "id", "data-sev", "role", "rel", "target"}:
                if not TOKEN_RE.fullmatch(value):
                    raise RenderError(f"{self.label}.{name} is not a safe token")
            elif name in {"title", "aria-label"}:
                pass
            elif name in {"colspan", "rowspan"} and value.isdigit():
                pass
            else:
                raise RenderError(f"{self.label} forbids attribute {name!r} on <{tag}>")
            rendered.append(f' {name}="{html.escape(value, quote=True)}"')
        return "".join(rendered)

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        tag = tag.lower()
        if tag not in SAFE_HTML_TAGS:
            raise RenderError(f"{self.label} forbids HTML tag <{tag}>")
        self.output.append(f"<{tag}{self._attributes(tag, attrs)}>")
        if tag not in VOID_HTML_TAGS:
            self.stack.append(tag)

    def handle_startendtag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        tag = tag.lower()
        if tag not in VOID_HTML_TAGS:
            raise RenderError(f"{self.label} forbids self-closing <{tag}> tag")
        self.output.append(f"<{tag}{self._attributes(tag, attrs)}>")

    def handle_endtag(self, tag: str) -> None:
        tag = tag.lower()
        if not self.stack or self.stack[-1] != tag:
            raise RenderError(f"{self.label} has mismatched closing tag </{tag}>")
        self.stack.pop()
        self.output.append(f"</{tag}>")

    def handle_data(self, data: str) -> None:
        self.output.append(html.escape(data, quote=False))

    def handle_entityref(self, name: str) -> None:
        self.output.append(f"&{name};")

    def handle_charref(self, name: str) -> None:
        self.output.append(f"&#{name};")

    def handle_comment(self, data: str) -> None:
        raise RenderError(f"{self.label} forbids HTML comments")

    def handle_decl(self, decl: str) -> None:
        raise RenderError(f"{self.label} forbids HTML declarations")

    def unknown_decl(self, data: str) -> None:
        raise RenderError(f"{self.label} forbids HTML declarations")

    def handle_pi(self, data: str) -> None:
        raise RenderError(f"{self.label} forbids processing instructions")

    def finish(self) -> str:
        if self.stack:
            raise RenderError(f"{self.label} has unclosed HTML tag <{self.stack[-1]}>")
        return "".join(self.output)


def _sanitize_html(value: str, label: str) -> str:
    parser = _SafeHTML(label)
    parser.feed(value)
    parser.close()
    return parser.finish()


def _mapping(value: Any, label: str) -> dict[str, Any]:
    if value is None:
        return {}
    if not isinstance(value, dict):
        raise RenderError(f"{label} must be an object")
    for key in value:
        if not isinstance(key, str) or not SAFE_NAME_RE.fullmatch(key):
            raise RenderError(f"invalid placeholder name in {label}: {key!r}")
    return value


def parse_context(value: Any, label: str = "data") -> Context:
    if not isinstance(value, dict):
        raise RenderError(f"{label} must be an object")
    allowed = {"scalars", "html", "json", "urls", "numbers", "tokens", "lists"}
    unknown = sorted(set(value) - allowed)
    if unknown:
        raise RenderError(f"unknown keys in {label}: {', '.join(unknown)}")

    scalars = _mapping(value.get("scalars"), f"{label}.scalars")
    html_values = _mapping(value.get("html"), f"{label}.html")
    json_values = _mapping(value.get("json"), f"{label}.json")
    url_values = _mapping(value.get("urls"), f"{label}.urls")
    number_values = _mapping(value.get("numbers"), f"{label}.numbers")
    token_values = _mapping(value.get("tokens"), f"{label}.tokens")
    raw_lists = _mapping(value.get("lists"), f"{label}.lists")

    namespaces = {
        "scalars": set(scalars),
        "html": set(html_values),
        "json": set(json_values),
        "urls": set(url_values),
        "numbers": set(number_values),
        "tokens": set(token_values),
    }
    names = sorted(set().union(*namespaces.values()))
    for name in names:
        owners = [namespace for namespace, values in namespaces.items() if name in values]
        if len(owners) > 1:
            raise RenderError(f"{label}.{name} appears in multiple typed sections: {', '.join(owners)}")

    for name, raw_value in html_values.items():
        if not (
            name.endswith("_HTML")
            or name.startswith("LIST_EMPTY_")
            or name in RAW_HTML_NAMES
        ):
            raise RenderError(f"{name} is not an approved raw HTML placeholder")
        if not isinstance(raw_value, str):
            raise RenderError(f"{label}.html.{name} must be a string")
        html_values[name] = _sanitize_html(raw_value, f"{label}.html.{name}")
    for name in json_values:
        if not name.endswith("_JSON"):
            raise RenderError(f"{name} is not an approved JSON placeholder")
    for name, raw_value in url_values.items():
        if not isinstance(raw_value, str):
            raise RenderError(f"{label}.urls.{name} must be a string")
        url_values[name] = _safe_url(raw_value, f"{label}.urls.{name}")
    for name, raw_value in number_values.items():
        if isinstance(raw_value, bool) or not isinstance(raw_value, (int, float)):
            raise RenderError(f"{label}.numbers.{name} must be a finite number")
        if not math.isfinite(raw_value):
            raise RenderError(f"{label}.numbers.{name} must be a finite number")
        if name.endswith("_PERCENT") and not 0 <= raw_value <= 100:
            raise RenderError(f"{label}.numbers.{name} must be between 0 and 100")
    for name, raw_value in token_values.items():
        if not isinstance(raw_value, str) or not TOKEN_RE.fullmatch(raw_value):
            raise RenderError(f"{label}.tokens.{name} must contain safe tokens")

    parsed_lists: dict[str, list[dict[str, Any]]] = {}
    for name, items in raw_lists.items():
        if not isinstance(items, list):
            raise RenderError(f"{label}.lists.{name} must be an array")
        parsed_items: list[dict[str, Any]] = []
        for index, item in enumerate(items):
            if not isinstance(item, dict):
                raise RenderError(f"{label}.lists.{name}[{index}] must be an object")
            # Validate now; retain the typed document for expansion later.
            parse_context(item, f"{label}.lists.{name}[{index}]")
            parsed_items.append(item)
        parsed_lists[name] = parsed_items

    return Context(
        scalars=scalars,
        html=html_values,
        json_values=json_values,
        urls=url_values,
        numbers=number_values,
        tokens=token_values,
        lists=parsed_lists,
    )


def _within(path: Path, root: Path) -> bool:
    try:
        path.resolve().relative_to(root.resolve())
        return True
    except ValueError:
        return False


def resolve_includes(text: str, template_root: Path, stack: tuple[Path, ...] = ()) -> str:
    """Inline partials while preventing traversal and include cycles."""

    def replace(match: re.Match[str]) -> str:
        relative = Path(match.group(1).strip())
        if relative.is_absolute() or ".." in relative.parts:
            raise RenderError(f"unsafe include path: {relative}")
        include_path = (template_root / relative).resolve()
        if not _within(include_path, template_root):
            raise RenderError(f"include escapes template root: {relative}")
        if include_path in stack:
            chain = " -> ".join(str(path.name) for path in (*stack, include_path))
            raise RenderError(f"include cycle: {chain}")
        try:
            included = include_path.read_text(encoding="utf-8")
        except FileNotFoundError as exc:
            raise RenderError(f"missing include: {relative}") from exc
        return resolve_includes(included, template_root, (*stack, include_path))

    previous = None
    while previous != text:
        previous = text
        text = INCLUDE_RE.sub(replace, text)
    return text


def _json_for_script(value: Any) -> str:
    serialized = json.dumps(value, ensure_ascii=True, separators=(",", ":"))
    return serialized.replace("</", "<\\/")


def placeholder_contexts(text: str) -> dict[str, str]:
    """Return the required typed section for placeholders in sensitive attributes."""

    text = re.sub(r"<!--.*?-->", "", text, flags=re.DOTALL)
    contexts: dict[str, str] = {}
    for attribute in ATTRIBUTE_RE.finditer(text):
        attribute_name = attribute.group("name").lower()
        if attribute_name in {"href", "src"}:
            required = "url"
        elif attribute_name == "style":
            required = "number"
        elif attribute_name == "class" or attribute_name.startswith("data-"):
            required = "token"
        else:
            continue
        for name in PLACEHOLDER_RE.findall(attribute.group("value")):
            previous = contexts.get(name)
            if previous is not None and previous != required:
                raise RenderError(
                    f"placeholder {name} is used in conflicting {previous} and {required} contexts"
                )
            contexts[name] = required
    for script in SCRIPT_RE.finditer(text):
        for name in PLACEHOLDER_RE.findall(script.group(1)):
            previous = contexts.get(name)
            if previous is not None and previous != "json":
                raise RenderError(
                    f"placeholder {name} is used in conflicting {previous} and json contexts"
                )
            contexts[name] = "json"
    return contexts


def _render_placeholders(
    text: str, context: Context, sensitive_contexts: dict[str, str]
) -> str:
    missing: set[str] = set()

    def replace(match: re.Match[str]) -> str:
        name = match.group(1)
        required = sensitive_contexts.get(name)
        if required == "url":
            if name not in context.urls:
                raise RenderError(f"placeholder {name} must be supplied in the urls section")
            return html.escape(context.urls[name], quote=True)
        if required == "number":
            if name not in context.numbers:
                raise RenderError(f"placeholder {name} must be supplied in the numbers section")
            return format(context.numbers[name], ".15g")
        if required == "token":
            if name not in context.tokens:
                raise RenderError(f"placeholder {name} must be supplied in the tokens section")
            return html.escape(context.tokens[name], quote=True)
        if required == "json":
            if name not in context.json_values:
                raise RenderError(f"placeholder {name} must be supplied in the json section")
            return _json_for_script(context.json_values[name])
        if name in context.html:
            return context.html[name]
        if name in context.json_values:
            return _json_for_script(context.json_values[name])
        if name in context.scalars:
            value = context.scalars[name]
            if value is None:
                return ""
            if isinstance(value, (dict, list)):
                raise RenderError(
                    f"scalar {name} must not be an object or array; use the json section"
                )
            return html.escape(str(value), quote=True)
        if name in context.urls:
            return html.escape(context.urls[name], quote=True)
        if name in context.numbers:
            return format(context.numbers[name], ".15g")
        if name in context.tokens:
            return html.escape(context.tokens[name], quote=True)
        missing.add(name)
        return match.group(0)

    rendered = PLACEHOLDER_RE.sub(replace, text)
    if missing:
        raise RenderError(f"missing placeholders: {', '.join(sorted(missing))}")
    return rendered


def render_text(
    text: str,
    context: Context,
    sensitive_contexts: dict[str, str] | None = None,
) -> str:
    """Expand list blocks and then render all scalar placeholders."""

    if sensitive_contexts is None:
        sensitive_contexts = placeholder_contexts(text)
    while True:
        match = SECTION_RE.search(text)
        if not match:
            break
        name, body = match.group(1), match.group(2)
        if name not in context.lists:
            raise RenderError(f"missing list: {name}")
        fragments: list[str] = []
        for index, item in enumerate(context.lists[name]):
            child = parse_context(item, f"lists.{name}[{index}]")
            fragments.append(render_text(body, context.merged(child), sensitive_contexts))
        text = f"{text[:match.start()]}{''.join(fragments)}{text[match.end():]}"
    return _render_placeholders(text, context, sensitive_contexts)


def load_data(path: Path) -> Context:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise RenderError(f"data file not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise RenderError(f"invalid JSON in {path}: {exc}") from exc
    return parse_context(document)


def _value_names(context: Context) -> set[str]:
    return (
        set(context.scalars)
        | set(context.html)
        | set(context.json_values)
        | set(context.urls)
        | set(context.numbers)
        | set(context.tokens)
    )


def validate_context_usage(text: str, context: Context, label: str = "data") -> None:
    """Reject unused keys and list names, including inside list item documents."""

    placeholder_names = set(PLACEHOLDER_RE.findall(text))
    section_bodies = {
        match.group(1): match.group(2) for match in SECTION_RE.finditer(text)
    }
    unused_values = sorted(_value_names(context) - placeholder_names)
    if unused_values:
        raise RenderError(f"unused values in {label}: {', '.join(unused_values)}")
    unused_lists = sorted(set(context.lists) - set(section_bodies))
    if unused_lists:
        raise RenderError(f"unused lists in {label}: {', '.join(unused_lists)}")
    for list_name, items in context.lists.items():
        body = section_bodies[list_name]
        for index, item in enumerate(items):
            child = parse_context(item, f"{label}.lists.{list_name}[{index}]")
            validate_context_usage(body, child, f"{label}.lists.{list_name}[{index}]")


def _placeholder_type(name: str, sensitive: dict[str, str]) -> str:
    if name in sensitive:
        return sensitive[name]
    if name.endswith("_JSON"):
        return "json"
    if name.endswith("_HTML") or name.startswith("LIST_EMPTY_") or name in RAW_HTML_NAMES:
        return "html"
    return "scalar"


def describe_template(template_path: Path, template_root: Path) -> dict[str, Any]:
    if not _within(template_path, template_root):
        raise RenderError("template must be inside the report template directory")
    try:
        text = template_path.read_text(encoding="utf-8")
    except FileNotFoundError as exc:
        raise RenderError(f"template not found: {template_path}") from exc
    text = resolve_includes(text, template_root, (template_path.resolve(),))
    sensitive = placeholder_contexts(text)
    sections = {
        match.group(1): match.group(2) for match in SECTION_RE.finditer(text)
    }

    def grouped(names: set[str]) -> dict[str, list[str]]:
        result: dict[str, list[str]] = {}
        for name in sorted(names):
            result.setdefault(_placeholder_type(name, sensitive), []).append(name)
        return result

    root_text = SECTION_RE.sub("", text)
    root_values = grouped(set(PLACEHOLDER_RE.findall(root_text)))
    list_values = {
        name: grouped(set(PLACEHOLDER_RE.findall(body)))
        for name, body in sorted(sections.items())
    }
    defaults = [
        name
        for name in ("BRAND_NAME", "BRAND_TAGLINE", "BRAND_LOGO_DATAURI")
        if any(name in values for values in root_values.values())
    ]
    return {
        "template": template_path.name,
        "defaults": defaults,
        "values": root_values,
        "lists": list_values,
    }


def with_brand_defaults(context: Context, template_root: Path) -> Context:
    logo_path = template_root / "_partials" / "astucia-logo.b64.txt"
    if "BRAND_LOGO_DATAURI" in context.scalars:
        raise RenderError("BRAND_LOGO_DATAURI must be supplied in the urls section")
    defaults = {
        "BRAND_NAME": "Astucia",
        "BRAND_TAGLINE": "AI Development Studio",
    }
    url_defaults = {
        "BRAND_LOGO_DATAURI": _safe_url(
            logo_path.read_text(encoding="utf-8").strip(),
            "brand default logo",
        )
    }
    return Context(
        scalars={**defaults, **context.scalars},
        html=context.html,
        json_values=context.json_values,
        urls={**url_defaults, **context.urls},
        numbers=context.numbers,
        tokens=context.tokens,
        lists=context.lists,
    )


def render_template(template_path: Path, template_root: Path, context: Context) -> str:
    if not _within(template_path, template_root):
        raise RenderError("template must be inside the report template directory")
    try:
        text = template_path.read_text(encoding="utf-8")
    except FileNotFoundError as exc:
        raise RenderError(f"template not found: {template_path}") from exc
    text = resolve_includes(text, template_root, (template_path.resolve(),))
    validate_context_usage(text, context)
    return render_text(text, with_brand_defaults(context, template_root))


def write_atomic(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        mode="w",
        encoding="utf-8",
        dir=path.parent,
        prefix=f".{path.name}.",
        delete=False,
    ) as handle:
        handle.write(content)
        temporary = Path(handle.name)
    os.chmod(temporary, 0o644)
    os.replace(temporary, path)


def parse_args() -> argparse.Namespace:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--template", required=True, help="template basename")
    parser.add_argument("--data", type=Path, help="typed JSON render data")
    parser.add_argument("--output", type=Path, help="output HTML path")
    parser.add_argument("--stdout", action="store_true", help="write rendered HTML to stdout")
    parser.add_argument(
        "--describe",
        action="store_true",
        help="print the template's generated typed placeholder contract as JSON",
    )
    parser.add_argument(
        "--template-root",
        type=Path,
        default=root / "templates" / "reports" / "html",
        help=argparse.SUPPRESS,
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    template_name = args.template
    if not template_name.endswith(".html"):
        template_name = f"{template_name}.html"
    if not SAFE_TEMPLATE_RE.fullmatch(template_name):
        raise SystemExit(f"invalid template name: {args.template}")
    template_path = (args.template_root / template_name).resolve()
    template_root = args.template_root.resolve()
    if args.describe:
        if args.data is not None or args.output is not None or args.stdout:
            raise SystemExit("--describe cannot be combined with data or output options")
        try:
            description = describe_template(template_path, template_root)
        except RenderError as exc:
            raise SystemExit(f"describe failed: {exc}") from exc
        print(json.dumps(description, indent=2, sort_keys=True))
        return 0
    if args.data is None:
        raise SystemExit("--data is required unless --describe is used")
    if args.stdout == (args.output is not None):
        raise SystemExit("exactly one of --output or --stdout is required")
    try:
        context = load_data(args.data)
        rendered = render_template(
            template_path,
            template_root,
            context,
        )
    except RenderError as exc:
        raise SystemExit(f"render failed: {exc}") from exc
    if args.stdout:
        print(rendered, end="")
    else:
        write_atomic(args.output, rendered)
        print(f"Rendered {template_name} to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
