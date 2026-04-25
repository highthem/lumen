# Xcode Cloud Setup — Claude Code Task File

> **Audience:** Claude Code (CLI agent running locally on Haithem's Mac).
> **Goal:** Bootstrap Xcode Cloud for the Lumen iOS app (`highthem/lumen`), end to end, with two workflows (Xcode 16 compatibility + Xcode 26 Apple Intelligence) and AI provider secrets injected at build time.
> **Self-contained:** every file you need to write is included inline below. Every shell command is ready to run. Idempotent.

---

## Mission

Set up Xcode Cloud for `Lumen Morning` (App Store Connect app `6763776556`, bundle `com.highthem.lumen`) with the following declarative end state:

```json
{
  "$schema": "https://developer.apple.com/documentation/appstoreconnectapi/ciworkflow",
  "app": {
    "name": "Lumen Morning",
    "bundleId": "com.highthem.lumen",
    "appStoreConnectAppId": "6763776556",
    "primaryRepository": "highthem/lumen",
    "primaryBranch": "main"
  },
  "workspace": {
    "path": "Lumen.xcworkspace",
    "rationale": "Root-level workspace referencing Apple/lumen.xcodeproj. Workaround because the Xcode project is not at the repo root (monorepo Apple/, Project/)."
  },
  "scheme": { "name": "lumen", "shared": true },
  "workflows": [
    {
      "id": "tests-xcode-16",
      "name": "Tests on push (Xcode 16)",
      "description": "Compatibility check matching brief PALO IT (Xcode 16+ requirement)",
      "isEnabled": true,
      "containerFilePath": "Lumen.xcworkspace",
      "branchPattern": "*",
      "autoCancel": true,
      "xcodeVersion": "16.4",
      "macOsVersion": "latest_release",
      "actions": [{
        "type": "TEST",
        "scheme": "lumen",
        "platform": "IOS",
        "destination": { "deviceTypeName": "iPhone 15", "runtime": "iOS 17.5" }
      }],
      "postActions": [{
        "type": "EMAIL_NOTIFICATION", "trigger": "ON_FAILURE",
        "recipients": ["ceo@highthem.com"]
      }]
    },
    {
      "id": "tests-xcode-26",
      "name": "Tests on push (Xcode 26)",
      "description": "Validates iOS 26 / Apple Intelligence code paths",
      "isEnabled": true,
      "containerFilePath": "Lumen.xcworkspace",
      "branchPattern": "main",
      "autoCancel": true,
      "xcodeVersion": "26.4",
      "macOsVersion": "latest_release",
      "actions": [{
        "type": "TEST",
        "scheme": "lumen",
        "platform": "IOS",
        "destination": { "deviceTypeName": "iPhone 17 Pro", "runtime": "iOS 26.4" }
      }],
      "postActions": [{
        "type": "EMAIL_NOTIFICATION", "trigger": "ON_FAILURE",
        "recipients": ["ceo@highthem.com"]
      }]
    },
    {
      "id": "testflight-on-tag",
      "name": "TestFlight on tag",
      "description": "Archive + TestFlight on v* tag. Activate on 10 May 2026 (J-1 before delivery to Sami)",
      "isEnabled": false,
      "containerFilePath": "Lumen.xcworkspace",
      "tagPattern": "v*",
      "xcodeVersion": "16.4",
      "actions": [{ "type": "ARCHIVE", "scheme": "lumen", "platform": "IOS" }]
    }
  ],
  "environmentVariables": [
    { "key": "OPENAI_API_KEY", "isSecret": true },
    { "key": "ANTHROPIC_API_KEY", "isSecret": true }
  ]
}
```

---

## Working directory

Run all commands from the repo root:

```bash
cd ~/Developer/Highthem/TheStudio/Lumen
```

---

## Step 0 — Verify current state (read-only checks)

Run these checks first. Report any ✗ to the user before proceeding.

```bash
# 0.1 — repo identity
git remote get-url origin | grep -q 'highthem/lumen' && echo "✓ Remote OK" || echo "✗ Wrong remote"

# 0.2 — required folders present
test -d Apple/lumen.xcodeproj && echo "✓ Xcode project present" || echo "✗ Apple/lumen.xcodeproj missing"
test -f Lumen.xcworkspace/contents.xcworkspacedata && echo "✓ Root workspace OK" || echo "✗ Lumen.xcworkspace missing"

# 0.3 — workspace references the project correctly
grep -q 'group:Apple/lumen.xcodeproj' Lumen.xcworkspace/contents.xcworkspacedata 2>/dev/null && echo "✓ Workspace ref OK" || echo "✗ Workspace does not reference Apple/lumen.xcodeproj"

# 0.4 — build settings
grep -q 'IPHONEOS_DEPLOYMENT_TARGET = 17.0' Apple/lumen.xcodeproj/project.pbxproj && echo "✓ iOS 17.0 target" || echo "✗ Wrong deployment target"
grep -q 'SWIFT_VERSION = 6.0' Apple/lumen.xcodeproj/project.pbxproj && echo "✓ Swift 6.0" || echo "✗ Wrong Swift version"

# 0.5 — scheme shared (the one Xcode Cloud actually needs)
test -f Apple/lumen.xcodeproj/xcshareddata/xcschemes/lumen.xcscheme && echo "✓ Scheme shared" || echo "✗ Scheme NOT shared — see Step 3"

# 0.6 — files we will create in Step 1 (ok if missing now)
test -f .gitignore && echo "→ .gitignore exists, will overwrite" || echo "→ will create .gitignore"
test -f ci_scripts/ci_post_clone.sh && echo "→ ci_post_clone.sh exists" || echo "→ will create ci_post_clone.sh"
test -f Apple/lumen/Config/Secrets.xcconfig.sample && echo "→ secrets sample exists" || echo "→ will create secrets sample"
```

---

## Step 1 — Recreate missing files (everything inline)

### 1.1 — Write `.gitignore`

```bash
cat > .gitignore <<'EOF'
# macOS
.DS_Store
.AppleDouble
.LSOverride
Icon?
._*

# Xcode
xcuserdata/
*.xcuserstate
build/
DerivedData/
*.dSYM.zip
*.dSYM

# Swift Package Manager
.build/
.swiftpm/

# Pods / Carthage (if ever added)
Pods/
Carthage/Build/

# Sed backup files
*.bak
*.bak2

# Secrets — JAMAIS commiter
Apple/lumen/Config/Secrets.xcconfig
*.xcconfig.local

# Logs
*.log

# IDEs
.vscode/
.idea/
*.swp
*.swo

# OS / temp
Thumbs.db
.cache/
EOF
echo "✓ .gitignore written"
```

### 1.2 — Create `ci_scripts/ci_post_clone.sh`

```bash
mkdir -p ci_scripts
cat > ci_scripts/ci_post_clone.sh <<'EOF'
#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────
# ci_post_clone.sh — runs after Xcode Cloud clones the repo
#
# Generates Apple/lumen/Config/Secrets.xcconfig from Xcode Cloud
# Environment Variables (set in App Store Connect → Xcode Cloud → Workflow).
#
# Required env vars (must be marked "Secret" in Xcode Cloud):
#   - OPENAI_API_KEY
#   - ANTHROPIC_API_KEY
# ─────────────────────────────────────────────────────────────────────────

set -e

echo "→ ci_post_clone: generating Secrets.xcconfig from environment variables"

CONFIG_DIR="$CI_PRIMARY_REPOSITORY_PATH/Apple/lumen/Config"
SECRETS_FILE="$CONFIG_DIR/Secrets.xcconfig"

mkdir -p "$CONFIG_DIR"

if [ -z "$OPENAI_API_KEY" ]; then
  echo "⚠️  OPENAI_API_KEY not set — using placeholder"
  OPENAI_API_KEY="MISSING_IN_CI"
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
  echo "⚠️  ANTHROPIC_API_KEY not set — using placeholder"
  ANTHROPIC_API_KEY="MISSING_IN_CI"
fi

cat > "$SECRETS_FILE" <<XCC
// Generated by ci_post_clone.sh — do not commit
OPENAI_API_KEY = $OPENAI_API_KEY
ANTHROPIC_API_KEY = $ANTHROPIC_API_KEY
XCC

echo "✓ Secrets.xcconfig generated at $SECRETS_FILE"
EOF
chmod +x ci_scripts/ci_post_clone.sh
echo "✓ ci_scripts/ci_post_clone.sh written and executable"
```

### 1.3 — Create `Apple/lumen/Config/Secrets.xcconfig.sample`

```bash
mkdir -p Apple/lumen/Config
cat > Apple/lumen/Config/Secrets.xcconfig.sample <<'EOF'
// ─────────────────────────────────────────────────────────────────────────
// Secrets.xcconfig.sample
//
// Copy this file to Secrets.xcconfig and fill in your real keys.
// Secrets.xcconfig is gitignored — NEVER commit your real keys.
//
// In CI (Xcode Cloud), Secrets.xcconfig is generated automatically by
// ci_scripts/ci_post_clone.sh from environment variables.
// ─────────────────────────────────────────────────────────────────────────

// OpenAI API key — used for primary cloud AI synthesis
// Get yours at: https://platform.openai.com/api-keys
OPENAI_API_KEY = REPLACE_ME_OPENAI_KEY

// Anthropic API key — used as fallback cloud AI provider
// Get yours at: https://console.anthropic.com/settings/keys
ANTHROPIC_API_KEY = REPLACE_ME_ANTHROPIC_KEY
EOF
echo "✓ Secrets.xcconfig.sample written"
```

### 1.4 — Verify root workspace (should already exist; create if missing)

```bash
if [ ! -f Lumen.xcworkspace/contents.xcworkspacedata ]; then
  mkdir -p Lumen.xcworkspace
  cat > Lumen.xcworkspace/contents.xcworkspacedata <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "group:Apple/lumen.xcodeproj">
   </FileRef>
</Workspace>
EOF
  echo "✓ Lumen.xcworkspace/contents.xcworkspacedata created"
else
  echo "→ Lumen.xcworkspace already present, skipping"
fi
```

---

## Step 2 — Verify build settings (Xcode project)

```bash
# These values were set by Claude in a previous session. Confirm they're still correct.
grep -c 'IPHONEOS_DEPLOYMENT_TARGET = 17.0' Apple/lumen.xcodeproj/project.pbxproj
# expected: 4 occurrences

grep -c 'SWIFT_VERSION = 6.0' Apple/lumen.xcodeproj/project.pbxproj
# expected: 6 occurrences

# If either count is wrong, ask Haithem to fix in Xcode UI:
#   Project → lumen target → Build Settings →
#     - iOS Deployment Target: 17.0
#     - Swift Language Version: 6
```

---

## Step 3 — Mark scheme `lumen` as Shared (HUMAN ACTION REQUIRED)

Xcode Cloud cannot build a non-shared scheme. The `xcshareddata/xcschemes/lumen.xcscheme` file must exist.

**Cannot be automated reliably via CLI** (xcscheme XML depends on the project's internal IDs). Ask Haithem to:

1. Open `Lumen.xcworkspace` in Xcode (NOT the .xcodeproj):
   ```bash
   open Lumen.xcworkspace
   ```
2. Menu: **Product → Scheme → Manage Schemes…**
3. In the list, check the **Shared** column for `lumen`
4. Close Xcode

Then verify:

```bash
test -f Apple/lumen.xcodeproj/xcshareddata/xcschemes/lumen.xcscheme && echo "✓ Scheme now shared" || echo "✗ Scheme still not shared — re-do step 3"
```

---

## Step 4 — Configure xcconfig as Base Configuration (HUMAN ACTION REQUIRED)

So that the `Secrets.xcconfig` is actually loaded by Xcode at build time. Without this step, `OPENAI_API_KEY` and `ANTHROPIC_API_KEY` won't be injected into the app binary.

Ask Haithem to:

1. In Xcode (`Lumen.xcworkspace`), select the **project** node (top of sidebar, blue icon)
2. Tab **Info** → section **Configurations**
3. Expand **Debug** and **Release**
4. For target `lumen`: change "None" → select `Secrets` (which corresponds to `Secrets.xcconfig`)
5. ⌘S to save

Verify by running a local build:

```bash
cp Apple/lumen/Config/Secrets.xcconfig.sample Apple/lumen/Config/Secrets.xcconfig
# Edit Secrets.xcconfig with real OpenAI + Anthropic keys
xcodebuild -workspace Lumen.xcworkspace -scheme lumen -destination 'generic/platform=iOS Simulator' build OPENAI_API_KEY=test 2>&1 | tail -20
```

The build should succeed. If it fails with "Secrets.xcconfig: file not found", re-do step 4.

---

## Step 5 — Commit and push everything

```bash
git status

# Make sure the real Secrets.xcconfig is NOT staged (gitignore should handle it)
git check-ignore -q Apple/lumen/Config/Secrets.xcconfig && echo "✓ Real Secrets.xcconfig is ignored" || echo "✗ Real Secrets.xcconfig would be committed — fix .gitignore"

git add .gitignore \
        ci_scripts/ \
        Apple/lumen/Config/Secrets.xcconfig.sample \
        Apple/lumen.xcodeproj/xcshareddata/ \
        Apple/lumen.xcodeproj/project.pbxproj \
        Lumen.xcworkspace/

git -c user.name="Haithem" -c user.email="highthem@icloud.com" commit -m "feat: bootstrap Xcode Cloud setup

- Add .gitignore (covers macOS, Xcode, secrets, sed backups)
- Add ci_scripts/ci_post_clone.sh for secrets injection in CI
- Add Apple/lumen/Config/Secrets.xcconfig.sample template
- Share lumen scheme for CI consumption
- Confirm iOS 17.0 deployment target and Swift 6.0 in project settings"

git push
```

---

## Step 6 — Create Workflow 1 via Xcode UI (HUMAN ACTION REQUIRED — first workflow only)

Xcode Cloud's first-time setup requires GitHub OAuth, which only Xcode UI can handle smoothly. Ask Haithem to:

1. Make sure `Lumen.xcworkspace` is open in Xcode
2. Menu: **Product → Xcode Cloud → Create Workflow**
3. Wizard:
   - **Select Product** → `Lumen Morning`
   - **Connect to Source Control** → click "Grant Access" → browser → authorise Apple for `highthem/lumen` → return to Xcode
   - **Review Workflow** → click "Edit Workflow"
4. Configure with these values (matching `tests-xcode-16` in the JSON spec at top):

| Field | Value |
|---|---|
| Name | `Tests on push (Xcode 16)` |
| Description | `Compatibility check matching brief PALO IT (Xcode 16+ requirement)` |
| Branch Changes → Source | `highthem/lumen` |
| Branch Changes → Branch | `Any Branch` |
| Branch Changes → Files & Folders | `All Changes` |
| Branch Changes → Auto-cancel | ☑️ enabled |
| Environment → Xcode | `16.4` (or latest 16.x available) |
| Environment → macOS | latest (default) |
| Environment → Clean | ☐ unchecked |
| Action 1 | **Test** |
| Test → Scheme | `lumen` |
| Test → Platform | iOS Simulator |
| Test → Destination | iPhone 15 (or any iOS 17.x simulator) |
| Post-Action | Email on Failure → `ceo@highthem.com` |

5. **Save** — first build runs automatically (5-10 min). Wait for green or report failure.

---

## Step 7 — Workflow 2 (Xcode 26) via API

After Workflow 1 exists and the OAuth GitHub connection is established, Workflow 2 can be created programmatically. This step requires App Store Connect API credentials.

### 7.1 — Generate ASC API key (HUMAN ACTION REQUIRED, one-time)

Ask Haithem to:

1. Go to https://appstoreconnect.apple.com/access/integrations/api
2. Click **Generate API Key**
3. Name: `lumen-xcode-cloud-automation`
4. Access: **Developer**
5. Download the `.p8` file (Apple lets you download once)
6. Note the Key ID (10 chars) and Issuer ID (UUID)

Then store credentials securely:

```bash
mkdir -p ~/.config/asc-api
mv ~/Downloads/AuthKey_*.p8 ~/.config/asc-api/
chmod 600 ~/.config/asc-api/AuthKey_*.p8

cat >> ~/.zshrc <<'EOF'

# App Store Connect API — Lumen Xcode Cloud
export ASC_KEY_ID="REPLACE_WITH_YOUR_KEY_ID"
export ASC_ISSUER_ID="REPLACE_WITH_YOUR_ISSUER_ID"
export ASC_PRIVATE_KEY_PATH="$HOME/.config/asc-api/AuthKey_${ASC_KEY_ID}.p8"
EOF
source ~/.zshrc
```

### 7.2 — Generate JWT for ASC API auth

```bash
pip install pyjwt cryptography --break-system-packages 2>/dev/null

export ASC_TOKEN=$(python3 - <<'PY'
import jwt, time, os
key_id = os.environ["ASC_KEY_ID"]
issuer = os.environ["ASC_ISSUER_ID"]
private_key = open(os.environ["ASC_PRIVATE_KEY_PATH"]).read()
now = int(time.time())
print(jwt.encode(
    {"iss": issuer, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
    private_key,
    algorithm="ES256",
    headers={"kid": key_id, "typ": "JWT"},
))
PY
)
echo "Token length: ${#ASC_TOKEN}"   # ~600 chars expected
```

### 7.3 — Find Xcode Cloud Product ID and Repository ID

```bash
curl -sH "Authorization: Bearer $ASC_TOKEN" \
  "https://api.appstoreconnect.apple.com/v1/ciProducts?filter[app]=6763776556&include=primaryRepositories" \
  | jq '{products: [.data[] | {id, name: .attributes.name}], repos: [.included[]? | select(.type=="scmRepositories") | {id, repoName: .attributes.repositoryName}]}'

# Set in env vars:
export XCC_PRODUCT_ID="<paste id from above>"
export XCC_REPO_ID="<paste repo id from above>"
```

### 7.4 — Find latest Xcode 26 version available

```bash
curl -sH "Authorization: Bearer $ASC_TOKEN" \
  "https://api.appstoreconnect.apple.com/v1/ciXcodeVersions" \
  | jq '.data[] | select(.attributes.name | startswith("26")) | {id, name: .attributes.name}' \
  | head -10

export XCODE_26_VERSION_ID="<paste id of latest 26.x>"
```

### 7.5 — Find latest macOS version

```bash
curl -sH "Authorization: Bearer $ASC_TOKEN" \
  "https://api.appstoreconnect.apple.com/v1/ciMacOsVersions" \
  | jq '.data | sort_by(.attributes.name) | reverse | .[:3] | .[] | {id, name: .attributes.name}'

export MACOS_VERSION_ID="<paste id of latest>"
```

### 7.6 — Create Workflow 2 (Xcode 26)

```bash
curl -sX POST "https://api.appstoreconnect.apple.com/v1/ciWorkflows" \
  -H "Authorization: Bearer $ASC_TOKEN" \
  -H "Content-Type: application/json" \
  -d @- <<EOF | jq .
{
  "data": {
    "type": "ciWorkflows",
    "attributes": {
      "name": "Tests on push (Xcode 26)",
      "description": "Validates iOS 26 / Apple Intelligence code paths",
      "isEnabled": true,
      "isLockedForEditing": false,
      "containerFilePath": "Lumen.xcworkspace",
      "branchStartCondition": {
        "source": {
          "type": "BRANCH_PATTERNS",
          "patterns": [{"isAllMatch": false, "patterns": ["main"]}]
        },
        "files": {"type": "ALL_CHANGES"},
        "autoCancel": true
      },
      "actions": [{
        "actionType": "TEST",
        "name": "lumenTests",
        "destination": "ANY_IOS_SIMULATOR_DEVICE",
        "scheme": "lumen",
        "platform": "IOS"
      }]
    },
    "relationships": {
      "xcodeVersion": {"data": {"type": "ciXcodeVersions", "id": "$XCODE_26_VERSION_ID"}},
      "macOsVersion": {"data": {"type": "ciMacOsVersions", "id": "$MACOS_VERSION_ID"}},
      "product": {"data": {"type": "ciProducts", "id": "$XCC_PRODUCT_ID"}},
      "repository": {"data": {"type": "scmRepositories", "id": "$XCC_REPO_ID"}}
    }
  }
}
EOF
```

Save the returned workflow id:

```bash
export WORKFLOW_2_ID="<paste from response>"
```

---

## Step 8 — Configure Environment Variables (secrets) — HUMAN ACTION

The actual key values must NEVER pass through this script or any agent. Ask Haithem to:

1. Open https://appstoreconnect.apple.com/teams/1b0462ee-7f1c-4214-bfa9-e05c27d5fc52/apps/6763776556/ci
2. **Settings** (top right) → **Environment**
3. Click **+ Add Environment Variable**:
   - Name: `OPENAI_API_KEY`
   - Value: paste the real OpenAI key (from https://platform.openai.com/api-keys)
   - ☑️ **Secret** (mandatory — masks the value in logs)
   - Save
4. Repeat for:
   - Name: `ANTHROPIC_API_KEY`
   - Value: paste the real Anthropic key (from https://console.anthropic.com/settings/keys)
   - ☑️ **Secret**
   - Save

These env vars apply to all workflows on this product.

---

## Step 9 — Verify the setup end to end

### 9.1 — List workflows

```bash
curl -sH "Authorization: Bearer $ASC_TOKEN" \
  "https://api.appstoreconnect.apple.com/v1/ciProducts/$XCC_PRODUCT_ID/workflows" \
  | jq '.data[] | {id, name: .attributes.name, isEnabled: .attributes.isEnabled, xcodeVersion: .attributes.xcodeVersion.name}'
```

Expect 2 workflows: Tests on push (Xcode 16), Tests on push (Xcode 26). Both `isEnabled: true`.

### 9.2 — Trigger a build manually

Trigger a build on Workflow 1:

```bash
WORKFLOW_1_ID="<id of Tests on push (Xcode 16) from 9.1>"

curl -sX POST "https://api.appstoreconnect.apple.com/v1/ciBuildRuns" \
  -H "Authorization: Bearer $ASC_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"data\": {
      \"type\": \"ciBuildRuns\",
      \"relationships\": {
        \"workflow\": {\"data\": {\"type\": \"ciWorkflows\", \"id\": \"$WORKFLOW_1_ID\"}}
      }
    }
  }" | jq .
```

### 9.3 — Poll build status

```bash
BUILD_ID="<id from 9.2 response>"

while true; do
  STATUS=$(curl -sH "Authorization: Bearer $ASC_TOKEN" \
    "https://api.appstoreconnect.apple.com/v1/ciBuildRuns/$BUILD_ID" \
    | jq -r '.data.attributes.executionProgress')
  RESULT=$(curl -sH "Authorization: Bearer $ASC_TOKEN" \
    "https://api.appstoreconnect.apple.com/v1/ciBuildRuns/$BUILD_ID" \
    | jq -r '.data.attributes.completionStatus // "PENDING"')
  echo "$(date +%H:%M:%S) progress=$STATUS result=$RESULT"
  [ "$STATUS" = "COMPLETE" ] && break
  sleep 30
done
```

### 9.4 — Inspect build issues if failed

```bash
curl -sH "Authorization: Bearer $ASC_TOKEN" \
  "https://api.appstoreconnect.apple.com/v1/ciBuildRuns/$BUILD_ID/actions" \
  | jq '.data[] | {id, name: .attributes.name, completionStatus: .attributes.completionStatus}'

ACTION_ID="<id of failed action from above>"

curl -sH "Authorization: Bearer $ASC_TOKEN" \
  "https://api.appstoreconnect.apple.com/v1/ciBuildActions/$ACTION_ID/issues" \
  | jq '.data[] | {category: .attributes.category, message: .attributes.message}'
```

---

## Step 10 — Final report to user

Once everything is green, output a concise summary to Haithem:

```
✓ Xcode Cloud setup complete

  • App Lumen Morning (com.highthem.lumen) bound to Xcode Cloud
  • Workflow 1 "Tests on push (Xcode 16)" ✓ (last build: <BUILD_ID>, succeeded)
  • Workflow 2 "Tests on push (Xcode 26)" ✓ (last build: <BUILD_ID>, succeeded)
  • Workflow 3 "TestFlight on tag" ⏸ (disabled, activate on 10 May)
  • Env vars OPENAI_API_KEY, ANTHROPIC_API_KEY configured (Secret)

Next:
  • Push code to trigger automatic CI on next push
  • To trigger TestFlight: enable Workflow 3, then `git tag v1.0.0 && git push origin v1.0.0`
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `git push` rejected — "non-fast-forward" | Local diverged from remote after reset | `git pull --rebase`, fix conflicts, re-push |
| Workflow created via API but doesn't appear in Xcode | Cached UI; restart Xcode | Quit Xcode, re-open `Lumen.xcworkspace` |
| First build fails: "scheme `lumen` not shared" | Step 3 not done | Re-do Step 3 in Xcode UI, push the new `xcshareddata/`, re-trigger |
| First build fails: "OPENAI_API_KEY: missing" in `ci_post_clone` log | Step 8 not done or wrong scope | Re-add env vars on the product, ensure Secret is checked |
| First build fails: "Use of unresolved identifier 'FoundationModels'" on Xcode 16 workflow | Apple Intelligence code not gated | Wrap import in `#if canImport(FoundationModels)` and `@available(iOS 26.0, *)` (see Project/04_tech/adr/ADR-006-cicd-xcode-cloud.md) |
| ASC API returns 401 | Token expired (20 min lifetime) or signing issue | Re-run Step 7.2 to regenerate `ASC_TOKEN` |
| ASC API returns 403 on `ciWorkflows` POST | API key access too low | Regenerate the key with "Developer" or higher access |
| `git push` errors with `pre-commit hook failed` | Pre-commit hooks active | Diagnose and fix (do NOT use `--no-verify` per project policy) |

---

## References

- Project ADR-006: `Project/04_tech/adr/ADR-006-cicd-xcode-cloud.md`
- Apple — [Configuring your first Xcode Cloud workflow](https://developer.apple.com/documentation/xcode/configuring-your-first-xcode-cloud-workflow)
- Apple — [Xcode Cloud Workflows and Builds API](https://developer.apple.com/documentation/appstoreconnectapi/xcode-cloud-workflows-and-builds)
- Apple — [App Store Connect API — JWT auth](https://developer.apple.com/documentation/appstoreconnectapi/generating_tokens_for_api_requests)
- Polpiella — [Using App Store Connect API to trigger Xcode Cloud workflows](https://www.polpiella.dev/using-app-store-connect-api-to-trigger-xcode-cloud-workflows)
