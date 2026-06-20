# Changelog

## 0.2.0

Re-architected `Image` from a `(Point) -> Color` function into a declarative
**tree** (faithful to OCaml [Vg](https://github.com/dbuenzli/vg)), folded once
into a backend-neutral draw list that each backend renders to **compact native
vector output** — a circle is one `<path>`, not thousands of sampled `<rect>`s.

### Breaking

- `Image` is now an enum (`Primitive` / `Cut` / `Blend` / `Tr` / `Text`), no
  longer a function wrapper. The old `primitive_*` / `imageop_*` constructors are
  removed.
- `compose` is **source-over**: `base.compose(overlay)` paints the overlay on
  top (was additive blending).
- `Image::line` is now a stroked outline with round caps (was a filled quad).

### Added

- **Native vector renderers**: `Image::to_svg`, `Image::to_pdf`, and
  `Image::to_js` (HTML5 canvas) fold the AST into one element per shape.
- `Image::eval` — the denotation (point → colour); the raster ground truth and
  the fallback for procedural images.
- Axial/radial gradients, non-zero and even-odd fills, stroke outlines
  (`Area::Outline`), procedural images via a `Raster` primitive (`of_fn`,
  `checkerboard`, `tile`, `conic_gradient`), and draw-only text (`Image::text`).
- Per-format escaping (XML / PDF literal / JS string) in text output.

### Fixed

- The `render_image_to_svg` sampler used a width-based y-step, distorting
  non-square canvases; it now uses the correct height-based step.

## 0.1.4

Initial published versions: core types, color/point/transform utilities, shape
and path construction, and SVG/PDF/Canvas document builders.
