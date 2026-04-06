# Open Source Contribution Lab

Lab 2 — Disruptive DevOps Portfolio

This repository contains containerised security screening and contribution scripts for evaluating and safely contributing to open source projects.

## Contents

- `Dockerfile.scan` — Docker image provisioned with Trivy, npm audit, and static analysis tools
- `scan.sh` — Automated scan script (clones a target repo in isolation, runs all checks, generates a report)
- `repo-screening.md` — Security screening process documentation and findings
- `scan-report.md` — Raw output from the Docker-based scan

## Usage

The scanning tools are designed to be reusable across any npm-based open source project. To scan a different repository, update the `REPO_URL` variable at the top of `scan.sh`:

```bash
# Build the scanner image (one-time)
docker build -f Dockerfile.scan -t repo-scanner .

# Run against any repo
docker run --rm -it repo-scanner -c "scan.sh"
```
