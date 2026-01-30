#!/bin/bash
# Screenshot generator for Gigily Themes
# Usage: ./scripts/screenshots.sh [--skip-capture]
#
# Generates individual theme screenshots and creates composite images
# with 3D overlay effect for marketplace display.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_ROOT/screenshots"
SAMPLE_FILE="$SCRIPT_DIR/samples/showcase.ts"

# Parse arguments
SKIP_CAPTURE=false
if [[ "$1" == "--skip-capture" ]]; then
    SKIP_CAPTURE=true
fi

# Theme definitions: "Display Name|filename"
DARK_THEMES=(
    "Gigily Word Dark|word-dark"
    "Gigily Sheet Dark|sheet-dark"
    "Gigily Slide Dark|slide-dark"
    "Gigily Mail Dark|mail-dark"
    "Gigily Note Dark|note-dark"
    "Gigily Slack Dark|slack-dark"
    "Gigily Teams Dark|teams-dark"
)

LIGHT_THEMES=(
    "Gigily Word Light|word-light"
    "Gigily Sheet Light|sheet-light"
    "Gigily Slide Light|slide-light"
    "Gigily Mail Light|mail-light"
    "Gigily Note Light|note-light"
    "Gigily Slack Light|slack-light"
    "Gigily Teams Light|teams-light"
)

# Check for macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: This script requires macOS.${NC}"
    exit 1
fi

# Check for ImageMagick
if ! command -v magick &> /dev/null && ! command -v convert &> /dev/null; then
    echo -e "${RED}Error: ImageMagick is required for creating composite images.${NC}"
    echo "Install with: brew install imagemagick"
    exit 1
fi

# Use 'magick' if available, otherwise 'convert'
if command -v magick &> /dev/null; then
    CONVERT="magick"
