#!/usr/bin/env python3
"""Publish an exact GitHub asset set through a source-bound draft release.

This helper deliberately has no release-deletion operation. A failed or
ambiguous run leaves its validated draft in place so a later run can reconcile
the asset inventory without ever cleaning up a release that may be public.
"""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import os
import re
import stat
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any, Dict, Iterable, List, Mapping, Optional, Sequence, Tuple


API_ROOT = "https://api.github.com"
UPLOAD_ROOT = "https://uploads.github.com"
API_VERSION = "2022-11-28"
MAX_JSON_BYTES = 4 * 1024 * 1024
MAX_ASSET_BYTES = 256 * 1024 * 1024
REPOSITORY_RE = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
TAG_RE = re.compile(r"^v[0-9]+\.[0-9]+\.[0-9]+$")
SHA_RE = re.compile(r"^[0-9a-f]{40}$")
ASSET_NAME_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")


class ReleaseError(RuntimeError):
    """A fail-closed release contract violation."""


class TransportError(ReleaseError):
    """The server may have applied a state-changing request."""


@dataclasses.dataclass(frozen=True)
class Response:
    status: int
    payload: Any
    headers: Mapping[str, str]


@dataclasses.dataclass(frozen=True)
class AssetSpec:
    path: Path
    name: str
    size: int
    sha256: str


def _bounded_read(stream: Any, limit: int = MAX_JSON_BYTES) -> bytes:
    content = stream.read(limit + 1)
    if len(content) > limit:
        raise ReleaseError("GitHub API response exceeded the bounded JSON limit")
    return content


