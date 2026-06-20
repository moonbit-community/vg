// Tests for image combinators (new declarative AST; `eval` is the denotation).
//
// Behavioural tests `debug_inspect` the colour `eval` produces at chosen points
// (run `moon test --update` to refresh the pinned values); a few keep an
// explicit assertion where the test is a relation rather than a fixed value.

///|
test "constant image" {
  let red_img = @vg.Image::const_color(@color.red())
  debug_inspect(
    (red_img.eval(Point(0.0, 0.0)), red_img.eval(Point(100.0, -50.0))),
    content=(
      #|({ r: 1, g: 0, b: 0, a: 1 }, { r: 1, g: 0, b: 0, a: 1 })
    ),
  )
}

///|
test "empty image" {
  let empty_img = @vg.Image::empty()
  debug_inspect(
    empty_img.eval(Point(5.0, 10.0)),
    content=(
      #|{ r: 0, g: 0, b: 0, a: 0 }
    ),
  )
}

///|
test "circle image" {
  let circle_img = @vg.Image::circle(@color.blue(), 5.0)
  // inside, then outside
  debug_inspect(
    (circle_img.eval(Point(3.0, 0.0)), circle_img.eval(Point(10.0, 0.0))),
    content=(
      #|({ r: 0, g: 0, b: 1, a: 1 }, { r: 0, g: 0, b: 0, a: 0 })


    ),
  )
}

///|
test "rectangle image" {
  let rect_img = @vg.Image::rectangle(@color.green(), 10.0, 6.0)
  // inside, then outside
  debug_inspect(
    (rect_img.eval(Point(2.0, 1.0)), rect_img.eval(Point(8.0, 1.0))),
    content=(
      #|({ r: 0, g: 1, b: 0, a: 1 }, { r: 0, g: 0, b: 0, a: 0 })


    ),
  )
}

///|
test "image translation" {
  let translated = @vg.Image::circle(@color.red(), 3.0).translate_img(5.0, 0.0)
  // original centre (now transparent), new centre (red)
  debug_inspect(
    (translated.eval(Point(0.0, 0.0)), translated.eval(Point(5.0, 0.0))),
    content=(
      #|({ r: 0, g: 0, b: 0, a: 0 }, { r: 1, g: 0, b: 0, a: 1 })


    ),
  )
}

///|
test "image scaling" {
  // (3,0) is outside the original r=2 circle but inside the scaled r=4 one
  let scaled = @vg.Image::circle(@color.blue(), 2.0).scale(2.0, 2.0)
  debug_inspect(
    scaled.eval(Point(3.0, 0.0)),
    content=(
      #|{ r: 0, g: 0, b: 1, a: 1 }
    ),
  )
}

///|
test "image composition is source-over" {
  let red_circle = @vg.Image::circle(@color.red(), 3.0)
  let blue_circle = @vg.Image::circle(@color.blue(), 3.0).translate_img(
    2.0, 0.0,
  )
  // base.compose(overlay) paints the overlay (blue) on top
  let composed = red_circle.compose(blue_circle)
  // red-only area, blue-only area, overlap (top = blue)
  debug_inspect(
    (
      composed.eval(Point(-2.0, 0.0)),
      composed.eval(Point(4.0, 0.0)),
      composed.eval(Point(1.0, 0.0)),
    ),
    content=(
      #|(
      #|  { r: 1, g: 0, b: 0, a: 1 },
      #|  { r: 0, g: 0, b: 1, a: 1 },
      #|  { r: 0, g: 0, b: 1, a: 1 },
      #|)


    ),
  )
}

///|
test "path cut" {
  let img = @vg.cut(
    @vg.Path::circle(Point(0.0, 0.0), 3.0),
    @vg.Image::const_color(@color.red()),
  )
  // inside the cut path, then outside
  debug_inspect(
    (img.eval(Point(0.0, 0.0)), img.eval(Point(8.0, 0.0))),
    content=(
      #|({ r: 1, g: 0, b: 0, a: 1 }, { r: 0, g: 0, b: 0, a: 0 })


    ),
  )
}

///|
test "linear gradient" {
  let gradient = @vg.Image::linear_gradient(
    @color.red(),
    @color.blue(),
    Point(-5.0, 0.0),
    Point(5.0, 0.0),
  )
  // start (red), centre (mix), end (blue)
  debug_inspect(
    (
      gradient.eval(Point(-5.0, 0.0)),
      gradient.eval(Point(0.0, 0.0)),
      gradient.eval(Point(5.0, 0.0)),
    ),
    content=(
      #|(
      #|  { r: 1, g: 0, b: 0, a: 1 },
      #|  { r: 0.5, g: 0, b: 0.5, a: 1 },
      #|  { r: 0, g: 0, b: 1, a: 1 },
      #|)
    ),
  )
}

///|
test "radial gradient" {
  let gradient = @vg.Image::radial_gradient(
    @color.white(),
    @color.black(),
    Point(0.0, 0.0),
    5.0,
  )
  // centre (white), middle (grey), edge (black)
  debug_inspect(
    (
      gradient.eval(Point(0.0, 0.0)),
      gradient.eval(Point(2.5, 0.0)),
      gradient.eval(Point(5.0, 0.0)),
    ),
    content=(
      #|(
      #|  { r: 1, g: 1, b: 1, a: 1 },
      #|  { r: 0.5, g: 0.5, b: 0.5, a: 1 },
      #|  { r: 0, g: 0, b: 0, a: 1 },
      #|)
    ),
  )
}

