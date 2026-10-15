#!/usr/bin/env bash
# Uses real local Git repositories; never contacts a remote or launches an agent.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.invalid
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.invalid

for parent in first second; do
  repo="$scratch/$parent/project"
  mkdir -p "$repo"
  git -C "$repo" init -q -b main
  printf 'fixture\n' > "$repo/README.md"
  git -C "$repo" add README.md
  git -C "$repo" commit -qm fixture
  output="$(cd "$repo" && bash "$here/scripts/worktree-setup.sh" FTR-0001 example "$scratch/worktrees")"
  checkout="$(printf '%s\n' "$output" | sed -n 's/^WORKTREE_PATH=//p')"
  [ -f "$checkout/README.md" ] || { echo 'default base did not resolve' >&2; exit 1; }
  if [ "$parent" = first ]; then first_checkout="$checkout"; else second_checkout="$checkout"; fi
done
[ "$first_checkout" != "$second_checkout" ] || { echo 'same-name repositories collided' >&2; exit 1; }

unknown="$(dirname "$first_checkout")/FTR-0002"
mkdir -p "$unknown"
printf 'keep\n' > "$unknown/sentinel"
if (cd "$scratch/first/project" && bash "$here/scripts/worktree-setup.sh" FTR-0002 example "$scratch/worktrees" main) >"$scratch/refusal.log" 2>&1; then
  echo 'unknown worktree directory was accepted' >&2
  exit 1
fi
[ "$(cat "$unknown/sentinel")" = keep ] || { echo 'unknown directory was modified' >&2; exit 1; }
echo 'worktree setup: default branch, repository identity, and unknown-directory preservation passed'
