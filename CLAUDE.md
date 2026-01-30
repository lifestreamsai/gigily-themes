# Claude Instructions for Gigily Themes

## Project Overview
VS Code color theme extension inspired by Microsoft Office applications. Provides 10 themes (5 apps × 2 variants each).

## Theme Structure
- **Word** (blue): `#185ABD` - word-dark/light-color-theme.json
- **Sheet** (green): `#217346` - excel-dark/light-color-theme.json
- **Slide** (orange): `#C43E1C` - powerpoint-dark/light-color-theme.json
- **Mail** (cyan): `#0078D4` - outlook-dark/light-color-theme.json
- **Note** (purple): `#7719AA` - onenote-dark/light-color-theme.json

## Key Files
- `package.json` - Extension manifest, theme definitions, version
- `themes/*.json` - Theme color definitions (JSON with comments)
- `icon.svg` / `icon.png` - Extension logo (256x256)
- `readme.md` - Marketplace description

## Common Tasks

### Editing Theme Colors
Theme files use VS Code color tokens. Key sections:
- `activityBar` - Left sidebar icons
- `titleBar` - Window title bar
- `commandCenter` - Search box in title bar
- `statusBar` - Bottom status bar
- `editor` - Main editor area

### Building
```bash
npx @vscode/vsce package --allow-missing-repository
```

### Version Bumping
Update `version` in package.json before building.

### Converting Logo
```bash
rsvg-convert -w 256 -h 256 icon.svg -o icon.png
```

## Brand Colors Reference
| App | Primary | Dark Accent |
|-----|---------|-------------|
| Sheet | #217346 | #1A5A38 |
| Word | #185ABD | #0F3A7A |
| Slide | #C43E1C | #8A3518 |
| Mail | #0078D4 | #005A9E |
| Note | #7719AA | #5C1483 |

## Notes
- Always update all 10 theme files when changing shared properties
- Test both light and dark variants after changes
- Command center colors should have good contrast with title bar
