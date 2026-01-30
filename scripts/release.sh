#!/bin/bash
# Release script for Gigily Themes VS Code extension
# Usage: ./scripts/release.sh [major|minor|patch] [--skip-screenshots]
# Default: patch

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Parse arguments
BUMP_TYPE="patch"
SKIP_SCREENSHOTS=false

for arg in "$@"; do
    case "$arg" in
        major|minor|patch)
            BUMP_TYPE="$arg"
            ;;
        --skip-screenshots)
            SKIP_SCREENSHOTS=true
            ;;
        *)
            echo -e "${RED}Error: Unknown argument '$arg'${NC}"
            echo "Usage: ./scripts/release.sh [major|minor|patch] [--skip-screenshots]"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}           Gigily Themes Release Script                    ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

# Get current version
CURRENT_VERSION=$(node -p "require('./package.json').version")
echo -e "Current version: ${YELLOW}${CURRENT_VERSION}${NC}"

# Calculate new version
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

case "$BUMP_TYPE" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
echo -e "New version:     ${GREEN}${NEW_VERSION}${NC} (${BUMP_TYPE})"
echo -e "Screenshots:     $([ "$SKIP_SCREENSHOTS" = true ] && echo "${YELLOW}skipped${NC}" || echo "${GREEN}enabled${NC}")"
echo ""

# Confirm with user
read -p "Proceed with release? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Release cancelled.${NC}"
    exit 0
fi

# ============================================================
# STEP 1: Generate screenshots (optional)
# ============================================================

if [[ "$SKIP_SCREENSHOTS" == false ]]; then
    echo ""
    echo -e "${YELLOW}Step 1/5: Generating theme screenshots...${NC}"

    # Check if ImageMagick is available
    if ! command -v magick &> /dev/null && ! command -v convert &> /dev/null; then
        echo -e "${YELLOW}Warning: ImageMagick not found. Skipping screenshots.${NC}"
        echo "Install with: brew install imagemagick"
    else
        # Run the screenshot script
        "$SCRIPT_DIR/screenshots.sh"
    fi
else
    echo ""
    echo -e "${YELLOW}Step 1/5: Skipping screenshots (--skip-screenshots)${NC}"
fi

# ============================================================
# STEP 2: Update version
# ============================================================

echo ""
echo -e "${YELLOW}Step 2/5: Updating version in package.json...${NC}"

# Update package.json version using node
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.version = '${NEW_VERSION}';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"
echo -e "${GREEN}✓ Version updated to ${NEW_VERSION}${NC}"

# ============================================================
# STEP 3: Build package
# ============================================================

echo ""
echo -e "${YELLOW}Step 3/5: Building package...${NC}"

# Check if icon.png exists
if [ ! -f "icon.png" ]; then
    if [ -f "icon.svg" ]; then
        echo "Converting icon.svg to icon.png..."
        if command -v rsvg-convert &> /dev/null; then
            rsvg-convert -w 256 -h 256 icon.svg -o icon.png
        else
            echo -e "${RED}Error: rsvg-convert not found. Please convert icon.svg manually.${NC}"
            exit 1
        fi
    fi
fi

# Clean up old packages
rm -f *.vsix

# Build the package
PACKAGE_NAME="office-themes-${NEW_VERSION}.vsix"
npx @vscode/vsce package --allow-missing-repository

if [ ! -f "$PACKAGE_NAME" ]; then
    echo -e "${RED}Error: Package was not created.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Package created: ${PACKAGE_NAME}${NC}"

# ============================================================
# STEP 4: Git commit and tag
# ============================================================

echo ""
echo -e "${YELLOW}Step 4/5: Creating git commit and tag...${NC}"

# Check for uncommitted changes (other than package.json)
if [[ -n $(git status --porcelain | grep -v "package.json") ]]; then
    echo -e "${YELLOW}Warning: You have uncommitted changes besides package.json.${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Release cancelled. Please commit your changes first.${NC}"
        exit 0
    fi
fi

# Stage and commit
git add package.json
git commit -m "Release v${NEW_VERSION}"
echo -e "${GREEN}✓ Created commit for v${NEW_VERSION}${NC}"

# Create tag
git tag -a "v${NEW_VERSION}" -m "Release v${NEW_VERSION}"
echo -e "${GREEN}✓ Created tag v${NEW_VERSION}${NC}"

# ============================================================
# STEP 5: Summary
# ============================================================

echo ""
echo -e "${YELLOW}Step 5/5: Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "  Package:     ${GREEN}${PACKAGE_NAME}${NC}"
echo -e "  Size:        $(du -h "$PACKAGE_NAME" | cut -f1)"
echo -e "  Version:     ${GREEN}v${NEW_VERSION}${NC}"
echo -e "  Commit:      $(git rev-parse --short HEAD)"
if [[ "$SKIP_SCREENSHOTS" == false ]] && [[ -d "screenshots" ]]; then
    echo -e "  Screenshots: ${GREEN}screenshots/${NC}"
fi
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

echo ""
echo -e "${GREEN}Release v${NEW_VERSION} complete!${NC}"
echo ""
echo "Next steps:"
echo -e "  1. Push to GitHub:    ${YELLOW}git push && git push --tags${NC}"
echo -e "  2. Publish to VS Code Marketplace:"
echo -e "     ${YELLOW}npx @vscode/vsce publish${NC}"
echo -e "     or upload ${PACKAGE_NAME} manually at:"
echo -e "     https://marketplace.visualstudio.com/manage"
if [[ -d "screenshots" ]]; then
    echo ""
    echo -e "  3. Update marketplace images with screenshots from:"
    echo -e "     ${BLUE}screenshots/dark-themes-composite.png${NC}"
    echo -e "     ${BLUE}screenshots/light-themes-composite.png${NC}"
fi
