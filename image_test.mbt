// Tests for image combinators (new declarative AST; `eval` is the denotation).

///|
test "constant image" {
  let red_img = @vg.Image::const_color(@color.red())
  if red_img.eval(Point(0.0, 0.0)) != @color.red() ||
    red_img.eval(Point(100.0, -50.0)) != @color.red() {
    fail("Constant image should return same color everywhere")
  }
}

///|
test "empty image" {
  let empty_img = @vg.Image::empty()
  if empty_img.eval(Point(5.0, 10.0)) != @color.transparent() {
    fail("Empty image should be transparent everywhere")
  }
}

///|
test "circle image" {
  let circle_img = @vg.Image::circle(@color.blue(), 5.0)
  if circle_img.eval(Point(3.0, 0.0)) != @color.blue() {
    fail("Point inside circle should be blue")
  }
  if circle_img.eval(Point(10.0, 0.0)) != @color.transparent() {
    fail("Point outside circle should be transparent")
  }
}

///|
test "rectangle image" {
  let rect_img = @vg.Image::rectangle(@color.green(), 10.0, 6.0)
  if rect_img.eval(Point(2.0, 1.0)) != @color.green() {
    fail("Point inside rectangle should be green")
  }
  if rect_img.eval(Point(8.0, 1.0)) != @color.transparent() {
    fail("Point outside rectangle should be transparent")
  }
}

///|
test "image translation" {
  let translated = @vg.Image::circle(@color.red(), 3.0).translate_img(5.0, 0.0)
  if translated.eval(Point(0.0, 0.0)) != @color.transparent() {
    fail("Original center should be transparent after translation")
  }
  if translated.eval(Point(5.0, 0.0)) != @color.red() {
    fail("New center should be red after translation")
  }
}

///|
test "image scaling" {
  let scaled = @vg.Image::circle(@color.blue(), 2.0).scale(2.0, 2.0)
  // (3,0) is outside the original r=2 circle but inside the scaled r=4 one
  if scaled.eval(Point(3.0, 0.0)) != @color.blue() {
    fail("Scaled image should be larger")
  }
}

///|
test "image composition is source-over" {
  let red_circle = @vg.Image::circle(@color.red(), 3.0)
  let blue_circle = @vg.Image::circle(@color.blue(), 3.0).translate_img(
    2.0, 0.0,
  )
  // base.compose(overlay) paints the overlay (blue) on top via source-over
  let composed = red_circle.compose(blue_circle)
  if composed.eval(Point(-2.0, 0.0)) != @color.red() {
    fail("Red-only area should be red")
  }
  if composed.eval(Point(4.0, 0.0)) != @color.blue() {
    fail("Blue-only area should be blue")
  }
  if composed.eval(Point(1.0, 0.0)) != @color.blue() {
    fail("Overlap should show the top (blue) layer")
  }
}

///|
test "path cut" {
  let red = @color.red()
  let img = @vg.cut(
    @vg.Path::circle(Point(0.0, 0.0), 3.0),
    @vg.Image::const_color(red),
  )
  if img.eval(Point(0.0, 0.0)) != red {
    fail("Inside the cut path should show the colour field")
  }
  if img.eval(Point(8.0, 0.0)).a != 0.0 {
    fail("Outside the cut path should be transparent")
  }
}

///|
test "linear gradient" {
  let gradient = @vg.Image::linear_gradient(
    @color.red(),
    @color.blue(),
    Point(-5.0, 0.0),
    Point(5.0, 0.0),
  )
  if gradient.eval(Point(-5.0, 0.0)) != @color.red() {
    fail("Gradient start should be red")
  }
  if gradient.eval(Point(5.0, 0.0)) != @color.blue() {
    fail("Gradient end should be blue")
  }
  let center = gradient.eval(Point(0.0, 0.0))
  if center == @color.red() || center == @color.blue() {
    fail("Gradient center should be interpolated")
  }
}

///|
test "radial gradient" {
  let gradient = @vg.Image::radial_gradient(
    @color.white(),
    @color.black(),
    Point(0.0, 0.0),
    5.0,
  )
  if gradient.eval(Point(0.0, 0.0)) != @color.white() {
    fail("Radial gradient center should be white")
  }
  if gradient.eval(Point(5.0, 0.0)) != @color.black() {
    fail("Radial gradient edge should be black")
  }
  let middle = gradient.eval(Point(2.5, 0.0))
  if middle == @color.white() || middle == @color.black() {
    fail("Radial gradient middle should be interpolated")
  }
}

///|
test "ellipse image" {
  let ellipse_img = @vg.Image::ellipse(@color.green(), 4.0, 2.0)
  if ellipse_img.eval(Point(2.0, 1.0)) != @color.green() {
    fail("Point inside ellipse should be green")
  }
  if ellipse_img.eval(Point(5.0, 0.0)) != @color.transparent() {
    fail("Point outside ellipse should be transparent")
  }
}

///|
test "polygon image" {
  let triangle_points : Array[@vg.Point] = [
    Point(0.0, -2.0),
    Point(-2.0, 2.0),
    Point(2.0, 2.0),
  ]
  let triangle_img = @vg.Image::polygon(@color.blue(), triangle_points)
  if triangle_img.eval(Point(0.0, 0.0)) != @color.blue() {
    fail("Point inside triangle should be blue")
  }
  if triangle_img.eval(Point(0.0, -3.0)) != @color.transparent() {
    fail("Point outside triangle should be transparent")
  }
}

///|
test "opacity application" {
  let semi = @vg.Image::circle(@color.red(), 5.0).with_opacity(0.5)
  let color = semi.eval(Point(0.0, 0.0))
  if color.r != 1.0 || color.g != 0.0 || color.b != 0.0 {
    fail("Color components should remain unchanged")
  }
  if color.a != 0.5 {
    fail("Alpha should be reduced to 0.5")
  }
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
