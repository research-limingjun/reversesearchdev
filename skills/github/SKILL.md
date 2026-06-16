---
name: github
description: "GitHub operations: auth, issues, PRs, code review, repo management via gh CLI and REST API."
version: 2.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [GitHub, Git, gh-cli, Issues, Pull-Requests, Code-Review, Repositories, CI/CD, Authentication]
    related_skills: [codebase-inspection]
---

# GitHub Operations

Complete guide for working with GitHub via the `gh` CLI and REST API. Covers authentication, issues, pull requests, code review, and repository management.

Every section shows `gh` first, then `git` + `curl` fallback for machines without `gh`.

## Prerequisites

- Git installed
- `gh` CLI (optional but recommended): `brew install gh` or see https://cli.github.com

---

## Auth Detection (shared by all sections)

Run this at the start of any GitHub workflow:

```bash
source "${HERMES_HOME:-$HOME/.hermes}/skills/github/scripts/gh-env.sh"
```

After sourcing: `$GH_AUTH_METHOD` is `gh`, `curl`, or `none`. `$GITHUB_TOKEN`, `$GH_USER`, `$GH_OWNER`, `$GH_REPO`, `$GH_OWNER_REPO` are set.

Manual detection (inline):

```bash
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  AUTH="gh"
else
  AUTH="git"
  if [ -z "$GITHUB_TOKEN" ]; then
    if [ -f ~/.hermes/.env ] && grep -q "^GITHUB_TOKEN=" ~/.hermes/.env; then
      GITHUB_TOKEN=$(grep "^GITHUB_TOKEN=" ~/.hermes/.env | head -1 | cut -d= -f2 | tr -d '\n\r')
    elif grep -q "github.com" ~/.git-credentials 2>/dev/null; then
      GITHUB_TOKEN=$(grep "github.com" ~/.git-credentials 2>/dev/null | head -1 | sed 's|https://[^:]*:\([^@]*\)@.*|\1|')
    fi
  fi
fi

REMOTE_URL=$(git remote get-url origin)
OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/]||; s|\.git$||')
OWNER=$(echo "$OWNER_REPO" | cut -d/ -f1)
REPO=$(echo "$OWNER_REPO" | cut -d/ -f2)
```

---

## §1 — Authentication Setup

Sets up auth so the agent can work with GitHub. Two paths: `git` (always available) and `gh` CLI (if installed).

### Detection

```bash
git --version
gh --version 2>/dev/null || echo "gh not installed"
gh auth status 2>/dev/null || echo "gh not authenticated"
git config --global credential.helper 2>/dev/null || echo "no git credential helper"
```

**Decision tree:**
1. `gh auth status` shows authenticated → use `gh` for everything
2. `gh` installed but not authenticated → use "gh auth" method
3. `gh` not installed → use "git-only" method

### Method 1: Git-Only (No gh, No sudo)

**HTTPS with Personal Access Token (recommended):**

1. Create token at https://github.com/settings/tokens — scopes: `repo`, `workflow`, `read:org`
2. Configure credential store:
   ```bash
   git config --global credential.helper store
   git ls-remote https://github.com/<username>/<any-repo>.git  # triggers auth prompt
   ```
3. Set identity:
   ```bash
   git config --global user.name "Their Name"
   git config --global user.email "their-email@example.com"
   ```

**SSH Key Authentication:**

```bash
ls -la ~/.ssh/id_*.pub 2>/dev/null || echo "No SSH keys found"
ssh-keygen -t ed25519 -C "email@example.com" -f ~/.ssh/id_ed25519 -N ""
cat ~/.ssh/id_ed25519.pub  # add to https://github.com/settings/keys
ssh -T git@github.com
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

### Method 2: gh CLI Authentication

```bash
gh auth login                        # interactive browser login
echo "<TOKEN>" | gh auth login --with-token  # headless token login
gh auth setup-git                    # configure git credentials through gh
gh auth status
```

### Using the API Without gh

```bash
export GITHUB_TOKEN="<token>"
curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
```

### Troubleshooting

| Problem | Solution |
|---------|----------|
| `git push` asks for password | Use PAT as password, or switch to SSH |
| `Permission denied` | Token may lack `repo` scope |
| `Authentication failed` | Run `git credential reject` then re-auth |
| SSH port 22 refused | Use `Port 443` / `Hostname ssh.github.com` in `~/.ssh/config` |
| Multiple accounts | Use SSH with different keys per host alias |

---

## §2 — Code Review

Review local changes before pushing, or review open PRs on GitHub.

### Reviewing Local Changes (Pre-Push)

```bash
git diff main...HEAD --stat        # scope of changes
git diff main...HEAD               # full diff
git diff main...HEAD -- src/file.py  # specific file
```

Check for common issues:

```bash
git diff main...HEAD | grep -n "print(\|console\.log\|TODO\|FIXME\|HACK\|debugger"
git diff main...HEAD | grep -in "password\|secret\|api_key\|token.*=\|private_key"
```

### Review Output Format

```
## Code Review Summary

