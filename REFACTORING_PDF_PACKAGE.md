# PDF Package Refactoring

**Date:** November 22, 2025

## Overview

This refactoring splits out the `PdfDocument` type and all PDF rendering functionality into a separate `pdf` package to improve modularity and reduce coupling in the VG vector graphics library. This follows the same pattern previously used for the geometry and color package refactorings.

## Changes Made

### New Package Structure

Created `pdf/` package with:
- `pdf/pdf.mbt` - PdfDocument struct definition and all PDF rendering methods
- `pdf/moon.pkg.json` - Package configuration

### Type Migration

**Moved from `vg` package to `pdf` package:**
- `PdfDocument` struct - PDF document representation with width, height, objects array, and object count

**PDF rendering methods moved:**
- Document creation: `PdfDocument::new`
- Shape rendering: `render_circle`, `render_rectangle`, `render_line`
- Path rendering: `render_path`
- Text rendering: `render_text`
- Output generation: `to_string`
- Internal methods: `add_object`, `color_to_pdf`, `point_to_pdf`, `path_to_pdf_commands`

### Dependency Management

**PDF package dependencies:**
- Updated `pdf/moon.pkg.json` to import `bobzhang/vg/geometry` and `bobzhang/vg/color`
- All methods updated to use `@geometry.Point`, `@geometry.Path` types
- All methods updated to use `@color.Color` type

**Main package (`vg`) changes:**
- Updated `moon.pkg.json` to import `bobzhang/vg/pdf`
- Modified `types.mbt` to re-export PdfDocument type using type alias:
  ```moonbit
  pub type PdfDocument = @pdf.PdfDocument
  ```
- Removed original `pdf.mbt` file from root directory

### Backward Compatibility

For most consumers, the change requires updating to use the `@pdf` namespace:
- Type references still work through type alias: `PdfDocument` or `@vg.PdfDocument`
- All PdfDocument methods work the same way (e.g., `doc.render_circle()`)
- Constructor now accessed via `@pdf.PdfDocument::new()` instead of `@vg.PdfDocument::new()`

### Test Results

- All 175 tests pass
- No errors, only existing warnings about using package-qualified names in geometry package tests
- Build verification: `moon check` and `moon test` both succeed

## Migration Guide for External Users

If you're using the VG library and upgrading:

### Using PdfDocument

PdfDocument must now be accessed through the `@pdf` namespace:

```moonbit
// Creating PDF documents
let doc = @pdf.PdfDocument::new(210.0, 297.0) // A4 size

// Using fluent API (same as before)
let result = doc
  .render_rectangle(0.0, 0.0, 210.0, 297.0, @color.white())
  .render_circle(@vg.Point::new(105.0, 150.0), 30.0, @color.red())
  .render_text("Hello PDF", @vg.Point::new(105.0, 50.0), 16.0, @color.black())
  .to_string()
```

### Using the PdfDocument Type

The PdfDocument type is still available through the main package via type alias:

```moonbit
// Type references work as before
let doc : PdfDocument = @pdf.PdfDocument::new(200.0, 150.0)
let doc2 : @vg.PdfDocument = @pdf.PdfDocument::new(300.0, 200.0)
```

### Migration from Previous Version

If you have existing code that used `@vg.PdfDocument::new()`, update to use `@pdf`:

```moonbit
// Before:
let doc = @vg.PdfDocument::new(300.0, 200.0)
  .render_circle(center, radius, color)

// After:
let doc = @pdf.PdfDocument::new(300.0, 200.0)
  .render_circle(center, radius, color)
```

## Benefits

1. **Modularity** - PDF rendering can be used independently of the full VG library
2. **Clarity** - Clearer separation between PDF rendering and other graphics functionality
3. **Testability** - PDF package can have its own focused test suite
4. **Reusability** - Other packages can depend on just the pdf package if needed
5. **Consistency** - Follows the same pattern as the geometry and color package refactorings

## Files Modified

- `pdf/` - New package directory with PDF rendering implementation
- `types.mbt` - Added PdfDocument type re-export
- `pdf.mbt` - **DELETED** (moved to pdf package)
- `oo_api_test.mbt` - Updated to use `@pdf.PdfDocument::new()`
- `renderer_test.mbt` - Updated to use `@pdf.PdfDocument::new()`
- `README.mbt.md` - Updated examples to use `@pdf.PdfDocument::new()`
- `moon.pkg.json` - Added pdf package import

## Files Structure

```
vg/
├── pdf/
│   ├── pdf.mbt          # PdfDocument struct and rendering methods
│   └── moon.pkg.json    # PDF package configuration (imports geometry, color)
├── color/               # Color package (previously refactored)
├── geometry/            # Geometry package (previously refactored)
├── types.mbt            # Type re-exports (PdfDocument type alias)
└── moon.pkg.json        # Main package configuration (imports pdf package)
```

## Notes

- The pdf package depends on geometry and color packages
- Type aliases ensure PdfDocument type is available through `@vg.PdfDocument`
- PdfDocument constructor must be accessed via `@pdf.PdfDocument::new()`
- This matches the geometry and color package patterns exactly
- The refactoring changes the public API - PdfDocument creation moved from `@vg` to `@pdf` namespace

## Future Work

With geometry, color, and pdf now separated into independent packages, potential future modularizations could include:
- SVG rendering as a separate package
- Canvas rendering as a separate package
- Image operations package
- Transform operations (if not already in geometry)
