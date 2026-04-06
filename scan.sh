#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/lingdojo/kana-dojo.git"
REPORT_FILE="/repo/scan-report.md"

# ── Helpers ──
header()  { echo -e "\n## $1" | tee -a "$REPORT_FILE"; }
subhead() { echo -e "\n### $1" | tee -a "$REPORT_FILE"; }
code()    { echo '```' >> "$REPORT_FILE"; }
log()     { echo "$1" | tee -a "$REPORT_FILE"; }
result()  { echo "$1" >> "$REPORT_FILE"; }

echo "# Phase 2 & 3 — Isolated Scan Report" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "Container: $(hostname)" >> "$REPORT_FILE"

# ── 2.1 Clone ──
header "2.1 Clone Repository"
git clone --depth 1 "$REPO_URL" /repo/src 2>&1 | tail -1 | tee -a "$REPORT_FILE"
cd /repo/src

# ── 2.2 Lifecycle Scripts ──
header "2.2 npm Lifecycle Scripts"
subhead "preinstall / postinstall / prepare"
code
grep -E '"(preinstall|postinstall|prepare)"' package.json >> "$REPORT_FILE" 2>&1 || echo "None found (preinstall/postinstall)" >> "$REPORT_FILE"
code

subhead "Husky hooks"
code
find .husky -type f ! -name '.gitignore' -exec echo "=== {} ===" \; -exec cat {} \; >> "$REPORT_FILE" 2>&1
code

subhead "Shell scripts"
code
find . -name "*.sh" -not -path "./node_modules/*" -exec echo "=== {} ===" \; -exec cat {} \; >> "$REPORT_FILE" 2>&1
code

# ── 2.3 Dangerous Patterns ──
header "2.3 Dangerous Code Patterns"

subhead "eval() usage"
code
grep -rn "eval(" --include="*.js" --include="*.ts" --include="*.mjs" --include="*.tsx" \
  --exclude-dir=node_modules --exclude-dir=.next . >> "$REPORT_FILE" 2>&1 || echo "None found" >> "$REPORT_FILE"
code

subhead "Function() constructor"
code
grep -rn "new Function(" --include="*.js" --include="*.ts" --include="*.mjs" --include="*.tsx" \
  --exclude-dir=node_modules --exclude-dir=.next . >> "$REPORT_FILE" 2>&1 || echo "None found" >> "$REPORT_FILE"
code

subhead "child_process usage"
code
grep -rn "child_process\|execSync\|spawnSync" --include="*.js" --include="*.ts" --include="*.mjs" --include="*.tsx" \
  --exclude-dir=node_modules --exclude-dir=.next . >> "$REPORT_FILE" 2>&1 || echo "None found" >> "$REPORT_FILE"
code

subhead "Obfuscation indicators (Buffer.from, atob/btoa)"
code
grep -rn "Buffer\.from\|atob\|btoa" --include="*.js" --include="*.ts" --include="*.mjs" --include="*.tsx" \
  --exclude-dir=node_modules --exclude-dir=.next . >> "$REPORT_FILE" 2>&1 || echo "None found" >> "$REPORT_FILE"
code

subhead "Network calls in config files"
code
grep -rn "fetch\|axios\|http\.get\|https\.get" next.config* postcss* tailwind* vite* >> "$REPORT_FILE" 2>&1 || echo "None found" >> "$REPORT_FILE"
code

subhead "process.env in hooks / shell scripts"
code
grep -rn "process\.env" .husky/ >> "$REPORT_FILE" 2>&1 || echo "None in .husky/" >> "$REPORT_FILE"
grep -rn "process\.env" --include="*.sh" --exclude-dir=node_modules . >> "$REPORT_FILE" 2>&1 || echo "None in .sh files" >> "$REPORT_FILE"
code

# ── 2.4 npm install (no scripts) + audit ──
header "2.4 Dependency Audit"

subhead "npm install --ignore-scripts"
npm install --ignore-scripts 2>&1 | tail -5 | tee -a "$REPORT_FILE"

subhead "npm audit"
code
npm audit 2>&1 >> "$REPORT_FILE" || true
code

subhead "npm audit (high + critical only)"
code
npm audit --audit-level=high 2>&1 >> "$REPORT_FILE" || true
code

# ── 3. Trivy Scan ──
header "3. Trivy Filesystem Scan"
code
trivy fs --severity HIGH,CRITICAL --skip-dirs node_modules /repo/src 2>&1 >> "$REPORT_FILE" || echo "Trivy scan failed" >> "$REPORT_FILE"
code

# ── Summary ──
header "Scan Complete"
log "Report saved to: $REPORT_FILE"
log "To copy out of container: docker cp <container>:/repo/scan-report.md ."

echo ""
echo "════════════════════════════════════════════════"
echo "  Scan complete. Report: $REPORT_FILE"
echo "  Drop into shell to inspect further, or exit."
echo "════════════════════════════════════════════════"

exec bash