### Critical
- **file.py:45** — SQL injection vulnerability.

### Warnings
- **file.py:23** — Password stored in plaintext.

### Suggestions
- **file.py:8** — Duplicates logic in other_file.py.

### Looks Good
- Clean separation of concerns.
```

See `references/review-output-template.md` for the full template.

### Reviewing a PR

**With gh:**
```bash
gh pr view 123
gh pr diff 123
gh pr checkout 123
```

**With curl:**
```bash
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pulls/123
git fetch origin pull/123/head:pr-123 && git checkout pr-123
```

### Posting Review Comments

**Inline comments:**
```bash
gh api repos/$OWNER/$REPO/pulls/123/comments \
  --method POST \
  -f body="This could be simplified." \
  -f path="src/auth.py" \
  -f commit_id="$HEAD_SHA" \
  -f line=45 -f side="RIGHT"
```

**Formal review (approve/request changes):**
```bash
gh pr review 123 --approve --body "LGTM!"
gh pr review 123 --request-changes --body "See inline comments."
```

**Atomic multi-comment review via curl:** see `references/github-api-cheatsheet.md` for the full pattern.

### Review Checklist

- **Correctness:** Does it work? Edge cases? Error handling?
- **Security:** No hardcoded secrets? Input validation? SQL injection/XSS?
- **Quality:** Clear naming? DRY? Single responsibility?
- **Testing:** New code paths tested? Happy + error cases?
- **Performance:** No N+1 queries? No blocking in async?
- **Documentation:** Public APIs documented? Non-obvious logic commented?

---

## §3 — Issues

Create, search, triage, and manage GitHub issues.

### Viewing Issues

```bash
gh issue list
gh issue list --state open --label "bug"
gh issue list --assignee @me
gh issue view 42
```

```bash
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/issues?state=open&per_page=20"
```

### Creating Issues

```bash
gh issue create \
  --title "Login redirect ignores ?next= parameter" \
  --body "## Description\n..." \
  --label "bug,backend" \
  --assignee "username"
```

Templates: `templates/bug-report.md`, `templates/feature-request.md`

### Managing Issues

```bash
gh issue edit 42 --add-label "priority:high,bug"
gh issue edit 42 --add-assignee @me
gh issue comment 42 --body "Root cause found."
gh issue close 42
gh issue reopen 42
```

### Triage Workflow

1. List untriaged: `gh issue list --label "needs-triage" --state open`
2. Read and categorize each issue
3. Apply labels and priority
4. Assign if owner is clear
5. Comment with triage notes if needed

### Bulk Operations

```bash
gh issue list --label "wontfix" --json number --jq '.[].number' | \
  xargs -I {} gh issue close {} --reason "not planned"
```

---

## §4 — Pull Requests

Complete PR lifecycle: branch, commit, push, CI, merge.

### Branch Creation

```bash
git fetch origin
git checkout main && git pull origin main
git checkout -b feat/add-user-authentication
```

Branch naming: `feat/`, `fix/`, `refactor/`, `docs/`, `ci/`

### Committing (Conventional Commits)

```bash
git add src/auth.py tests/test_auth.py
git commit -m "feat: add JWT-based user authentication"
```

Format: `type(scope): description`. Types: `feat`, `fix`, `refactor`, `docs`, `test`, `ci`, `chore`, `perf`

See `references/conventional-commits.md` for the full reference.

### Creating a PR

**With gh:**
```bash
gh pr create --title "feat: add JWT auth" --body "## Summary\n..." --draft --reviewer user1
```

**With curl:**
```bash
curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pulls \
  -d '{"title":"feat: add JWT auth","body":"...","head":"branch","base":"main"}'
