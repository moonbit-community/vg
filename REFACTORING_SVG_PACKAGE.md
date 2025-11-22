# SVG Package Refactoring

**Date:** November 22, 2025

## Overview

This refactoring splits out the `SvgDocument` type and all SVG rendering utilities into a separate `svg` package to improve modularity and reduce coupling in the VG vector graphics library. This follows the same pattern previously used for the geometry and color package refactorings. Importantly, the `Image::render_image_to_svg` method is kept in the main `vg` package as it represents a rendering backend method for the Image type.

## Changes Made

### New Package Structure

Created `svg/` package with:
- `svg/types.mbt` - Core SvgDocument type definition
- `svg/svg.mbt` - All SVG rendering methods and utilities
- `svg/moon.pkg.json` - Package configuration with dependencies on geometry and color packages

### Type Migration

**Moved from `vg` package to `svg` package:**
- `SvgDocument` struct - SVG document representation with width, height, and elements array

**SVG functions moved:**
- Document creation: `new_svg`
- Document manipulation: `SvgDocument::add_element`, `SvgDocument::to_string`
- Rendering methods: `SvgDocument::render_circle`, `SvgDocument::render_rectangle`, `SvgDocument::render_path`, `SvgDocument::render_line`, `SvgDocument::render_text`, `SvgDocument::render_ellipse`, `SvgDocument::render_polygon`, `SvgDocument::render_linear_gradient`
- Helper functions: `color_to_svg`, `point_to_svg`, `path_to_svg_data`

**Kept in `vg` package:**
- `Image::render_image_to_svg` - Image rendering method (uses `@svg` namespace internally)

### Dependency Management

**Main package (`vg`) changes:**
- Updated `moon.pkg.json` to import `bobzhang/vg/svg`
- Modified `types.mbt` to re-export SvgDocument type using type alias:
  ```moonbit
  pub type SvgDocument = @svg.SvgDocument
  ```
- Updated `svg.mbt` to only contain `Image::render_image_to_svg` method
- Image rendering method now uses `@svg.new_svg` to create SVG documents

**SVG package dependencies:**
- Imports `bobzhang/vg/geometry` for Point and Path types
- Imports `bobzhang/vg/color` for Color type and utilities

### Code Updates Required

**In test files and documentation:**
- Replaced `@vg.new_svg` with `@svg.new_svg`
- All SvgDocument methods now accessed through the `@svg` namespace

**Examples:**
```moonbit
// Before:
let doc = @vg.new_svg(100.0, 100.0)
  .render_circle(Point::new(50.0, 50.0), 25.0, @color.red())

// After:
let doc = @svg.new_svg(100.0, 100.0)
  .render_circle(Point::new(50.0, 50.0), 25.0, @color.red())
```

**Files updated:**
- All test files (svg_test.mbt, oo_api_test.mbt, renderer_test.mbt, hello_test.mbt, advanced_test.mbt)
- README.mbt.md
- svg.mbt (now only contains Image::render_image_to_svg)
- types.mbt (added SvgDocument type re-export)
- moon.pkg.json (added svg package import)

### Backward Compatibility

The SvgDocument type remains accessible through the main package:
- The SvgDocument type is re-exported from the main package via type alias
- All existing type references like `SvgDocument` still work
- However, the creation and manipulation functions now require the `@svg` namespace
- This is a breaking change in the public API (functions moved from `@vg` to `@svg` namespace)

### Test Results

- All 175 tests pass
- No errors, only existing warnings about using package-qualified names in geometry package tests
- Build verification: `moon check` and `moon test` both succeed

## Migration Guide for External Users

If you're using the VG library and upgrading:

### Using SVG Functions

SVG functions must now be accessed through the `@svg` namespace:

```moonbit
// Creating SVG documents
let doc = @svg.new_svg(200.0, 200.0)

// Rendering shapes
let doc = @svg.new_svg(100.0, 100.0)
  .render_circle(@vg.Point::new(50.0, 50.0), 25.0, @color.red())
  .render_rectangle(10.0, 10.0, 80.0, 80.0, @color.blue())
  .render_text("Hello", @vg.Point::new(50.0, 50.0), 16.0, @color.black())

// Converting to string
let svg_string = doc.to_string()
```

### Using the SvgDocument Type

The SvgDocument type is still available through the main package via type alias:

```moonbit
// Type references work as before
let doc : SvgDocument = @svg.new_svg(100.0, 100.0)
let doc2 : @vg.SvgDocument = @svg.new_svg(100.0, 100.0)
```

### Image to SVG Rendering

The `Image::render_image_to_svg` method remains in the main `vg` package:

```moonbit
let img = @vg.Image::circle(@color.red(), 25.0)
let svg_string = img.render_image_to_svg(100.0, 100.0, 20)
```

### Migration from Previous Version

If you have existing code that used `@vg.new_svg`, update to use `@svg`:

```moonbit
// Before:
let doc = @vg.new_svg(100.0, 100.0)

// After:
let doc = @svg.new_svg(100.0, 100.0)
```

## Benefits

1. **Modularity** - SVG rendering types and utilities can be used independently of the full VG library
2. **Clarity** - Clear separation between SVG rendering backend and core image/graphics functionality
3. **Testability** - SVG package can have its own focused test suite
4. **Reusability** - Other packages can depend on just the svg package if needed for SVG generation
5. **Type Safety** - No change in type safety, all benefits of strong typing preserved
6. **Consistency** - Follows the same pattern as the geometry and color package refactorings
7. **Proper Architecture** - Keeps Image methods in the main package while SVG document operations are in the svg package

## Files Modified

- `svg/` - New package directory with types and rendering utilities
- `types.mbt` - Added SvgDocument type re-export
- `svg.mbt` - Reduced to only contain Image::render_image_to_svg method
- All test files - Updated from `@vg.new_svg()` to `@svg.new_svg()`
- `README.mbt.md` - Updated all examples to use `@svg` namespace
- `moon.pkg.json` - Added svg package import

## Files Structure

```
vg/
├── color/
│   ├── types.mbt        # Color struct definition
│   ├── color.mbt        # Color utilities and functions
│   ├── color_test.mbt   # Color-specific tests
│   └── moon.pkg.json    # Color package configuration
├── geometry/            # Geometry package (previously refactored)
│   ├── types.mbt
│   ├── point.mbt
│   ├── path.mbt
│   ├── transform.mbt
│   └── moon.pkg.json
├── svg/
│   ├── types.mbt        # SvgDocument struct definition
│   ├── svg.mbt          # SVG rendering methods and utilities
│   └── moon.pkg.json    # SVG package configuration (depends on geometry and color)
├── types.mbt            # Type re-exports (Color, Point, Path, SvgDocument, etc.)
├── svg.mbt              # Image::render_image_to_svg only
└── moon.pkg.json        # Main package configuration (imports color, geometry, svg packages)
```

## Notes

- The svg package depends on both geometry and color packages
- Type aliases ensure SvgDocument type is available through `@vg.SvgDocument`
- All SVG functions must be accessed via `@svg` namespace (no re-export wrappers)
- `Image::render_image_to_svg` remains in the main `vg` package as specified in the requirements
- This refactoring changes the public API - SVG functions moved from `@vg` to `@svg` namespace
- The pattern matches geometry and color packages: types re-exported, functions in dedicated namespace

## Future Work

With geometry, color, and svg now separated into independent packages, the library has a clean modular architecture. Future work could include:
- Additional rendering backends (Canvas, PDF) as separate packages
- Image composition and manipulation utilities as a separate package
- More advanced SVG features (filters, animations, etc.)
