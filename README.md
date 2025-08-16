# Vg — Declarative 2D vector graphics for MoonBit

Vg is a declarative 2D vector graphics library ported from OCaml to MoonBit. Images are values that denote functions mapping points of the cartesian plane to colors and combinators are provided to define and compose them.

This is a MoonBit port of the original [Vg library](https://github.com/dbuenzli/vg) by Daniel Bünzli.

## Features

- ✅ **Core Types**: Point, Color, Transform, Path, Image
- ✅ **Color Utilities**: Predefined colors, blending, RGBA, HSV support
- ✅ **Point Operations**: Distance, dot product, normalization, rotation
- ✅ **Transformations**: Translation, scaling, rotation, skewing, composition
- ✅ **Basic Shapes**: Circle, rectangle, line, ellipse, polygon
- ✅ **Image Combinators**: Shapes, gradients, composition, cutting, opacity
- ✅ **Path Construction**: Move, line, curve, close operations
- ✅ **Advanced Paths**: Circle, ellipse, rectangle path generation
- ✅ **Gradients**: Linear and radial gradients with color interpolation
- ✅ **SVG Rendering**: Complete SVG backend with all shape support
- ✅ **Comprehensive Tests**: Extensive test suite for all components
- ✅ **WebAssembly Target**: Compiles to WebAssembly via MoonBit

## Installation

```bash
# Clone the repository
git clone https://github.com/moonbit-community/vg.git
cd vg

# Build the library
moon check

# Run the demo
moon run src/main
```

## Usage

```moonbit
// Create basic shapes
let red_circle = circle(red(), 50.0)
let blue_ellipse = ellipse(blue(), 60.0, 40.0)
let triangle = polygon(green(), [point(0.0, -30.0), point(-30.0, 30.0), point(30.0, 30.0)])

// Apply transformations and effects
let semi_transparent = with_opacity(red_circle, 0.7)
let translated_ellipse = translate_img(50.0, 0.0, blue_ellipse)

// Compose images
let composed = compose_imgs(semi_transparent, translated_ellipse)

// Create SVG output with advanced shapes
let svg_doc = new_svg(200.0, 200.0)
  |> render_circle(point(100.0, 100.0), 50.0, red())
  |> render_ellipse(point(150.0, 100.0), 30.0, 20.0, blue())
  |> render_polygon([point(50.0, 50.0), point(80.0, 50.0), point(65.0, 80.0)], green())

let svg_string = to_svg_string(svg_doc)
```

## Architecture

The library is organized into several modules:

- **`types.mbt`**: Core type definitions (Point, Color, Transform, etc.)
- **`color.mbt`**: Color utilities and predefined colors
- **`point.mbt`**: Point operations and vector math
- **`transform.mbt`**: 2D transformation matrices
- **`image.mbt`**: Image combinators and shape primitives
- **`path.mbt`**: Path construction and manipulation
- **`svg.mbt`**: SVG rendering backend

## Examples

### Basic Shapes
```moonbit
// Create a red circle
let circle_img = circle(red(), 25.0)

// Create a blue rectangle
let rect_img = rectangle(blue(), 50.0, 30.0)

// Create an ellipse
let ellipse_img = ellipse(green(), 40.0, 20.0)

// Create a polygon (triangle)
let triangle = polygon(yellow(), [
  point(0.0, -20.0), 
  point(-20.0, 20.0), 
  point(20.0, 20.0)
])
```

### Transformations
```moonbit
// Translate an image
let moved = translate_img(10.0, 20.0, circle_img)

// Scale an image
let scaled = scale_image(2.0, 1.5, rect_img)

// Rotate an image
let rotated = rotate_image(3.14159 / 4.0, circle_img) // 45 degrees
```

### Colors and Effects
```moonbit
// HSV color creation
let bright_orange = hsv(30.0, 1.0, 1.0)  // Hue, Saturation, Value

// Color interpolation
let purple_to_cyan = lerp_color(purple(), cyan(), 0.5)

// Apply opacity
let semi_transparent = with_opacity(circle(red(), 30.0), 0.6)

// Linear gradient
let gradient = linear_gradient(
  red(), blue(), 
  point(-50.0, 0.0), point(50.0, 0.0)
)

// Radial gradient
let radial = radial_gradient(
  white(), black(),
  point(0.0, 0.0), 50.0
)
```

### Paths
```moonbit
// Create a custom path
let path = empty_path()
  |> move_to(point(10.0, 10.0))
  |> line_to(point(90.0, 10.0))
  |> curve_to(point(110.0, 10.0), point(110.0, 30.0), point(90.0, 30.0))
  |> close_path()

// Render path to SVG
let svg = new_svg(100.0, 100.0)
  |> render_path(path, green())
```

## Status

✅ **Complete and Working**: The library successfully compiles and runs, demonstrating all core functionality of the original Vg library adapted for MoonBit's syntax and type system.

## License

ISC License (same as original Vg library)

## Credits

Original Vg library by Daniel Bünzli: https://github.com/dbuenzli/vg
MoonBit port with extensive tests and examples.