```

Templates: `templates/pr-body-bugfix.md`, `templates/pr-body-feature.md`

### Monitoring CI

```bash
gh pr checks
gh pr checks --watch  # polls until done
```

```bash
SHA=$(git rev-parse HEAD)
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/commits/$SHA/status
```

### Auto-Fixing CI Failures

1. Get failure details: `gh run view <RUN_ID> --log-failed`
2. Diagnose (see `references/ci-troubleshooting.md`)
3. Fix code, commit, push
4. Re-check CI status
5. Repeat up to 3 times

### Merging

```bash
gh pr merge --squash --delete-branch
gh pr merge --auto --squash --delete-branch  # auto-merge when green
```

```bash
curl -s -X PUT -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER/merge \
  -d '{"merge_method":"squash","commit_title":"feat: auth (#42)"}'
```

---

## §5 — Repository Management

Create, clone, fork, configure, and manage repositories.

### Cloning

```bash
git clone https://github.com/owner/repo.git
git clone --depth 1 https://github.com/owner/repo.git  # shallow
gh repo clone owner/repo
```

### Creating Repos

```bash
gh repo create my-project --public --clone
gh repo create my-project --source . --public --push  # existing dir
```

```bash
curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user/repos \
  -d '{"name":"my-project","private":false,"auto_init":true}'
```

### Forking

```bash
gh repo fork owner/repo --clone
gh repo sync $GH_USER/repo  # keep fork in sync
```

### Repository Settings

```bash
gh repo edit --description "Updated" --visibility public
gh repo edit --enable-wiki=false --enable-issues=true
gh repo edit --add-topic "ml,python"
gh repo edit --enable-auto-merge
```

### Branch Protection

```bash
curl -s -X PUT -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/branches/main/protection \
  -d '{"required_status_checks":{"strict":true,"contexts":["ci/test"]},"required_pull_request_reviews":{"required_approving_review_count":1}}'
```

### Secrets (GitHub Actions)

```bash
gh secret set API_KEY --body "value"
gh secret list
gh secret delete API_KEY
```

### Releases

```bash
gh release create v1.0.0 --title "v1.0.0" --generate-notes
gh release create v1.0.0 ./dist/binary --notes "Release notes"
gh release list
gh release download v1.0.0
```

### GitHub Actions

```bash
gh workflow list
gh run list --limit 10
gh run view <RUN_ID> --log-failed
gh run rerun <RUN_ID>
gh workflow run ci.yml --ref main
```

### Gists

```bash
gh gist create script.py --public --desc "Useful script"
gh gist list
```

---

## §6 — Codebase Inspection (pygount)

Analyze repositories for lines of code, language breakdown, and code-vs-comment ratios.

### Prerequisites

```bash
pip install --break-system-packages pygount
```

### Usage

```bash
cd /path/to/repo
pygount --format=summary --folders-to-skip=".git,node_modules,venv,.venv,__pycache__,.cache,dist,build" .
```

**Always use `--folders-to-skip`** to exclude dependency/build directories.

### Common Exclusions

```bash
# Python
--folders-to-skip=".git,venv,.venv,__pycache__,.cache,dist,build,.tox,.eggs"

# JavaScript/TypeScript
--folders-to-skip=".git,node_modules,dist,build,.next,.cache,.turbo"

# General
--folders-to-skip=".git,node_modules,venv,.venv,__pycache__,.cache,dist,build,vendor,third_party"
```

### Filter by Language

```bash
pygount --suffix=py --format=summary .       # Python only
pygount --suffix=py,yaml,yml --format=summary .
```

### JSON Output

```bash
pygount --format=json .
```

### Notes

- Markdown shows 0 code lines (pygount classifies all as comments)
- JSON files show low counts — use `wc -l` for accurate JSON line counts
- Large monorepos: use `--suffix` to target specific languages

---

## Quick Reference

| Action | gh | curl endpoint |
|--------|-----|--------------|
| List issues | `gh issue list` | `GET /repos/{o}/{r}/issues` |
| Create issue | `gh issue create` | `POST /repos/{o}/{r}/issues` |
| Create PR | `gh pr create` | `POST /repos/{o}/{r}/pulls` |
| Merge PR | `gh pr merge --squash` | `PUT /repos/{o}/{r}/pulls/{n}/merge` |
| Review PR | `gh pr review --approve` | `POST /repos/{o}/{r}/pulls/{n}/reviews` |
| Create release | `gh release create v1.0` | `POST /repos/{o}/{r}/releases` |
| Set secret | `gh secret set KEY` | `PUT /repos/{o}/{r}/actions/secrets/KEY` |
| Rerun CI | `gh run rerun ID` | `POST /repos/{o}/{r}/actions/runs/ID/rerun` |

Full API cheatsheet: `references/github-api-cheatsheet.md`
