# Open Source Contribution Lab

Lab 2 — Disruptive DevOps Portfolio

This repository contains containerised security screening and contribution tooling for evaluating and safely contributing to open source projects. All operations (cloning, scanning, dependency installation, forking, committing, and PR creation) run inside disposable Docker containers — nothing touches the host system.

## Contents

- `Dockerfile` — Single Docker image provisioned with Trivy, npm audit, GitHub CLI, and static analysis tools
- `scan.sh` — Automated security scan script (clones a target repo in isolation, runs all checks, generates a report)
- `contribute.sh` — Automated contribution script (forks, branches, edits, commits, and opens a PR from inside a container)
- `repo-screening.md` — Security screening process documentation, methodology, and findings

## How It Works

### 1. Security Screening (`scan.sh`)

Clones a target repository inside a container and runs:

- **Lifecycle script inspection** — checks for `preinstall`, `postinstall`, and `prepare` hooks
- **Git hook review** — reads all Husky/pre-commit hooks for suspicious commands
- **Static pattern analysis** — greps for `eval()`, `child_process`, `Buffer.from`, obfuscation indicators
- **Dependency audit** — `npm install --ignore-scripts` followed by `npm audit`
- **Trivy filesystem scan** — checks for HIGH/CRITICAL vulnerabilities and leaked secrets

Outputs a `scan-report.md` with all findings.

### 2. Contribution (`contribute.sh`)

Runs the full contribution workflow inside a container:

- Authenticates with GitHub via `GH_TOKEN` for API calls
- Uses SSH (read-only mounted key) for git push operations
- Forks the target repository to your account
- Clones the fork, creates a feature branch
- Makes the required edit and validates the change
- Commits, pushes to the fork, and opens a PR against upstream

### 3. Isolation Model

```
┌──────────────────────────────────────────┐
│         Host Machine                     │
│  (no repo cloned, no npm install)        │
│                                          │
│  Provides:                               │
│  - GH_TOKEN (env var, for gh API calls)  │
│  - SSH key (read-only mount, for push)   │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │     Docker Container (--rm)        │  │
│  │  - git clone                       │  │
│  │  - npm install --ignore-scripts    │  │
│  │  - trivy scan                      │  │
│  │  - gh fork / push / pr create      │  │
│  │                                    │  │
│  │  Destroyed on exit                 │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

## Usage

```bash
# Build the image (one-time)
docker build -t os-contrib-lab .

# Scan a repo for security issues
docker run --rm -it os-contrib-lab -c "scan.sh"

# Contribute to a repo (requires GH_TOKEN + SSH key)
# Generate a token at https://github.com/settings/tokens (repo scope)
docker run --rm -it -e GH_TOKEN \
  -v ~/.ssh/id_ed25519:/root/.ssh/id_ed25519:ro \
  -v ~/.ssh/known_hosts:/root/.ssh/known_hosts:ro \
  os-contrib-lab -c "contribute.sh"
```

To target a different repository, update the `REPO_URL` / `UPSTREAM_REPO` variable at the top of each script.

## Target Repository

- **Repo:** [lingdojo/kana-dojo](https://github.com/lingdojo/kana-dojo)
- **Issue:** [#12088](https://github.com/lingdojo/kana-dojo/issues/12088) — Add new Japan Fact 140
- **PR:** [#12100](https://github.com/lingdojo/kana-dojo/pull/12100) — Submitted, awaiting maintainer review
- **Screening verdict:** Safe to contribute (no malicious code), but identified as a contribution/engagement farm

## License

[MIT](LICENSE)
