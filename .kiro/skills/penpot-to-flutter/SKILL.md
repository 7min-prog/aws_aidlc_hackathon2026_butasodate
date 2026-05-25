# Penpot to Flutter Implementation

Use when implementing Flutter screens from Penpot designs.

## Critical Rules

1. **Always visually confirm with `export_shape`** before implementing. Never rely solely on raw data values.
2. **Check for existing SVG assets** in `assets/pixel-art/backgrounds/` before recreating backgrounds in code. If a matching SVG exists (e.g. `bg-barn.svg`, `bg-meadow.svg`, `bg-starry.svg`), use `flutter_svg` to render it.
3. **Background groups are NOT single colors.** When Penpot returns a group (e.g. `bg-barn`, `bg-meadow`) with `fills: []`, it contains a full pixel art scene made of many rects. Do NOT assume a single background color from the first child element.
4. **Use ratio-based positioning.** Penpot designs are 390x740. Use `sx = screenWidth / 390` and `sy = screenHeight / 740` to scale all coordinates.
5. **Text alignment comes from Penpot's `align` property.** Always check it — most text is `center` aligned with full-width positioning (`left: 0, right: 0`).
6. **Fonts are bundled as assets**, not loaded via google_fonts. Use `kFontDotGothic16` and `kFontPressStart2P` constants from `theme.dart`.

## Background Implementation Pattern

```dart
import 'package:flutter_svg/flutter_svg.dart';

// In Stack:
Positioned.fill(
  child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-barn.svg', fit: BoxFit.cover),
),
```

## Available Backgrounds

| File | Used in | Description |
|------|---------|-------------|
| bg-barn.svg | A-01 Login | Blue sky + pink barn roof + brown wood walls + green grass |
| bg-meadow.svg | M-01 Home | Blue sky + green meadow + flowers |
| bg-battle.svg | B-03 Battle | Arena background |
| bg-battle-full.svg | B-03 variant | Full arena |
| bg-home-full.svg | M-01 variant | Full home |
| bg-record.svg | R-01 Category | Interior/room background |
| bg-room.svg | General | Room interior |
| bg-auth.svg | Auth screens | Auth background |
| bg-arena.svg | Battle screens | Arena |

## Starry Background (Animated)

For screens with `bg-starry` (X-00, X-02, X-06a/b/c), use the shared `StarryBackground` widget:

```dart
import 'package:buta_app/shared/starry_background.dart';

const StarryBackground(seed: 42) // seed controls star pattern
```

## Common Mistakes to Avoid

- ❌ Using `backgroundColor: ButaColors.ink` when the screen has a full SVG background
- ❌ Reading only the first fill color of a background group
- ❌ Using fixed pixel positions without scaling (causes misalignment on different screen sizes)
- ❌ Using google_fonts package (removed — fonts are bundled)
- ✅ Always export and visually inspect the screen first
- ✅ Check `assets/pixel-art/backgrounds/` for existing SVGs
- ✅ Use `StarryBackground` widget for animated star backgrounds

## Visual Verification with agent-browser

After implementing a screen, always verify visually using agent-browser:

**Self-comparison workflow** (never ask the user "what's different?"):
1. Export the Penpot design with `export_shape` to get the reference image
2. Take a screenshot with agent-browser to get the implementation image
3. Compare both images yourself and identify ALL differences
4. Fix all differences before presenting the result

**Development server startup order**:
1. Start mock server first: `cd mock-server && npm run dev`
2. Build and serve: `cd frontend && flutter build web && cd build/web && python -m http.server 8084`
3. Access at `http://localhost:8084/#/login`

```bash
# 1. Build the Flutter web app
cd frontend && flutter build web

# 2. Serve it locally (if not already running)
cd frontend/build/web && python -m http.server 8080

# 3. Set viewport to mobile size (390x740 matches Penpot design)
agent-browser set viewport 390 740

# 4. Navigate to the specific screen
agent-browser navigate http://localhost:8080/#/login

# 5. Wait for rendering and take screenshot
agent-browser wait 2000
agent-browser screenshot screenshots/screen-name.png
```

