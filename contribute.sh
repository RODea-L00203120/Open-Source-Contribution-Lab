#!/usr/bin/env bash
set -euo pipefail

DRY_RUN="${DRY_RUN:-false}"

# ── Configuration (update these for a different project/issue) ──
UPSTREAM_REPO="lingdojo/kana-dojo"
ISSUE_NUMBER="12088"
BRANCH_NAME="content/add-japan-fact-140"
COMMIT_MSG="content: add new japan fact"
PR_TITLE="content: add new japan fact"
PR_BODY="Closes #${ISSUE_NUMBER}"
TARGET_FILE="community/content/japan-facts.json"
GIT_NAME="Ronan O'Dea"
GIT_EMAIL="L00203120@atu.ie"

# The fact to add
FACT='"Japan has smart toilets that analyze your waste and display health metrics on a screen - some even save data to apps."'

# ── Preflight ──
if [ -z "${GH_TOKEN:-}" ]; then
  echo "ERROR: GH_TOKEN is not set."
  echo "Generate one at https://github.com/settings/tokens (repo scope)"
  echo "Then run: docker run --rm -it -e GH_TOKEN=ghp_... os-contrib-lab -c contribute.sh"
  exit 1
fi

echo "Authenticating with GitHub..."
gh auth status || echo "GH_TOKEN set — proceeding with token auth."

git config --global user.name "${GIT_NAME}"
git config --global user.email "${GIT_EMAIL}"
git config --global core.pager ""

# Use SSH for git operations
gh config set git_protocol ssh

# ── Fork and clone ──
echo ""
echo "Forking ${UPSTREAM_REPO}..."
gh repo fork "${UPSTREAM_REPO}" --clone --default-branch-only
cd "$(basename "${UPSTREAM_REPO}")"

# Ensure origin uses SSH
FORK_USER=$(gh api user --jq '.login')
git remote set-url origin "git@github.com:${FORK_USER}/$(basename "${UPSTREAM_REPO}").git"

# ── Branch ──
echo ""
echo "Creating branch: ${BRANCH_NAME}"
git checkout -b "${BRANCH_NAME}"

# ── Edit ──
echo ""
echo "Adding fact to ${TARGET_FILE}..."

# Insert the fact before the closing bracket, maintaining valid JSON
python3 -c "
import json, sys

with open('${TARGET_FILE}', 'r') as f:
    data = json.load(f)

data.append(${FACT})

with open('${TARGET_FILE}', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"

echo "Validating JSON..."
python3 -c "import json; json.load(open('${TARGET_FILE}'))" && echo "JSON is valid."

# ── Commit and push ──
echo ""
git add "${TARGET_FILE}"
git diff --cached --stat
git commit -m "${COMMIT_MSG}"

if [ "${DRY_RUN}" = "true" ]; then
  echo ""
  echo "════════════════════════════════════════════════"
  echo "  DRY RUN — skipping push and PR creation"
  echo "  Branch: ${BRANCH_NAME}"
  echo "  Remote: $(git remote get-url origin)"
  echo "  Commit: $(git log -1 --oneline)"
  echo "  PR would target: ${UPSTREAM_REPO} main"
  echo "  PR head: ${FORK_USER}:${BRANCH_NAME}"
  echo "════════════════════════════════════════════════"
  exit 0
fi

git push origin "${BRANCH_NAME}"

# ── Open PR ──
echo ""
echo "Opening pull request..."
PR_URL=$(gh pr create \
  --repo "${UPSTREAM_REPO}" \
  --title "${PR_TITLE}" \
  --body "${PR_BODY}" \
  --head "${FORK_USER}:${BRANCH_NAME}")

echo ""
echo "════════════════════════════════════════════════"
echo "  PR created: ${PR_URL}"
echo "════════════════════════════════════════════════"
