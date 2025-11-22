# Geometry Package Refactoring

**Date:** November 22, 2025

## Overview

This refactoring splits out core geometric types (`Point`, `Path`, `PathSegment`, `Box`) into a separate `geometry` package to improve modularity and reduce coupling in the VG vector graphics library.

## Changes Made

### New Package Structure

Created `geometry/` package with:
- `geometry/types.mbt` - Core type definitions (Point, Path, PathSegment, Box)
- `geometry/point.mbt` - Point utilities and methods
- `geometry/path.mbt` - Path construction and manipulation utilities
- `geometry/point_test.mbt` - Tests for Point functionality
- `geometry/path_test.mbt` - Tests for Path functionality (non-transform dependent)
- `geometry/moon.pkg.json` - Package configuration

### Type Migrations

**Moved from `vg` package to `geometry` package:**
- `Point` struct - 2D point representation
- `Box` struct - Bounding box
- `PathSegment` enum - Path segment types (MoveTo, LineTo, CurveTo, etc.)
- `Path` struct - Sequence of path segments

**Point methods moved:**
- `Point::new`, `Point::origin`
- `Point::add`, `Point::sub`, `Point::scale`
- `Point::distance`, `Point::dot`, `Point::length`
- `Point::normalize`, `Point::lerp`, `Point::rotate`

**Path methods moved:**
- `Path::empty`, `Path::move_to`, `Path::line_to`
- `Path::curve_to`, `Path::qcurve_to`, `Path::earc_to`
- `Path::close_path`, `Path::rect`, `Path::circle`, `Path::ellipse`
- `Path::bounds`, `Path::smooth_ccurve_to`, `Path::smooth_qcurve_to`

### Dependency Management

**Main package (`vg`) changes:**
- Updated `moon.pkg.json` to import `bobzhang/vg/geometry`
- Modified `types.mbt` to re-export geometry types using type aliases:
  ```moonbit
  pub type Point = @geometry.Point
  pub type Box = @geometry.Box
  pub type Path = @geometry.Path
  pub type PathSegment = @geometry.PathSegment
  ```
- Removed duplicate type definitions
- Deleted `point.mbt` (functionality now in geometry package)
- Simplified `path.mbt` to only contain `transform_path` wrapper

### Transform Dependency Resolution

The `Path::transform` method had a circular dependency issue (geometry types depending on Transform type). Solved by:

1. Made `Path::transform` generic in the geometry package:
   ```moonbit
   pub fn[T] Path::transform(
     self : Path,
     transform : T,
     apply_fn : (T, Point) -> Point
   ) -> Path
   ```

2. Created a wrapper in the main `vg` package:
   ```moonbit
   pub fn transform_path(path : Path, t : Transform) -> Path {
     path.transform(t, apply)
   }
   ```

3. Updated `transform.mbt` to use `Point::new` constructor instead of struct literals

4. Updated tests and documentation to use new API:
   ```moonbit
   // Old: path.transform(transform)
   // New: path.transform(transform, @vg.apply)
   ```

### Backward Compatibility

For most consumers, the change is transparent:
- Types are re-exported from the main package
- All existing type references like `Point`, `Path` still work
- Method calls work the same way (e.g., `Point::new()`, `path.bounds()`)
- Only `Path::transform()` requires the additional `apply` parameter

### Test Results

- All 155 tests pass
- No errors, only warnings about using package-qualified names in geometry package tests
- Build verification: `moon check` and `moon test` both succeed

## Migration Guide for External Users

If you're using the VG library and upgrading:

### No Changes Needed For:
- Creating points: `Point::new(x, y)`
- Creating paths: `Path::empty()`, `Path::rect()`, etc.
- Using path methods: `path.move_to()`, `path.bounds()`, etc.
- Using point methods: `p.add()`, `p.distance()`, etc.

### Changes Required For:
- Path transformations: Update from `path.transform(t)` to `path.transform(t, @vg.apply)`

### Example Update:
```moonbit
// Before:
let transformed = path.transform(my_transform)

// After:
let transformed = path.transform(my_transform, @vg.apply)
```

## Benefits

1. **Modularity** - Geometry types can be used independently of the full VG library
2. **Clarity** - Clearer separation between pure geometric operations and graphics rendering
3. **Testability** - Geometry package has its own focused test suite
4. **Reusability** - Other packages can depend on just the geometry package if needed
5. **Type Safety** - No change in type safety, all benefits of strong typing preserved

## Files Modified

- `geometry/` - New package directory
- `types.mbt` - Type re-exports added
- `transform.mbt` - Updated Point construction
- `path.mbt` - Simplified to wrapper function
- `path_test.mbt` - Updated transform test
- `README.mbt.md` - Updated examples
- `moon.pkg.json` - Added geometry import
- Deleted: `point.mbt`

## Notes

- The geometry package has zero dependencies beyond MoonBit core
- Transform-dependent operations remain in the main package to avoid circular dependencies
- Type aliases ensure seamless backward compatibility
- Future work could further modularize the library (color, image, renderers as separate packages)
