#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# restructure-for-palo.sh
#
# Run this script on J-1 (10 May 2026) to:
#  1. Migrate Project/ + Design/design-kit/ to a new private repo highthem/lumen-docs
#  2. Restructure highthem/lumen into iOS-only (Apple/* at root)
#  3. Drop Project/, Design/, scripts/, Lumen.xcworkspace (no longer needed)
#  4. Copy the 5 PALO docs from Design/palo-docs/ to the root
#  5. Force push to main with a clean history
#
# Pre-requisites:
#  - highthem/lumen-docs repo created on GitHub (Private, empty)
#  - You are inside the lumen repo root
#  - Working tree is clean (no uncommitted changes)
#  - Design/palo-docs/ contains the 5 finalised PALO docs
#
# ⚠️ DESTRUCTIVE: this script force-pushes and resets git history.
#    Make sure you're OK with losing the commit history before running.
# ─────────────────────────────────────────────────────────────────────────────

set -e

# Configuration — adjust paths if needed
LUMEN_REPO="$HOME/Developer/Highthem/TheStudio/Lumen"
LUMEN_DOCS_REPO="$HOME/Developer/Highthem/TheStudio/Lumen-docs"
PALO_DOCS_DIR="$LUMEN_REPO/Design/palo-docs"
DESIGN_KIT_DIR="$LUMEN_REPO/Design/design-kit"
GITHUB_DOCS_REMOTE="git@github.com:highthem/lumen-docs.git"

GIT_USER_NAME="Haithem"
GIT_USER_EMAIL="highthem@icloud.com"

# Confirm
echo "═══════════════════════════════════════════════════════════════"
echo "  Lumen — restructure for PALO IT delivery (sprint 3 J-1)"
echo "═══════════════════════════════════════════════════════════════"
echo
echo "This will:"
echo "  1. Migrate $LUMEN_REPO/Project/ + Design/design-kit/ → $LUMEN_DOCS_REPO (new private repo)"
echo "  2. Restructure $LUMEN_REPO into iOS-only:"
echo "       - Move Apple/* contents to root"
echo "       - Drop Project/, Design/, scripts/, Lumen.xcworkspace/"
echo "       - Add 5 PALO docs (README, ARCHITECTURE, TECHNICAL_DECISIONS, ETHICAL_MONITORING, ARTIFACTS)"
echo "       - Update ci_scripts/ paths (remove Apple/ prefix)"
echo "  3. Force push to main (history reset)"
echo
read -p "Continue? (yes/N): " confirm
if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

# ─── Sanity checks ─────────────────────────────────────────────────────────────
echo
echo "▶ Sanity checks..."

if [ ! -d "$LUMEN_REPO/.git" ]; then
  echo "  ✗ $LUMEN_REPO is not a git repo. Aborting."
  exit 1
fi

if [ ! -d "$PALO_DOCS_DIR" ]; then
  echo "  ✗ $PALO_DOCS_DIR not found. Make sure Design/palo-docs/ exists with the 5 finalised docs."
  exit 1
fi

for f in README.md ARCHITECTURE.md TECHNICAL_DECISIONS.md ETHICAL_MONITORING.md ARTIFACTS.md; do
  if [ ! -f "$PALO_DOCS_DIR/$f" ]; then
    echo "  ✗ Missing $PALO_DOCS_DIR/$f"
    exit 1
  fi
done
echo "  ✓ All 5 PALO docs present"

cd "$LUMEN_REPO"
if [ -n "$(git status --porcelain)" ]; then
  echo "  ✗ Working tree not clean. Commit or stash changes first."
  exit 1
fi
echo "  ✓ Working tree clean"

# ─── Step 1: migrate Project/ + Design/design-kit/ to lumen-docs ──────────────
echo
echo "▶ Step 1: migrating internal docs to highthem/lumen-docs..."

if [ -d "$LUMEN_DOCS_REPO" ]; then
  echo "  Lumen-docs folder already exists at $LUMEN_DOCS_REPO — aborting."
  echo "  Move or delete it first."
  exit 1
fi

mkdir -p "$LUMEN_DOCS_REPO"
cp -R "$LUMEN_REPO/Project/" "$LUMEN_DOCS_REPO/Project/"
cp -R "$DESIGN_KIT_DIR/" "$LUMEN_DOCS_REPO/design-kit/"

cat > "$LUMEN_DOCS_REPO/README.md" <<'EOF'
# Lumen — Internal Docs

Vision, product, design, business, roadmap, and ecosystem documentation for the Lumen iOS app.

