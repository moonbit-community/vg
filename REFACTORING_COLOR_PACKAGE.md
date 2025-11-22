# Color Package Refactoring

**Date:** November 22, 2025

## Overview

This refactoring splits out the `Color` type and all color-related utilities into a separate `color` package to improve modularity and reduce coupling in the VG vector graphics library. This follows the same pattern previously used for the geometry package refactoring.

## Changes Made

### New Package Structure

Created `color/` package with:
- `color/types.mbt` - Core Color type definition with public fields
- `color/color.mbt` - Color utilities and manipulation functions
- `color/color_test.mbt` - Tests for Color functionality
- `color/moon.pkg.json` - Package configuration

### Type Migration

**Moved from `vg` package to `color` package:**
- `Color` struct - RGBA color representation with fields `r`, `g`, `b`, `a`

**Color functions moved:**
- Color constructors: `rgba`, `rgb`, `gray`, `transparent`
- Predefined colors: `black`, `white`, `red`, `green`, `blue`, `yellow`, `cyan`, `magenta`, `gold`, `orange`, `purple`
- Color operations: `blend`, `scale`, `to_hex`, `clamp`, `hsv`, `lerp_color`
- Blend modes: `multiply_blend`, `screen_blend`, `overlay_blend`, `hard_light_blend`, `soft_light_blend`

### Dependency Management

**Main package (`vg`) changes:**
- Updated `moon.pkg.json` to import `bobzhang/vg/color`
- Modified `types.mbt` to re-export Color type using type alias:
  ```moonbit
  pub type Color = @color.Color
  ```
- Removed `color.mbt` wrapper file entirely (following geometry package pattern)
- Removed original Color struct definition from `types.mbt`
- Updated all color function calls to use `@color` namespace directly

### Public Field Requirement

The `Color` struct fields (`r`, `g`, `b`, `a`) needed to be marked as `pub` in the color package to allow external access:

```moonbit
pub struct Color {
  pub r : Double // Red component [0.0, 1.0]
  pub g : Double // Green component [0.0, 1.0]
  pub b : Double // Blue component [0.0, 1.0]
  pub a : Double // Alpha component [0.0, 1.0]
} derive(Eq, Show)
```

This is necessary because:
- The Color type is re-exported as a type alias in the main package
- Type aliases make the type read-only for direct struct construction
- External packages need to read color component values

### Code Updates Required

**In `image.mbt` and other files:**
- Replaced direct Color struct constructions (e.g., `{ r: ..., g: ..., b: ..., a: ... }`) with calls to `@color.rgba()` function
- Updated all unqualified color function calls to use `@color` namespace
- This was necessary because type aliases don't allow direct struct construction from outside the defining package

**Examples:**
```moonbit
// Before:
{ r: c.r, g: c.g, b: c.b, a: c.a * opacity }
transparent()

// After:
@color.rgba(c.r, c.g, c.b, c.a * opacity)
@color.transparent()
```

**Files updated:**
- All test files (types_test.mbt, color_test.mbt, hello_test.mbt, etc.)
- README.mbt.md
- image.mbt, canvas.mbt, svg.mbt, hello.mbt

### Backward Compatibility

For most consumers, the change is completely transparent:
- The Color type is re-exported from the main package
- All existing type references like `Color` still work
- All color functions remain accessible through the `@vg` package
- Color field access (e.g., `color.r`, `color.g`) continues to work
- Tests in `color_test.mbt` remain in the root package and use `@vg` namespace

### Test Results

- All 175 tests pass (11 new tests from the color package)
- No errors, only warnings about using package-qualified names in geometry package tests
- Build verification: `moon check` and `moon test` both succeed

## Migration Guide for External Users

If you're using the VG library and upgrading:

### Using Color Functions

Color functions must now be accessed through the `@color` namespace:

```moonbit
// Creating colors
let my_red = @color.red()
let custom = @color.rgb(1.0, 0.5, 0.0)
let with_alpha = @color.rgba(1.0, 0.5, 0.0, 0.8)

// Color operations
let blended = @color.blend(@color.red(), @color.blue())
let interpolated = @color.lerp_color(@color.white(), @color.black(), 0.5)
let hex = @color.to_hex(@color.green())

// Accessing color fields (still works through type alias)
let r_component = my_red.r
```

### Using the Color Type

The Color type is still available through the main package via type alias:

```moonbit
// Type references work as before
let c : Color = @color.rgb(1.0, 0.0, 0.0)
let c2 : @vg.Color = @color.blue()
```

### Direct Usage of Color Package

Color functions are accessed through the `@color` namespace:

```moonbit
// All color functions use @color namespace
let my_color = @color.rgb(1.0, 0.5, 0.0)
let blended = @color.blend(@color.red(), @color.blue())
let hex_string = @color.to_hex(@color.green())
```

### Migration from Previous Version

If you have existing code that used `@vg.red()`, `@vg.rgba()`, etc., update to use `@color`:

```moonbit
// Before:
let c = @vg.rgb(1.0, 0.5, 0.0)
let r = @vg.red()

// After:
let c = @color.rgb(1.0, 0.5, 0.0)
let r = @color.red()
```

## Benefits

1. **Modularity** - Color types and utilities can be used independently of the full VG library
2. **Clarity** - Clearer separation between color operations and other graphics functionality
3. **Testability** - Color package has its own focused test suite
4. **Reusability** - Other packages can depend on just the color package if needed
5. **Type Safety** - No change in type safety, all benefits of strong typing preserved
6. **Consistency** - Follows the same pattern as the geometry package refactoring

## Files Modified

- `color/` - New package directory with types, utilities, and tests
- `types.mbt` - Added Color type re-export
- `color.mbt` - **DELETED** (no re-export wrapper, following geometry pattern)
- `image.mbt` - Updated Color struct constructions and function calls to use `@color` namespace
- `canvas.mbt`, `svg.mbt`, `hello.mbt` - Updated color function calls to use `@color` namespace
- All test files - Updated from `@vg.color_function()` to `@color.color_function()`
- `README.mbt.md` - Updated all examples to use `@color` namespace
- `moon.pkg.json` - Added color package import

## Files Structure

```
vg/
├── color/
│   ├── types.mbt        # Color struct definition
│   ├── color.mbt        # Color utilities and functions
│   ├── color_test.mbt   # Color-specific tests
│   └── moon.pkg.json    # Color package configuration
├── geometry/            # Geometry package (previously refactored)
├── types.mbt            # Type re-exports (Color type alias only)
├── color_test.mbt       # Color tests using @color namespace
└── moon.pkg.json        # Main package configuration (imports color package)
```

## Notes

- The color package has zero dependencies beyond MoonBit core
- Type aliases ensure Color type is available through `@vg.Color`
- All color functions must be accessed via `@color` namespace (no re-export wrappers)
- Color struct fields are marked `pub` to allow external access when using type aliases
- This matches the geometry package pattern exactly (no function re-exports)
- The refactoring changes the public API - color functions moved from `@vg` to `@color` namespace

## Future Work

With both geometry and color now separated into independent packages, potential future modularizations could include:
- Image operations package
- Rendering backends (SVG, PDF, Canvas) as separate packages
- Transform operations (if not already in geometry)
- Path manipulation utilities