///|
test "ellipse image" {
  let ellipse_img = @vg.Image::ellipse(@color.green(), 4.0, 2.0)
  // inside, then outside
  debug_inspect(
    (ellipse_img.eval(Point(2.0, 1.0)), ellipse_img.eval(Point(5.0, 0.0))),
    content=(
      #|({ r: 0, g: 1, b: 0, a: 1 }, { r: 0, g: 0, b: 0, a: 0 })


    ),
  )
}

///|
test "polygon image" {
  let triangle_points : Array[@vg.Point] = [
    Point(0.0, -2.0),
    Point(-2.0, 2.0),
    Point(2.0, 2.0),
  ]
  let triangle_img = @vg.Image::polygon(@color.blue(), triangle_points)
  // inside, then outside
  debug_inspect(
    (triangle_img.eval(Point(0.0, 0.0)), triangle_img.eval(Point(0.0, -3.0))),
    content=(
      #|({ r: 0, g: 0, b: 1, a: 1 }, { r: 0, g: 0, b: 0, a: 0 })


    ),
  )
}

///|
test "opacity application" {
  let semi = @vg.Image::circle(@color.red(), 5.0).with_opacity(0.5)
  debug_inspect(
    semi.eval(Point(0.0, 0.0)),
    content=(
      #|{ r: 1, g: 0, b: 0, a: 0.5 }
    ),
  )
}

///|
test "path boundary samples count as inside" {
  // (5,0) is exactly on the r=5 circle boundary -> filled, not transparent
  let c = @vg.Image::circle(@color.red(), 5.0)
  debug_inspect(c.eval(Point(5.0, 0.0)), content=(#|{ r: 1, g: 0, b: 0, a: 1 }
  ))
}

///|
test "plus blend respects top opacity" {
  // a fully-transparent top adds nothing under Plus -> the black bottom shows
  let faded = @vg.blend(
    @vg.Image::const_color(@color.red()),
    @vg.Image::const_color(@color.black()),
    op=Plus,
    alpha=0.0,
  )
  debug_inspect(faded.eval(Point(0.0, 0.0)), content=(#|{ r: 0, g: 0, b: 0, a: 1 }
  ))
}

///|
test "image rendering showcase" (it : @test.Test) {
  let background = @vg.Image::rectangle(@color.gray(0.95), 200.0, 150.0)
  let red_circle = @vg.Image::circle(@color.red(), 25.0)
  let blue_ellipse = @vg.Image::ellipse(@color.blue(), 30.0, 20.0)
  let green_rect = @vg.Image::rectangle(@color.green(), 40.0, 30.0)
  let composed = background
    .compose(red_circle.translate_img(50.0, 40.0))
    .compose(blue_ellipse.translate_img(100.0, 60.0))
    .compose(green_rect.translate_img(150.0, 50.0))
    .compose(
      @vg.Image::circle(@color.yellow(), 20.0)
      .with_opacity(0.7)
      .translate_img(75.0, 90.0),
    )
  let svg_string = composed.render_image_to_svg(200.0, 150.0, 40)
  it.write(svg_string)
  it.snapshot(filename="image_composition.svg")
}

///|
test "gradient images showcase" (it : @test.Test) {
  let horizontal_gradient = @vg.Image::linear_gradient(
    @color.red(),
    @color.blue(),
    Point(-50.0, 0.0),
    Point(50.0, 0.0),
  )
  let vertical_gradient = @vg.Image::linear_gradient(
    @color.green(),
    @color.yellow(),
    Point(0.0, -40.0),
    Point(0.0, 40.0),
  )
  let diagonal_gradient = @vg.Image::linear_gradient(
    @color.purple(),
    @color.cyan(),
    Point(-35.0, -35.0),
    Point(35.0, 35.0),
  )
  let radial1 = @vg.Image::radial_gradient(
    @color.white(),
    @color.red(),
    Point(0.0, 0.0),
    30.0,
  )
  let radial2 = @vg.Image::radial_gradient(
    @color.yellow(),
    @color.purple(),
    Point(0.0, 0.0),
    25.0,
  )
  let combined_output = "<!-- Horizontal Linear Gradient -->\n" +
    horizontal_gradient.render_image_to_svg(100.0, 80.0, 25) +
    "\n\n<!-- Vertical Linear Gradient -->\n" +
    vertical_gradient.render_image_to_svg(100.0, 80.0, 25) +
    "\n\n<!-- Diagonal Linear Gradient -->\n" +
    diagonal_gradient.render_image_to_svg(100.0, 80.0, 25) +
    "\n\n<!-- Radial Gradient 1 -->\n" +
    radial1.render_image_to_svg(100.0, 80.0, 25) +
    "\n\n<!-- Radial Gradient 2 -->\n" +
    radial2.render_image_to_svg(100.0, 80.0, 25)
  it.write(combined_output)
  it.snapshot(filename="gradient_gallery.txt")
}

///|
test "transform showcase" (it : @test.Test) {
  let base_circle = @vg.Image::circle(@color.red(), 20.0)
  let translated = base_circle.translate_img(60.0, 0.0)
  let scaled = base_circle.scale(1.5, 0.8)
  let rotated = base_circle.rotate(3.14159 / 4.0)
  let background = @vg.Image::rectangle(@color.gray(0.9), 200.0, 100.0)
  let showcase = background
    .compose(base_circle.translate_img(40.0, 50.0))
    .compose(translated.translate_img(100.0, 50.0))
    .compose(scaled.translate_img(40.0, 30.0))
    .compose(rotated.translate_img(140.0, 30.0))
  let svg_string = showcase.render_image_to_svg(200.0, 100.0, 30)
  it.write(svg_string)
  it.snapshot(filename="transform_showcase.svg")
}