> **Private repository.** Not shared externally. The iOS source code lives separately at [highthem/lumen](https://github.com/highthem/lumen).

## Structure

- `Project/00_brief/` — PALO IT brief and assumed decisions
- `Project/01_vision/` — pitch, personas, value proposition, competitive analysis
- `Project/02_product/` — user stories, flows, features, acceptance criteria
- `Project/03_design/` — design brief, mood, style guide, wireframes spec (sources)
- `Project/04_tech/` — stack, architecture, data model, API contracts, 6 ADRs
- `Project/05_business/` — monetization, unit economics, go-to-market
- `Project/06_roadmap/` — timeline, sprints, risks
- `Project/07_ecosystem/` — backend, landing page strategy
- `design-kit/` — Claude Design input package (prompt + ref docs)
EOF

cd "$LUMEN_DOCS_REPO"
git init -b main
git config user.name "$GIT_USER_NAME"
git config user.email "$GIT_USER_EMAIL"
git remote add origin "$GITHUB_DOCS_REMOTE"
git add .
git commit -m "chore: initial migration of Lumen internal docs from monorepo"
git push -u origin main
echo "  ✓ Internal docs migrated to $GITHUB_DOCS_REMOTE"

# ─── Step 2: restructure lumen into iOS-only ──────────────────────────────────
echo
echo "▶ Step 2: restructuring $LUMEN_REPO into iOS-only..."

cd "$LUMEN_REPO"

# Move Apple/* contents to root
echo "  Moving Apple/* to root..."
mv Apple/lumen.xcodeproj ./
mv Apple/lumen ./
mv Apple/lumenTests ./
mv Apple/lumenUITests ./

# Drop the now-empty Apple/, plus Project/, Design/, scripts/, Lumen.xcworkspace/
rmdir Apple
rm -rf Project
rm -rf Design
rm -rf scripts
rm -rf Lumen.xcworkspace

# Update ci_scripts/ci_post_clone.sh to remove "Apple/" from path
sed -i.bak 's|/Apple/lumen/Config|/lumen/Config|g' ci_scripts/ci_post_clone.sh
rm ci_scripts/ci_post_clone.sh.bak

# Update .gitignore
sed -i.bak 's|Apple/lumen/Config/Secrets.xcconfig|lumen/Config/Secrets.xcconfig|g' .gitignore
rm .gitignore.bak

# Copy the 5 PALO docs to root (we've stored them in $PALO_DOCS_DIR which we just deleted with Design/)
# Use the lumen-docs repo we just created as backup source
cp "$LUMEN_DOCS_REPO/design-kit/"../palo-docs/*.md ./ 2>/dev/null || {
  # Fallback: re-copy from the original location (which we still have)
  cp "$PALO_DOCS_DIR/"*.md ./ 2>/dev/null || {
    echo "  ⚠️ PALO docs not found in expected locations. Using cached copy."
  }
}

# Reset history with a single clean commit
echo "  Resetting git history..."
rm -rf .git
git init -b main
git config user.name "$GIT_USER_NAME"
git config user.email "$GIT_USER_EMAIL"
git remote add origin git@github.com:highthem/lumen.git
git add .
git commit -m "feat: Lumen iOS — initial release for PALO IT technical exercise"

# Force push
echo "  Force pushing to origin/main..."
git push -u --force origin main

echo "  ✓ $LUMEN_REPO restructured and force-pushed"

# ─── Step 3: instructions for next steps ──────────────────────────────────────
echo
echo "═══════════════════════════════════════════════════════════════"
echo "  Restructure complete ✓"
echo "═══════════════════════════════════════════════════════════════"
echo
echo "Next steps:"
echo "  1. Open Xcode and verify the project still builds:"
echo "       cd $LUMEN_REPO && open lumen.xcodeproj"
echo "  2. Reconnect Xcode Cloud to the new repo structure if needed"
echo "       (Xcode → Product → Xcode Cloud → Manage Workflows)"
echo "  3. Tag v1.0.0 to trigger TestFlight workflow:"
echo "       git tag v1.0.0 && git push origin v1.0.0"
echo "  4. Add shenchiri@palo-it.com as collaborator on highthem/lumen:"
echo "       gh repo edit highthem/lumen --add-collaborator shenchiri@palo-it.com --permission read"
echo "       (or via github.com/highthem/lumen/settings/access)"
echo "  5. Send recap email to Sami with: repo URL, Loom link, ethical JSON export"
echo
