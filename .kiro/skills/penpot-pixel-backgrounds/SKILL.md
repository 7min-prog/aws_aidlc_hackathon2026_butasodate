# Penpot Pixel Art Background Management

Use when creating pixel art SVG backgrounds and applying them to Penpot screen designs.

## SVG Background Creation Rules

- ViewBox: `390x740` (iPhone screen size per design-rules.html)
- Always use `shape-rendering="crispEdges"` for pixel-perfect rendering
- Grid snap: all coordinates must be multiples of 2px
- Color palette: strictly follow `design/design-rules.html` (no custom colors)
- Key colors:
  - `#1A1228` (INK/dark bg), `#F4ECD8` (BG/warm light), `#FFF8E6` (PAPER)
  - `#F6C453` (YELLOW), `#FF9BB3` (PINK), `#6CB979` (GREEN)
  - `#5A8ED1` (BLUE), `#E8485A` (RED), `#3D2B4D` (INK2)
  - `#0A0612` (BLACK), `#E8D9B0` (BG·DEEP), `#2F6B3C` (GREEN·DK)
- Star pixels: 4x4px rects, scattered randomly
- Decorative elements (flowers, grass): 6x6px or 4x8px

## Penpot Integration

### Inserting backgrounds into screen boards

```javascript
// Create SVG shape and insert at index 0 (bottom layer)
const bg = penpot.createShapeFromSvg(svgString);
bg.name = "bg-meadow"; // consistent naming
screen.insertChild(0, bg); // index 0 = behind all other children
bg.x = screen.x; // align to board position
bg.y = screen.y;
```

### Setting board fill color

```javascript
screen.fills = [{ fillColor: "#5A8ED1", fillOpacity: 1 }];
```

### Asset placement

- Place background assets as standalone groups on the root (not inside Screen Template)
- Position them to the right of character sprites to avoid overlap
- Use `penpot.root.appendChild(shape)` to ensure root-level placement
- Find max X of existing content first: `penpotUtils.findShapes(predicate)` → calculate maxX

### Batch operations

When applying to many screens (30+), process in batches of 8 to avoid timeouts:

```javascript
const screens = penpotUtils.findShapes(predicate).slice(startIdx, endIdx);
for (const screen of screens) { /* insert bg */ }
```

### Common pitfalls

- `createShapeFromSvg` places shapes in the currently active board context — always reparent explicitly
- Shapes created at root may end up inside "Screen Template" board if it's the first child — verify with `parent.name`
- Use `parent?.name === "Root Frame"` to check if shape is at root level (not `parent === penpot.root`)
- After `insertChild(0, shape)`, set `x` and `y` to match the parent board's absolute position
- Board fills act as background color; SVG decorations go on top as child at index 0

## Inserting pixel art sprites into screens

### Why cloning existing SVG groups fails

Cloning a 256x256 SVG group and resizing to 120x120 results in each internal rect becoming <1px (e.g. 0.9375px). These sub-pixel shapes are invisible at normal zoom levels.

### Solution: Create a simplified SVG at target size

Instead of cloning and resizing, create a new SVG with `viewBox="0 0 120 120"` (or whatever target size) so that pixel rects remain ≥4px:

```javascript
const pigSvg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" shape-rendering="crispEdges">
  <rect width="120" height="120" fill="#E8D9B0"/>
  <rect x="20" y="20" width="80" height="70" fill="#FF9BB3"/>
  <!-- simplified pixel art at target resolution -->
</svg>`;

const pig = penpot.createShapeFromSvg(pigSvg);
pig.name = "pig-sprite";
screen.appendChild(pig);
pig.x = screen.x + offsetX;
pig.y = screen.y + offsetY;
```

### Z-order issues

- `appendChild` places at the end (highest index = frontmost)
- `insertChild(0, shape)` places at the back (behind everything)
- After inserting, verify with `parent.children.indexOf(shape)` — if `-1`, the shape is nested deeper
- Use `shape.bringToFront()` to ensure visibility, or hide overlapping placeholder rects with `placeholder.hidden = true`

### Hiding placeholder rectangles

When replacing placeholder ■ with actual sprites:
1. Hide the placeholder: `placeholder.hidden = true`
2. Also hide background areas (e.g. `avatar-area`): they may cover the sprite
3. Place sprite with `appendChild` (not `insertChild(0, ...)`) to ensure it's on top

## File naming convention

- `assets/pixel-art/backgrounds/bg-{name}.svg` for local files
- Penpot shape names: `BG-{Name}` for assets, `bg-{name}` for in-screen decorations