else
    CONVERT="convert"
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}         Gigily Themes Screenshot Generator                ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to capture a single theme screenshot
capture_theme() {
    local theme_name="$1"
    local file_name="$2"
    local output_file="$OUTPUT_DIR/${file_name}.png"

    echo -e "  Capturing: ${GREEN}${theme_name}${NC}"

    # Use AppleScript to switch theme via Command Palette
    # First, use VS Code CLI to set the theme directly
    code --force --profile "Default" --install-extension "$PROJECT_ROOT"/*.vsix 2>/dev/null || true

    osascript <<EOF
tell application "Visual Studio Code"
    activate
    delay 0.5
end tell

tell application "System Events"
    tell process "Code"
        -- Open Command Palette with Cmd+Shift+P
        keystroke "p" using {command down, shift down}
        delay 0.6

        -- Type the exact command to set theme
        keystroke "Preferences: Color Theme"
        delay 0.8
        keystroke return
        delay 0.8

        -- Type theme name (partial match should work for installed themes)
        keystroke "${theme_name}"
        delay 1.0

        -- Press Down arrow to ensure we select from installed themes (top of list)
        -- then press Return
        keystroke return
        delay 2.0

        -- Press Escape to close any remaining dialogs
        key code 53
        delay 0.5
    end tell
end tell
EOF

    # Resize and position the window for consistent screenshots
    osascript <<EOF2
tell application "Visual Studio Code"
    activate
end tell
tell application "System Events"
    tell process "Code"
        try
            set position of window 1 to {50, 50}
            set size of window 1 to {1280, 800}
        end try
    end tell
end tell
EOF2
    sleep 1.5

    # Capture full screen and crop to the window region
    local temp_file="$OUTPUT_DIR/temp_fullscreen.png"
    screencapture -x "$temp_file"

    # Crop to the VS Code window area (50,50 position, 1280x800 size)
    if [[ -f "$temp_file" ]]; then
        $CONVERT "$temp_file" -crop 1280x800+50+50 +repage "$output_file"
        rm -f "$temp_file"
        echo "    ✓ Saved: $file_name.png"
    else
        echo "    Warning: Screenshot capture failed for $file_name"
    fi
}

# Function to create 3D cascading overlay composite
create_3d_composite() {
    local output_file="$1"
    local label="$2"
    shift 2
    local images=("$@")

    echo -e "Creating 3D composite: ${GREEN}${label}${NC}"

    local count=${#images[@]}
    local canvas_width=1600
    local canvas_height=1000

    # Calculate offsets for cascading effect
    local x_offset=60
    local y_offset=40
    local scale_factor=0.55

    # Start with transparent canvas
    $CONVERT -size ${canvas_width}x${canvas_height} xc:transparent "$OUTPUT_DIR/temp_composite.png"

    # Process each image with 3D perspective effect
    for ((i=count-1; i>=0; i--)); do
        local img="${images[$i]}"
        local x=$((50 + (count - 1 - i) * x_offset))
        local y=$((30 + (count - 1 - i) * y_offset))

        if [[ -f "$img" ]]; then
            # Create shadow
            $CONVERT "$img" \
                -resize ${scale_factor}00% \
                \( +clone -background '#00000060' -shadow 80x8+12+12 \) \
                +swap -background none -layers merge +repage \
                -bordercolor '#ffffff' -border 1 \
                "$OUTPUT_DIR/temp_layer_$i.png"

            # Add subtle 3D perspective distortion
            local width=$($CONVERT "$OUTPUT_DIR/temp_layer_$i.png" -format "%w" info:)
            local height=$($CONVERT "$OUTPUT_DIR/temp_layer_$i.png" -format "%h" info:)

            # Slight perspective skew for 3D effect
            local skew=$((i * 2))
            $CONVERT "$OUTPUT_DIR/temp_layer_$i.png" \
                -virtual-pixel transparent \
                -distort Perspective \
                    "0,0 ${skew},${skew}  ${width},0 $((width-skew)),${skew}  0,${height} ${skew},$((height-skew))  ${width},${height} $((width-skew)),$((height-skew))" \
                "$OUTPUT_DIR/temp_layer_$i.png"

            # Composite onto canvas
            $CONVERT "$OUTPUT_DIR/temp_composite.png" \
                "$OUTPUT_DIR/temp_layer_$i.png" \
                -geometry +${x}+${y} \
                -composite \
                "$OUTPUT_DIR/temp_composite.png"
        fi
    done

    # Trim and finalize
    $CONVERT "$OUTPUT_DIR/temp_composite.png" -trim +repage "$output_file"

    # Clean up temp files
    rm -f "$OUTPUT_DIR"/temp_layer_*.png "$OUTPUT_DIR/temp_composite.png"

    echo -e "  ${GREEN}✓ Saved: ${output_file}${NC}"
}

# Function to create simple fan/cascade composite (fallback if perspective fails)
create_cascade_composite() {
    local output_file="$1"
    local label="$2"
    shift 2
    local images=("$@")

    echo -e "Creating cascade composite: ${GREEN}${label}${NC}"

    local count=${#images[@]}
    local x_step=80
    local y_step=50
    local scale="45%"

    # Build the composite command
    local cmd="$CONVERT -size 1400x900 xc:transparent"

    for ((i=count-1; i>=0; i--)); do
        local img="${images[$i]}"
        local x=$((40 + (count - 1 - i) * x_step))
        local y=$((20 + (count - 1 - i) * y_step))

        if [[ -f "$img" ]]; then
            cmd="$cmd \\( \"$img\" -resize $scale"
            cmd="$cmd \\( +clone -background '#00000050' -shadow 60x6+8+8 \\)"
            cmd="$cmd +swap -background none -layers merge +repage"
            cmd="$cmd -bordercolor '#e0e0e0' -border 1 \\)"
            cmd="$cmd -geometry +${x}+${y} -composite"
        fi
    done

    cmd="$cmd -trim +repage \"$output_file\""

    eval $cmd

    echo -e "  ${GREEN}✓ Saved: ${output_file}${NC}"
}

# ============================================================
# STEP 1: Capture individual screenshots
# ============================================================

if [[ "$SKIP_CAPTURE" == false ]]; then
    # Check if VS Code is available
    if ! command -v code &> /dev/null; then
        echo -e "${RED}Error: VS Code CLI 'code' not found.${NC}"
        echo "Install it from VS Code: Cmd+Shift+P → 'Shell Command: Install code command'"
        exit 1
    fi

    echo -e "${YELLOW}Step 1: Capturing individual theme screenshots${NC}"
    echo ""
    echo -e "${YELLOW}Note: This requires accessibility permissions for AppleScript.${NC}"
    echo "Grant access at: System Preferences → Privacy & Security → Accessibility"
    echo ""

    # Install extension locally for accurate theme colors
    echo "Installing extension locally..."
    VSIX_FILE=$(ls -t "$PROJECT_ROOT"/*.vsix 2>/dev/null | head -1)
    if [[ -n "$VSIX_FILE" ]]; then
        code --install-extension "$VSIX_FILE" --force
    else
        echo "Building extension first..."
        npx @vscode/vsce package --allow-missing-repository
        VSIX_FILE=$(ls -t "$PROJECT_ROOT"/*.vsix | head -1)
        code --install-extension "$VSIX_FILE" --force
    fi
    sleep 2

    # Open VS Code in a NEW window (not in dev mode) for accurate status bar colors
    echo "Opening VS Code in new window..."
    code --new-window "$SAMPLE_FILE" &
    sleep 5

    # Capture dark themes
    echo -e "\n${BLUE}Capturing Dark Themes:${NC}"
    for theme_entry in "${DARK_THEMES[@]}"; do
        IFS='|' read -r THEME_NAME FILE_NAME <<< "$theme_entry"
        capture_theme "$THEME_NAME" "$FILE_NAME"
    done

    # Capture light themes
    echo -e "\n${BLUE}Capturing Light Themes:${NC}"
    for theme_entry in "${LIGHT_THEMES[@]}"; do
        IFS='|' read -r THEME_NAME FILE_NAME <<< "$theme_entry"
        capture_theme "$THEME_NAME" "$FILE_NAME"
    done

    echo -e "\n${GREEN}✓ All individual screenshots captured${NC}"
else
    echo -e "${YELLOW}Skipping capture (--skip-capture flag set)${NC}"
fi

# ============================================================
# STEP 2: Create composite images
# ============================================================

echo ""
echo -e "${YELLOW}Step 2: Creating 3D composite images${NC}"

# Prepare image arrays
DARK_IMAGES=()
LIGHT_IMAGES=()

for theme_entry in "${DARK_THEMES[@]}"; do
    IFS='|' read -r _ FILE_NAME <<< "$theme_entry"
    DARK_IMAGES+=("$OUTPUT_DIR/${FILE_NAME}.png")
done

for theme_entry in "${LIGHT_THEMES[@]}"; do
    IFS='|' read -r _ FILE_NAME <<< "$theme_entry"
    LIGHT_IMAGES+=("$OUTPUT_DIR/${FILE_NAME}.png")
done

# Create dark themes composite
create_cascade_composite "$OUTPUT_DIR/dark-themes-composite.png" "Dark Themes" "${DARK_IMAGES[@]}"

# Create light themes composite
create_cascade_composite "$OUTPUT_DIR/light-themes-composite.png" "Light Themes" "${LIGHT_IMAGES[@]}"

# Create combined showcase (dark + light side by side)
echo -e "Creating combined showcase..."
$CONVERT "$OUTPUT_DIR/dark-themes-composite.png" "$OUTPUT_DIR/light-themes-composite.png" \
    +append -background none \
    "$OUTPUT_DIR/all-themes-showcase.png"
echo -e "  ${GREEN}✓ Saved: all-themes-showcase.png${NC}"

# ============================================================
# Summary
# ============================================================

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Screenshot generation complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Individual screenshots:"
ls -1 "$OUTPUT_DIR"/*.png 2>/dev/null | grep -v composite | grep -v showcase | while read f; do
    echo "  - $(basename "$f")"
done
echo ""
echo "Composite images for marketplace:"
echo -e "  - ${GREEN}dark-themes-composite.png${NC}  (5 dark themes overlaid)"
echo -e "  - ${GREEN}light-themes-composite.png${NC} (5 light themes overlaid)"
echo -e "  - ${GREEN}all-themes-showcase.png${NC}    (both composites side by side)"
echo ""
echo -e "Output directory: ${BLUE}$OUTPUT_DIR${NC}"
