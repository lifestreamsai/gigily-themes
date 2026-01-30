#!/bin/bash
# Build script for Gigily Themes VS Code extension
# Usage: ./scripts/build.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo -e "${YELLOW}Building Gigily Themes...${NC}"

# Check if vsce is available
if ! command -v npx &> /dev/null; then
    echo -e "${RED}Error: npx is not installed. Please install Node.js.${NC}"
    exit 1
fi

# Get current version from package.json
VERSION=$(node -p "require('./package.json').version")
PACKAGE_NAME="office-themes-${VERSION}.vsix"

echo -e "Version: ${GREEN}${VERSION}${NC}"

# Check if icon.png exists
if [ ! -f "icon.png" ]; then
    echo -e "${YELLOW}Warning: icon.png not found. Checking for icon.svg...${NC}"
    if [ -f "icon.svg" ]; then
        echo "Converting icon.svg to icon.png..."
        if command -v rsvg-convert &> /dev/null; then
            rsvg-convert -w 256 -h 256 icon.svg -o icon.png
            echo -e "${GREEN}Icon converted successfully.${NC}"
        else
            echo -e "${RED}Error: rsvg-convert not found. Install librsvg or manually convert icon.svg to icon.png${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Error: No icon file found.${NC}"
        exit 1
    fi
fi

# Clean up old packages
if ls *.vsix 1> /dev/null 2>&1; then
    echo "Cleaning up old .vsix files..."
    rm -f *.vsix
fi

# Build the package
echo "Packaging extension..."
npx @vscode/vsce package --allow-missing-repository

# Verify the package was created
if [ -f "$PACKAGE_NAME" ]; then
    echo -e "${GREEN}✓ Successfully created: ${PACKAGE_NAME}${NC}"
    echo -e "  Size: $(du -h "$PACKAGE_NAME" | cut -f1)"
else
    echo -e "${RED}Error: Package was not created.${NC}"
    exit 1
fi

echo -e "${GREEN}Build complete!${NC}"
