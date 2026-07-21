#!/usr/bin/env bash

# worktree-setup.sh - Create or inspect a feature worktree.
# Canonical branch format: feat/FTR-####-feature-slug

set -Eeuo pipefail
export GIT_TERMINAL_PROMPT=${GIT_TERMINAL_PROMPT:-0}

JSON_OUTPUT=false
NO_FETCH=false
POSITIONAL_WORKTREE_BASE=
POSITIONAL_BASE_BRANCH=

json_escape() {
    local value=${1-}
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//$'\n'/\\n}
    value=${value//$'\r'/\\r}
    value=${value//$'\t'/\\t}
    printf '%s' "$value"
}

usage() {
    cat <<EOF
Usage: $0 <feature_id> <feature_slug> [worktree_base_path] [base_branch] [options]

Arguments:
  feature_id          Feature ID (for example, FTR-0042)
  feature_slug        Kebab-case slug from the feature filename
  worktree_base_path  Optional worktree root (default: XDG state directory)
  base_branch         Optional base branch or commit (default: auto-detect)

Options:
  --worktree-path PATH  Set the worktree root
  --base-branch REF     Set the base branch or commit
  --no-fetch            Do not fetch origin before resolving refs
  --json                Emit one machine-readable result object on stdout
  --help, -h            Show this help message

Environment:
  VIRTUALBOARD_WORKTREE_PATH  Default worktree root
  VIRTUALBOARD_BASE_BRANCH    Default base branch or commit
EOF
}

die() {
    local message=$1
    local code=${2:-1}
    if [[ "$JSON_OUTPUT" == true ]]; then
        printf '{"success":false,"error":"%s"}\n' "$(json_escape "$message")"
    else
        echo "Error: $message" >&2
    fi
    exit "$code"
}

on_error() {
    local code=$1
    local line=$2
    local command=$3
    trap - ERR
    die "command failed at line $line (exit $code): $command" "$code"
}
trap 'on_error "$?" "$LINENO" "$BASH_COMMAND"' ERR

info() {
    echo "$*" >&2
}

emit_result() {
    local status=$1
    local current_branch=$2
    local commits_ahead=$3
    local uncommitted=$4
    local last_commit=$5

    if [[ "$JSON_OUTPUT" == true ]]; then
        printf '{"success":true,"feature_id":"%s","branch":"%s","base_ref":"%s","worktree_path":"%s","status":"%s","commits_ahead":%s,"uncommitted_files":%s,"last_commit":"%s"}\n' \
            "$(json_escape "$FEATURE_ID")" \
            "$(json_escape "$current_branch")" \
            "$(json_escape "$BASE_REF")" \
            "$(json_escape "$WORKTREE_DIR")" \
            "$(json_escape "$status")" \
            "$commits_ahead" \
            "$uncommitted" \
            "$(json_escape "$last_commit")"
    else
        echo
        echo "Worktree ready"
        echo "  Feature: $FEATURE_ID"
        echo "  Branch: $current_branch"
        echo "  Base ref: $BASE_REF"
        echo "  Directory: $WORKTREE_DIR"
        echo "  Status: $status"
        echo "  Commits ahead: $commits_ahead"
        echo "  Uncommitted files: $uncommitted"
        echo "WORKTREE_PATH=$WORKTREE_DIR"
        echo "WORKTREE_STATUS=$status"
        echo "COMMITS_AHEAD=$commits_ahead"
        echo "UNCOMMITTED_FILES=$uncommitted"
    fi
}

if [[ ${1-} == --help || ${1-} == -h ]]; then
    usage
    exit 0
fi

if [[ $# -lt 2 ]]; then
    usage >&2
    exit 1
fi

FEATURE_ID=$1
FEATURE_SLUG=$2
shift 2

while [[ $# -gt 0 ]]; do
    case "$1" in
        --worktree-path)
            [[ $# -ge 2 ]] || die "--worktree-path requires a value"
            POSITIONAL_WORKTREE_BASE=$2
            shift 2
            ;;
        --base-branch)
            [[ $# -ge 2 ]] || die "--base-branch requires a value"
            POSITIONAL_BASE_BRANCH=$2
            shift 2
            ;;
        --no-fetch)
            NO_FETCH=true
            shift
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        --*)
            die "unknown option '$1'"
            ;;
        *)
            if [[ -z "$POSITIONAL_WORKTREE_BASE" ]]; then
                POSITIONAL_WORKTREE_BASE=$1
            elif [[ -z "$POSITIONAL_BASE_BRANCH" ]]; then
                POSITIONAL_BASE_BRANCH=$1
            else
                die "unexpected positional argument '$1'"
            fi
            shift
            ;;
    esac
done

[[ "$FEATURE_ID" =~ ^FTR-[0-9]{4}$ ]] || die "invalid feature ID '$FEATURE_ID'; expected FTR-####"
[[ "$FEATURE_SLUG" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || die "invalid feature slug '$FEATURE_SLUG'; expected kebab-case"
IFS=- read -r -a SLUG_WORDS <<< "$FEATURE_SLUG"
(( ${#SLUG_WORDS[@]} <= 6 )) || die "feature slug exceeds the configured six-word limit: $FEATURE_SLUG"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "current directory is not inside a Git worktree"
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_ROOT=$(cd -- "$REPO_ROOT" && pwd -P)
REPO_NAME=$(basename -- "$REPO_ROOT")

DEFAULT_WORKTREE_PATH="${XDG_STATE_HOME:-${HOME:-/tmp}/.local/state}/virtualboard/worktrees"
WORKTREE_BASE=${POSITIONAL_WORKTREE_BASE:-${VIRTUALBOARD_WORKTREE_PATH:-$DEFAULT_WORKTREE_PATH}}
REQUESTED_BASE=${POSITIONAL_BASE_BRANCH:-${VIRTUALBOARD_BASE_BRANCH:-}}

BRANCH_NAME="feat/${FEATURE_ID}-${FEATURE_SLUG}"
git check-ref-format --branch "$BRANCH_NAME" >/dev/null 2>&1 || die "generated branch name is invalid: $BRANCH_NAME"

mkdir -p -- "$WORKTREE_BASE"
WORKTREE_BASE=$(cd -- "$WORKTREE_BASE" && pwd -P)
WORKTREE_DIR="$WORKTREE_BASE/$REPO_NAME/$FEATURE_ID"

HAS_ORIGIN=false
if git remote get-url origin >/dev/null 2>&1; then
    HAS_ORIGIN=true
fi
if [[ "$HAS_ORIGIN" == true && "$NO_FETCH" != true ]]; then
    info "Fetching origin..."
    git fetch origin --prune
fi

refresh_remote_claim() {
    [[ "$HAS_ORIGIN" == true && "$NO_FETCH" != true ]] || return 0

    local remote_ref="refs/heads/$BRANCH_NAME"
    local tracking_ref="refs/remotes/origin/$BRANCH_NAME"
    local result oid resolved_ref extra fetched_oid
    if ! result=$(git ls-remote --heads origin "$remote_ref"); then
        die "failed to inspect exact remote claim ref $remote_ref"
    fi
    if [[ -z "$result" ]]; then
        # A narrow fetch refspec may leave a stale tracking ref that --prune does
        # not own. Do not mistake it for a currently published claim.
        git update-ref -d "$tracking_ref"
        return 0
    fi
    [[ "$result" != *$'\n'* ]] || die "remote returned multiple values for exact claim ref $remote_ref"
    read -r oid resolved_ref extra <<< "$result"
    [[ -z "$extra" && "$resolved_ref" == "$remote_ref" ]] \
        || die "remote returned an invalid exact claim record for $remote_ref"
    [[ "$oid" =~ ^[0-9a-f]+$ && ( ${#oid} -eq 40 || ${#oid} -eq 64 ) ]] \
        || die "remote returned an invalid object ID for $remote_ref"

    info "Fetching exact remote claim $remote_ref..."
    git fetch --no-tags origin "+$remote_ref:$tracking_ref"
    fetched_oid=$(git rev-parse "$tracking_ref^{commit}")
    [[ "$fetched_oid" == "$oid" ]] \
        || die "remote claim $remote_ref changed while it was inspected; retry from a fresh fetch"
}

refresh_remote_claim

resolve_ref() {
    local requested=$1
    local candidate
    for candidate in "$requested" "refs/heads/$requested" "refs/remotes/origin/$requested"; do
        if git rev-parse --verify --quiet "${candidate}^{commit}" >/dev/null; then
            case "$candidate" in
                refs/heads/*) printf '%s\n' "${candidate#refs/heads/}" ;;
                refs/remotes/*) printf '%s\n' "${candidate#refs/remotes/}" ;;
                *) printf '%s\n' "$candidate" ;;
            esac
            return 0
        fi
    done
    return 1
}

require_local_claim_not_behind_remote() {
    local branch=$1
    local local_ref="refs/heads/$branch"
    local remote_ref="refs/remotes/origin/$branch"
    local ahead behind relation

    # --no-fetch is an explicit local-only mode. Its caller must disclose that
    # it cannot prove a cross-clone claim. With a successful fetch, fail closed
    # instead of selecting a stale local branch over a newer remote claim.
    if [[ "$NO_FETCH" == true ]] \
        || ! git show-ref --verify --quiet "$local_ref" \
        || ! git show-ref --verify --quiet "$remote_ref"; then
        return 0
    fi

    relation=$(git rev-list --left-right --count "$local_ref...$remote_ref")
    read -r ahead behind <<< "$relation"
    if (( behind > 0 && ahead > 0 )); then
        die "local branch '$branch' diverges from origin/$branch; reconcile the published claim before creating or reusing a worktree"
    fi
    if (( behind > 0 )); then
        die "local branch '$branch' is behind origin/$branch; inspect the newer published claim before creating or reusing a worktree"
    fi
}

if [[ -n "$REQUESTED_BASE" ]]; then
    BASE_REF=$(resolve_ref "$REQUESTED_BASE") || die "base ref '$REQUESTED_BASE' does not resolve to a commit"
else
    BASE_REF=
    if ORIGIN_HEAD=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null); then
        BASE_REF=$(resolve_ref "$ORIGIN_HEAD") || true
    fi
    if [[ -z "$BASE_REF" ]] && git rev-parse --verify --quiet 'refs/heads/main^{commit}' >/dev/null; then
        BASE_REF=main
    fi
    if [[ -z "$BASE_REF" ]] && git rev-parse --verify --quiet 'refs/remotes/origin/main^{commit}' >/dev/null; then
        BASE_REF=origin/main
    fi
    if [[ -z "$BASE_REF" ]] && CURRENT_HEAD=$(git symbolic-ref --quiet --short HEAD 2>/dev/null); then
        BASE_REF=$(resolve_ref "$CURRENT_HEAD") || true
    fi
    if [[ -z "$BASE_REF" ]] && git rev-parse --verify --quiet 'HEAD^{commit}' >/dev/null; then
        BASE_REF=HEAD
    fi
    [[ -n "$BASE_REF" ]] || die "could not resolve a base commit; pass --base-branch explicitly"
fi

require_local_claim_not_behind_remote "$BRANCH_NAME"

is_registered_worktree() {
    local line
    while IFS= read -r line; do
        if [[ "$line" == "worktree $WORKTREE_DIR" ]]; then
            return 0
        fi
    done < <(git worktree list --porcelain)
    return 1
}

if [[ -e "$WORKTREE_DIR" ]]; then
    if ! is_registered_worktree; then
        die "refusing to remove or overwrite existing unregistered directory: $WORKTREE_DIR"
    fi

    CURRENT_BRANCH=$(git -C "$WORKTREE_DIR" branch --show-current)
    if [[ "$CURRENT_BRANCH" != "$BRANCH_NAME" ]]; then
        die "registered worktree $WORKTREE_DIR is on '$CURRENT_BRANCH', expected '$BRANCH_NAME'; inspect it manually before reuse"
    fi
    COMMITS_AHEAD=$(git -C "$WORKTREE_DIR" rev-list --count "${BASE_REF}..HEAD")
    LAST_COMMIT=$(git -C "$WORKTREE_DIR" log -1 --format=%s)
    UNCOMMITTED=$(git -C "$WORKTREE_DIR" status --porcelain | awk 'END { print NR + 0 }')
    emit_result existing "$CURRENT_BRANCH" "$COMMITS_AHEAD" "$UNCOMMITTED" "$LAST_COMMIT"
    exit 0
fi

mkdir -p -- "$(dirname -- "$WORKTREE_DIR")"

if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
    info "Creating worktree from existing local branch $BRANCH_NAME..."
    git worktree add "$WORKTREE_DIR" "$BRANCH_NAME" >&2
    STATUS=existing_branch
elif git show-ref --verify --quiet "refs/remotes/origin/$BRANCH_NAME"; then
    info "Creating worktree from existing remote branch origin/$BRANCH_NAME..."
    # Do not use `--track`: Git refuses to infer tracking for a branch outside a
    # deliberately narrow origin refspec even after the exact ref was fetched.
    git worktree add -b "$BRANCH_NAME" "$WORKTREE_DIR" "refs/remotes/origin/$BRANCH_NAME" >&2
    git config "branch.$BRANCH_NAME.remote" origin
    git config "branch.$BRANCH_NAME.merge" "refs/heads/$BRANCH_NAME"
    STATUS=remote_branch
else
    info "Creating $BRANCH_NAME from $BASE_REF..."
    git worktree add -b "$BRANCH_NAME" "$WORKTREE_DIR" "$BASE_REF" >&2
    STATUS=new
fi

CURRENT_BRANCH=$(git -C "$WORKTREE_DIR" branch --show-current)
COMMITS_AHEAD=$(git -C "$WORKTREE_DIR" rev-list --count "${BASE_REF}..HEAD")
LAST_COMMIT=$(git -C "$WORKTREE_DIR" log -1 --format=%s)
UNCOMMITTED=$(git -C "$WORKTREE_DIR" status --porcelain | awk 'END { print NR + 0 }')
emit_result "$STATUS" "$CURRENT_BRANCH" "$COMMITS_AHEAD" "$UNCOMMITTED" "$LAST_COMMIT"
