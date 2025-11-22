# Canvas Package Refactoring

**Date:** November 22, 2025

## Overview

This refactoring splits out the `CanvasDocument` type and all Canvas rendering utilities into a separate `canvas` package to improve modularity and reduce coupling in the VG vector graphics library. This follows the same pattern previously used for the geometry and color package refactorings.

## Changes Made

### New Package Structure

Created `canvas/` package with:
- `canvas/types.mbt` - Core CanvasDocument type definition with public fields
- `canvas/canvas.mbt` - Canvas rendering functions and document methods
- `canvas/canvas_test.mbt` - Tests for Canvas functionality
- `canvas/moon.pkg.json` - Package configuration

### Type Migration

**Moved from `vg` package to `canvas` package:**
- `CanvasDocument` struct - Canvas document representation with fields `width`, `height`, `commands`

**Canvas functions moved:**
- Constructor: `new_canvas`
- Document methods: `CanvasDocument::add_command`, `CanvasDocument::render_circle`, `CanvasDocument::render_rectangle`, `CanvasDocument::render_line`, `CanvasDocument::render_text`, `CanvasDocument::render_path`
- Output methods: `CanvasDocument::to_js`, `CanvasDocument::to_html`
- Helper functions: `color_to_canvas`, `path_to_canvas_commands` (internal)

### Dependency Management

**Main package (`vg`) changes:**
- Updated `moon.pkg.json` to import `bobzhang/vg/canvas`
- Modified `types.mbt` to re-export CanvasDocument type using type alias:
  ```moonbit
  pub type CanvasDocument = @canvas.CanvasDocument
  ```
- Modified `canvas.mbt` to only contain a wrapper function for `new_canvas`:
  ```moonbit
  pub fn new_canvas(width : Double, height : Double) -> CanvasDocument {
    @canvas.new_canvas(width, height)
  }
  ```

**Canvas package dependencies:**
- Depends on `bobzhang/vg/geometry` for Point and Path types
- Depends on `bobzhang/vg/color` for Color type

### Public Field Requirement

The `CanvasDocument` struct fields (`width`, `height`, `commands`) are marked as `pub` in the canvas package to allow external access:

```moonbit
pub struct CanvasDocument {
  pub width : Double
  pub height : Double
  pub commands : Array[String]
} derive(Show)
```

This is necessary because:
- The CanvasDocument type is re-exported as a type alias in the main package
- External packages may need to inspect the document state
- Tests need access to verify the generated commands

### Code Updates Required

**In `canvas/canvas.mbt`:**
- All references to `Color` changed to `@color.Color`
- All references to `Point` changed to `@geometry.Point`
- All references to `Path` changed to `@geometry.Path`
- All color function calls updated to use `@color` namespace (e.g., `@color.to_hex()`)

**Files updated:**
- `canvas/types.mbt` - New file with CanvasDocument struct
- `canvas/canvas.mbt` - New file with all Canvas rendering functions
- `canvas/canvas_test.mbt` - New file with 11 Canvas-specific tests
- `canvas/moon.pkg.json` - New package configuration
- `moon.pkg.json` - Added canvas package import
- `types.mbt` - Added CanvasDocument type re-export
- `canvas.mbt` - Simplified to wrapper function only

### Backward Compatibility

For most consumers, the change is completely transparent:
- The CanvasDocument type is re-exported from the main package
- All existing type references like `CanvasDocument` still work
- The `new_canvas` function remains accessible through the `@vg` package
- All CanvasDocument methods continue to work via the type alias
- Tests in the main package (e.g., `oo_api_test.mbt`, `renderer_test.mbt`) remain unchanged

### Test Results

- All 186 tests pass (11 new tests from the canvas package)
- No errors, only existing warnings from geometry package tests
- Build verification: `moon check` and `moon test` both succeed

## Migration Guide for External Users

If you're using the VG library and upgrading:

### No Changes Needed For:

The refactoring is fully backward compatible. All existing code continues to work without modification:

```moonbit
// Creating canvas documents - works as before
let doc = @vg.new_canvas(300.0, 200.0)

// Using canvas methods - works as before
let canvas = @vg.new_canvas(200.0, 100.0)
  .render_circle(@vg.Point::new(100.0, 50.0), 25.0, @color.red())
  .render_text("Hello", @vg.Point::new(100.0, 80.0), 12.0, @color.black())

// Converting to output formats - works as before
let js = canvas.to_js()
let html = canvas.to_html("My Canvas")

// Type references - work as before
let c : CanvasDocument = @vg.new_canvas(100.0, 100.0)
let c2 : @vg.CanvasDocument = @vg.new_canvas(100.0, 100.0)
```

### Direct Usage of Canvas Package

If you want to use the canvas package directly (optional):

```moonbit
// Import the canvas package in moon.pkg.json:
{
  "import": ["bobzhang/vg/canvas"]
}

// Then use directly:
let doc = @canvas.new_canvas(300.0, 200.0)
  .render_circle(@geometry.Point::new(100.0, 100.0), 50.0, @color.red())
```

## Benefits

1. **Modularity** - Canvas rendering can be used independently or extended separately
2. **Clarity** - Clearer separation between Canvas rendering and other graphics backends
3. **Testability** - Canvas package has its own focused test suite
4. **Reusability** - Other packages can depend on just the canvas package if needed
5. **Type Safety** - No change in type safety, all benefits of strong typing preserved
6. **Consistency** - Follows the same pattern as the geometry and color package refactorings

## Files Modified

- `canvas/` - New package directory with types, utilities, and tests
- `types.mbt` - Added CanvasDocument type re-export
- `canvas.mbt` - Simplified to wrapper function only
- `moon.pkg.json` - Added canvas package import

## Files Structure

```
vg/
├── canvas/
│   ├── types.mbt          # CanvasDocument struct definition
│   ├── canvas.mbt         # Canvas rendering functions
│   ├── canvas_test.mbt    # Canvas-specific tests
│   └── moon.pkg.json      # Canvas package configuration
├── color/                 # Color package (previously refactored)
├── geometry/              # Geometry package (previously refactored)
├── canvas.mbt             # Wrapper function for new_canvas
├── types.mbt              # Type re-exports (CanvasDocument type alias)
└── moon.pkg.json          # Main package configuration (imports canvas package)
```

## Notes

- The canvas package depends on both geometry and color packages
- Type aliases ensure CanvasDocument type is available through `@vg.CanvasDocument`
- All CanvasDocument methods work through the type alias
- CanvasDocument struct fields are marked `pub` to allow external access when using type aliases
- This matches the geometry and color package patterns exactly
- The refactoring is fully backward compatible - no API changes required for consumers

## Future Work

With geometry, color, and canvas now separated into independent packages, potential future modularizations could include:
- SVG renderer as a separate package
- PDF renderer as a separate package
- Image operations package
- Additional rendering backends (e.g., PostScript, WebGL)