def _decode_json(content: bytes, context: str) -> Any:
    if not content:
        return None
    try:
        return json.loads(content.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ReleaseError(f"{context} returned malformed JSON") from error


class GitHubAPI:
    """Small bounded client for only the release endpoints this workflow uses."""

    def __init__(self, token: str) -> None:
        if not token or "\n" in token or "\r" in token:
            raise ReleaseError("GitHub token is missing or malformed")
        self._token = token

    def _request(
        self,
        method: str,
        url: str,
        *,
        body: Optional[bytes] = None,
        content_type: str = "application/vnd.github+json",
        timeout: int = 30,
    ) -> Response:
        parsed = urllib.parse.urlsplit(url)
        if parsed.scheme != "https" or parsed.hostname not in {
            "api.github.com",
            "uploads.github.com",
        }:
            raise ReleaseError("refusing an untrusted GitHub API URL")
        headers = {
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {self._token}",
            "Content-Type": content_type,
            "User-Agent": "virtualboard-source-bound-release/1",
            "X-GitHub-Api-Version": API_VERSION,
        }
        request = urllib.request.Request(
            url, data=body, headers=headers, method=method
        )
        attempts = 3 if method == "GET" else 1
        for attempt in range(attempts):
            try:
                with urllib.request.urlopen(request, timeout=timeout) as response:
                    content = _bounded_read(response)
                    return Response(
                        response.status,
                        _decode_json(content, f"GitHub {method}"),
                        {key.lower(): value for key, value in response.headers.items()},
                    )
            except urllib.error.HTTPError as error:
                try:
                    content = _bounded_read(error)
                finally:
                    error.close()
                return Response(
                    error.code,
                    _decode_json(content, f"GitHub {method} HTTP {error.code}"),
                    {key.lower(): value for key, value in error.headers.items()},
                )
            except (urllib.error.URLError, TimeoutError, OSError) as error:
                if attempt + 1 < attempts:
                    time.sleep(2**attempt)
                    continue
                if method == "GET":
                    raise ReleaseError(f"GitHub read failed: {error}") from error
                raise TransportError(
                    f"GitHub {method} outcome is ambiguous: {error}"
                ) from error
        raise AssertionError("unreachable request loop")

    @staticmethod
    def _repo_path(repository: str) -> str:
        owner, name = repository.split("/", 1)
        return "/repos/{}/{}".format(
            urllib.parse.quote(owner, safe=""), urllib.parse.quote(name, safe="")
        )

    def get_release_by_tag(self, repository: str, tag: str) -> Response:
        path = self._repo_path(repository)
        encoded_tag = urllib.parse.quote(tag, safe="")
        return self._request("GET", f"{API_ROOT}{path}/releases/tags/{encoded_tag}")

    def get_release(self, repository: str, release_id: int) -> Response:
        path = self._repo_path(repository)
        return self._request("GET", f"{API_ROOT}{path}/releases/{release_id}")

    def create_release(self, repository: str, payload: Mapping[str, Any]) -> Response:
        path = self._repo_path(repository)
        return self._request(
            "POST",
            f"{API_ROOT}{path}/releases",
            body=json.dumps(payload, separators=(",", ":")).encode("utf-8"),
        )

    def update_release(
        self, repository: str, release_id: int, payload: Mapping[str, Any]
    ) -> Response:
        path = self._repo_path(repository)
        return self._request(
            "PATCH",
            f"{API_ROOT}{path}/releases/{release_id}",
            body=json.dumps(payload, separators=(",", ":")).encode("utf-8"),
        )

    def list_assets(self, repository: str, release_id: int) -> List[Mapping[str, Any]]:
        path = self._repo_path(repository)
        assets: List[Mapping[str, Any]] = []
        for page in range(1, 11):
            response = self._request(
                "GET",
                f"{API_ROOT}{path}/releases/{release_id}/assets?per_page=100&page={page}",
            )
            if response.status != 200 or not isinstance(response.payload, list):
                raise ReleaseError(
                    f"could not list draft assets (GitHub returned HTTP {response.status})"
                )
            page_assets = response.payload
            if not all(isinstance(item, dict) for item in page_assets):
                raise ReleaseError("GitHub returned a malformed release asset list")
            assets.extend(page_assets)
            if len(page_assets) < 100:
                return assets
        raise ReleaseError("release asset inventory exceeded 1000 entries")

    def delete_asset(self, repository: str, asset_id: int) -> Response:
        path = self._repo_path(repository)
        return self._request(
            "DELETE", f"{API_ROOT}{path}/releases/assets/{asset_id}"
        )

    def upload_asset(
        self, repository: str, release_id: int, name: str, content: bytes
    ) -> Response:
        owner, repo = repository.split("/", 1)
        path = "/repos/{}/{}/releases/{}/assets".format(
            urllib.parse.quote(owner, safe=""),
            urllib.parse.quote(repo, safe=""),
            release_id,
        )
        query = urllib.parse.urlencode({"name": name})
        return self._request(
            "POST",
            f"{UPLOAD_ROOT}{path}?{query}",
            body=content,
            content_type="application/octet-stream",
            timeout=120,
        )


def inspect_assets(paths: Iterable[str]) -> List[AssetSpec]:
    assets: List[AssetSpec] = []
    names = set()
    for raw_path in paths:
        path = Path(raw_path)
        try:
            metadata = path.lstat()
        except OSError as error:
            raise ReleaseError(f"cannot inspect release asset {path}: {error}") from error
        if not stat.S_ISREG(metadata.st_mode) or path.is_symlink():
            raise ReleaseError(f"release asset is not a regular unlinked file: {path}")
        name = path.name
        if not ASSET_NAME_RE.fullmatch(name):
            raise ReleaseError(f"release asset name is not allowed: {name!r}")
        if name in names:
            raise ReleaseError(f"duplicate local release asset name: {name}")
        if metadata.st_size <= 0 or metadata.st_size > MAX_ASSET_BYTES:
            raise ReleaseError(
                f"release asset {name} must be between 1 and {MAX_ASSET_BYTES} bytes"
            )
        try:
            content = path.read_bytes()
        except OSError as error:
            raise ReleaseError(f"cannot read release asset {path}: {error}") from error
        if len(content) != metadata.st_size:
            raise ReleaseError(f"release asset changed while it was inspected: {path}")
        assets.append(
            AssetSpec(path, name, len(content), hashlib.sha256(content).hexdigest())
        )
        names.add(name)
    if not assets:
        raise ReleaseError("at least one release asset is required")
    return assets


class ReleasePublisher:
    def __init__(
        self,
        api: Any,
        repository: str,
        tag: str,
        source_sha: str,
        title: str,
        assets: Sequence[AssetSpec],
    ) -> None:
        if not REPOSITORY_RE.fullmatch(repository):
            raise ReleaseError("repository must be an owner/name pair")
        if not TAG_RE.fullmatch(tag):
            raise ReleaseError("release tag must be an exact vMAJOR.MINOR.PATCH tag")
        if not SHA_RE.fullmatch(source_sha):
            raise ReleaseError("source SHA must contain exactly 40 lowercase hex characters")
        if not title or "\n" in title or "\r" in title:
            raise ReleaseError("release title is missing or malformed")
        if not assets:
            raise ReleaseError("at least one release asset is required")
        self.api = api
        self.repository = repository
        self.tag = tag
        self.source_sha = source_sha
        self.title = title
        self.assets = {asset.name: asset for asset in assets}
        if len(self.assets) != len(assets):
            raise ReleaseError("local release asset names must be unique")
        self.marker = (
            "<!-- virtualboard-release-draft:v1 "
            f"repo={repository} tag={tag} source-sha={source_sha} -->"
        )

    @staticmethod
    def _release_id(payload: Any) -> int:
        if not isinstance(payload, dict):
            raise ReleaseError("GitHub returned a malformed release object")
        release_id = payload.get("id")
        if not isinstance(release_id, int) or isinstance(release_id, bool) or release_id <= 0:
            raise ReleaseError("GitHub release object has no valid numeric ID")
        return release_id

    def _validate_identity(self, payload: Any, *, require_draft: bool) -> int:
        release_id = self._release_id(payload)
        assert isinstance(payload, dict)
        if payload.get("tag_name") != self.tag:
            raise ReleaseError("GitHub release tag changed during publication")
        if payload.get("draft") is not require_draft:
            if require_draft and payload.get("draft") is False:
                raise ReleaseError(
                    f"published release {self.tag} already exists; refusing to replace it"
                )
            state = "draft" if require_draft else "published"
            raise ReleaseError(f"GitHub release is not the expected {state} release")
        if payload.get("target_commitish") != self.source_sha:
            raise ReleaseError("same-tag draft is bound to a different source SHA")
        if payload.get("name") != self.title:
            raise ReleaseError("same-tag draft has a different release title")
        if payload.get("prerelease") is not False:
            raise ReleaseError("same-tag release has unexpected prerelease state")
        body = payload.get("body")
        if not isinstance(body, str) or not body.splitlines() or body.splitlines()[0] != self.marker:
            raise ReleaseError("same-tag draft is missing the exact source-binding marker")
        return release_id

    def _read_by_tag(self) -> Optional[Mapping[str, Any]]:
        response = self.api.get_release_by_tag(self.repository, self.tag)
        if response.status == 404:
            return None
        if response.status != 200 or not isinstance(response.payload, dict):
            raise ReleaseError(
                "could not inspect the target release "
                f"(GitHub returned HTTP {response.status})"
            )
        return response.payload

    def _bound_draft_after_ambiguous_create(self) -> Mapping[str, Any]:
        payload = self._read_by_tag()
        if payload is None:
            raise ReleaseError(
                "draft creation outcome was ambiguous and no same-tag draft was found"
            )
        self._validate_identity(payload, require_draft=True)
        return payload

    def _ensure_draft(self) -> Mapping[str, Any]:
        existing = self._read_by_tag()
        if existing is not None:
            self._validate_identity(existing, require_draft=True)
            return existing
        create_payload = {
            "tag_name": self.tag,
            "target_commitish": self.source_sha,
            "name": self.title,
            "body": self.marker,
            "draft": True,
            "prerelease": False,
            "generate_release_notes": True,
        }
        try:
            response = self.api.create_release(self.repository, create_payload)
        except TransportError:
            return self._bound_draft_after_ambiguous_create()
        if response.status == 201:
            try:
                self._validate_identity(response.payload, require_draft=True)
                return response.payload
            except ReleaseError:
                return self._bound_draft_after_ambiguous_create()
        if response.status == 422 or response.status >= 500:
            return self._bound_draft_after_ambiguous_create()
        raise ReleaseError(f"draft creation failed with HTTP {response.status}")

    def _require_bound_draft(self, release_id: int) -> Mapping[str, Any]:
        response = self.api.get_release(self.repository, release_id)
        if response.status != 200 or not isinstance(response.payload, dict):
            raise ReleaseError(
                f"could not revalidate draft {release_id} (GitHub returned HTTP {response.status})"
            )
        actual_id = self._validate_identity(response.payload, require_draft=True)
        if actual_id != release_id:
            raise ReleaseError("GitHub release identity changed during publication")
        return response.payload

    @staticmethod
    def _asset_id(payload: Mapping[str, Any]) -> int:
        asset_id = payload.get("id")
        if not isinstance(asset_id, int) or isinstance(asset_id, bool) or asset_id <= 0:
            raise ReleaseError("GitHub returned a release asset without a valid ID")
        return asset_id

    @staticmethod
    def _remote_matches(payload: Mapping[str, Any], expected: AssetSpec) -> bool:
        if payload.get("name") != expected.name:
            return False
        if payload.get("state") != "uploaded" or payload.get("size") != expected.size:
            return False
        digest = payload.get("digest")
        if digest not in (None, "", f"sha256:{expected.sha256}"):
            return False
        return True

    def _asset_inventory(self, release_id: int) -> List[Mapping[str, Any]]:
        assets = self.api.list_assets(self.repository, release_id)
        for asset in assets:
            if not isinstance(asset, dict):
                raise ReleaseError("GitHub returned a malformed release asset")
            self._asset_id(asset)
            if not isinstance(asset.get("name"), str):
                raise ReleaseError("GitHub returned a release asset without a name")
        return assets

    def _delete_reconcilable_asset(
        self, release_id: int, asset: Mapping[str, Any]
    ) -> None:
        asset_id = self._asset_id(asset)
        self._require_bound_draft(release_id)
        try:
            response = self.api.delete_asset(self.repository, asset_id)
        except TransportError:
            remaining_ids = {
                self._asset_id(item) for item in self._asset_inventory(release_id)
            }
            if asset_id not in remaining_ids:
                return
            raise ReleaseError(
                f"asset {asset_id} deletion was ambiguous; validated draft was left intact"
            )
        if response.status not in (204, 404):
            raise ReleaseError(
                f"could not reconcile draft asset {asset_id} (HTTP {response.status})"
            )

    def _upload_asset(self, release_id: int, expected: AssetSpec) -> None:
        self._require_bound_draft(release_id)
        content = expected.path.read_bytes()
        if len(content) != expected.size or hashlib.sha256(content).hexdigest() != expected.sha256:
            raise ReleaseError(f"local release asset changed before upload: {expected.path}")
        try:
            response = self.api.upload_asset(
                self.repository, release_id, expected.name, content
            )
        except TransportError:
            response = None
        if response is not None and response.status == 201:
            if not isinstance(response.payload, dict) or not self._remote_matches(
                response.payload, expected
            ):
                raise ReleaseError(f"GitHub returned a mismatched upload for {expected.name}")
            return
        matches = [
            asset
            for asset in self._asset_inventory(release_id)
            if asset.get("name") == expected.name
        ]
        if len(matches) == 1 and self._remote_matches(matches[0], expected):
            return
        status = "ambiguous" if response is None else f"HTTP {response.status}"
        raise ReleaseError(
            f"upload of {expected.name} ended with {status}; validated draft was retained"
        )

    def _reconcile_assets(self, release_id: int) -> None:
        self._require_bound_draft(release_id)
        remote = self._asset_inventory(release_id)
        by_name: Dict[str, List[Mapping[str, Any]]] = {}
        for asset in remote:
            by_name.setdefault(str(asset["name"]), []).append(asset)

        retained = set()
        for name, copies in by_name.items():
            expected = self.assets.get(name)
            if expected is not None and len(copies) == 1 and self._remote_matches(
                copies[0], expected
            ):
                retained.add(name)
                continue
            for asset in copies:
                self._delete_reconcilable_asset(release_id, asset)

        for name in sorted(self.assets):
            if name not in retained:
                self._upload_asset(release_id, self.assets[name])

        self._require_bound_draft(release_id)
        final_assets = self._asset_inventory(release_id)
        if len(final_assets) != len(self.assets):
            raise ReleaseError("draft asset count does not match the complete local inventory")
        seen = set()
        for asset in final_assets:
            name = str(asset["name"])
            expected = self.assets.get(name)
            if expected is None or name in seen or not self._remote_matches(asset, expected):
                raise ReleaseError("draft asset names, sizes, states, or digests do not match")
            seen.add(name)
        if seen != set(self.assets):
            raise ReleaseError("draft is missing one or more expected release assets")

    def _recover_publish_outcome(self, release_id: int) -> Mapping[str, Any]:
        response = self.api.get_release(self.repository, release_id)
        if response.status != 200 or not isinstance(response.payload, dict):
            by_tag = self._read_by_tag()
            if by_tag is None:
                raise ReleaseError(
                    "publication outcome is unknown; no release cleanup was attempted"
                )
            payload = by_tag
        else:
            payload = response.payload
        actual_id = self._release_id(payload)
        if actual_id != release_id:
            raise ReleaseError("publication resolved to an unexpected release ID")
        if payload.get("draft") is True:
            self._validate_identity(payload, require_draft=True)
            raise ReleaseError("publication did not complete; the validated draft was retained")
        self._validate_identity(payload, require_draft=False)
        return payload

    def publish(self) -> int:
        draft = self._ensure_draft()
        release_id = self._validate_identity(draft, require_draft=True)
        self._reconcile_assets(release_id)
        self._require_bound_draft(release_id)
        try:
            response = self.api.update_release(
                self.repository, release_id, {"draft": False}
            )
        except TransportError:
            published = self._recover_publish_outcome(release_id)
        else:
            if response.status == 200:
                try:
                    self._validate_identity(response.payload, require_draft=False)
                    published = response.payload
                except ReleaseError:
                    published = self._recover_publish_outcome(release_id)
            else:
                published = self._recover_publish_outcome(release_id)
        self._validate_identity(published, require_draft=False)
        final_assets = self._asset_inventory(release_id)
        if len(final_assets) != len(self.assets):
            raise ReleaseError("published release asset count changed after publication")
        seen = set()
        for asset in final_assets:
            name = str(asset.get("name"))
            expected = self.assets.get(name)
            if expected is None or name in seen or not self._remote_matches(asset, expected):
                raise ReleaseError("published release asset inventory changed after publication")
            seen.add(name)
        if seen != set(self.assets):
            raise ReleaseError("published release is missing an expected asset")
        return release_id


def parse_args(argv: Optional[Sequence[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--source-sha", required=True)
    parser.add_argument("--title", required=True)
    parser.add_argument("--asset", action="append", required=True)
    return parser.parse_args(argv)


def main(argv: Optional[Sequence[str]] = None) -> int:
    args = parse_args(argv)
    token = os.environ.get("GH_TOKEN", "")
    try:
        assets = inspect_assets(args.asset)
        publisher = ReleasePublisher(
            GitHubAPI(token),
            args.repository,
            args.tag,
            args.source_sha,
            args.title,
            assets,
        )
        release_id = publisher.publish()
    except ReleaseError as error:
        print(f"release publication refused: {error}", file=sys.stderr)
        return 1
    print(
        f"published {args.tag} from source {args.source_sha} as release {release_id} "
        f"with {len(assets)} verified assets"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
