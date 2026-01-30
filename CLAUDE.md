# Claude Instructions for Gigily Themes

## Project Overview
VS Code color theme extension inspired by Microsoft Office applications. Provides 14 themes (7 apps × 2 variants each).

## Theme Structure
- **Word** (blue): `#2B579A` - word-dark/light-color-theme.json
- **Sheet** (green): `#107C41` - excel-dark/light-color-theme.json
- **Slide** (orange): `#D04423` - powerpoint-dark/light-color-theme.json
- **Mail** (cyan): `#0078D4` - outlook-dark/light-color-theme.json
- **Note** (purple): `#80397B` - onenote-dark/light-color-theme.json
- **Slack** (aubergine): `#4A154B` - slack-dark/light-color-theme.json
- **Teams** (indigo): `#6264A7` - teams-dark/light-color-theme.json

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
| Word | #2B579A | #1D3D6C |
| Sheet | #107C41 | #0A5A2E |
| Slide | #D04423 | #9C3019 |
| Mail | #0078D4 | #005A9E |
| Note | #80397B | #5C2860 |
| Slack | #4A154B | #3F0E40 |
| Teams | #6264A7 | #464775 |

## Notes
- Always update all 14 theme files when changing shared properties
- Test both light and dark variants after changes
- Command center colors should have good contrast with title bar