Key points:
- **Always set viewport to 390x740** before taking screenshots — desktop-sized viewports will break the ratio-based layout
- Use hash routing (`/#/login`) for Flutter web navigation
- Screenshots go to `frontend/screenshots/` for comparison
- **Cache busting**: After rebuilding, restart the python server AND use a query param to bust browser cache: `navigate "http://localhost:8084/?v=2#/login"`
- If assets (SVGs, fonts) don't update, delete `build/` folder before rebuilding: `Remove-Item -Recurse -Force build`

## Layout Pattern (AspectRatio + LayoutBuilder)

For screens that must maintain 390:740 ratio on any device/browser size:

```dart
Scaffold(
  backgroundColor: ButaColors.blue, // fallback color matching SVG sky
  body: Center(
    child: AspectRatio(
      aspectRatio: 390 / 740,
      child: LayoutBuilder(builder: (context, constraints) {
        final sx = constraints.maxWidth / 390;
        final sy = constraints.maxHeight / 740;
        return Stack(children: [
          Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-barn.svg', fit: BoxFit.cover)),
          // ... positioned children using sx/sy ...
        ]);
      }),
    ),
  ),
);
```

This ensures the layout stays correct regardless of browser window size (landscape, desktop, etc.).


## Multi-Device Testing

After confirming on 390x740 (Penpot design size), test on real device sizes:

```bash
# iPhone 17 (393x852)
agent-browser set viewport 393 852
agent-browser navigate http://localhost:8080/#/login
agent-browser wait 2000
agent-browser screenshot screenshots/login-iphone17.png

# Galaxy S26 (412x915)
agent-browser set viewport 412 915
agent-browser navigate http://localhost:8080/#/login
agent-browser wait 2000
agent-browser screenshot screenshots/login-galaxy-s26.png
```

Common device sizes:
| Device | Width | Height |
|--------|-------|--------|
| Penpot design | 390 | 740 |
| iPhone 17 | 393 | 852 |
| Galaxy S26 | 412 | 915 |

Always test both sizes after implementing a new screen to catch scaling issues.

## Complete Screen Implementation Workflow

When implementing or modifying a screen, follow this exact sequence:

### 1. Penpot Design Confirmation
```bash
# Get screen structure
execute_code: findShape → children map (name, type, x, y, w, h, fills, chars)
# Visual confirmation
export_shape: shapeId → compare with implementation
```

### 2. Code Modification
- API integration: use `apiClientProvider` with try/catch for graceful fallback
- Always provide default values when API fails
- Use ratio-based positioning: `sx = width / 390`, `sy = height / 740`

### 3. Build Verification
```bash
cd frontend && flutter analyze 2>&1
cd frontend && Remove-Item -Recurse -Force build 2>$null; flutter build web 2>&1
```

### 4. Visual Verification with agent-browser
```bash
# Start static server (flutter run has issues with agent-browser)
Get-Process -Name python -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process powershell -ArgumentList "-Command","cd 'frontend\build\web'; python -m http.server 8085"

# IMPORTANT: Always verify at 390x740 first (matches Penpot design size)
agent-browser set viewport 390 740
agent-browser navigate "http://localhost:8085/?v=N#/screen-path"
Start-Sleep -Seconds 5
agent-browser screenshot "screenshots/screen-name.png"
```

**IMPORTANT**:
- **Always set viewport to 390x740 for design comparison** — this matches the Penpot canvas size exactly
- Use static build (`python -m http.server`) for serving. Never use `flutter run`.
- Multi-device testing (iPhone 17, Galaxy S26) is done AFTER confirming 390x740 matches Penpot

### 5. Multi-Device Testing
```bash
# iPhone 17
agent-browser set viewport 393 852
agent-browser navigate "http://localhost:8085/?v=N#/screen-path"
agent-browser screenshot "screenshots/screen-iphone17.png"

# Galaxy S26
agent-browser set viewport 412 915
agent-browser navigate "http://localhost:8085/?v=N#/screen-path"
agent-browser screenshot "screenshots/screen-galaxy-s26.png"
```

### 6. Cache Busting
- Increment `?v=N` query parameter on each rebuild
- Delete `build/` folder before rebuilding if assets don't update
- Restart python server after each rebuild

### Key Learnings
- Always use `flutter build web` + `python -m http.server` for both user and agent-browser
- `bootProvider` with complex async logic can block splash screen — simplify for dev
- API errors should always fall back to sensible defaults, never show "エラー" to user
- `connectivity_plus` may not work correctly in web environment
