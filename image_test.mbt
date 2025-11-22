// Tests for image combinators

///|
test "constant image" {
  let red_img = @vg.Image::const_color(@color.red())
  let p1 = @vg.Point::new(0.0, 0.0)
  let p2 = @vg.Point::new(100.0, -50.0)
  let c1 = red_img(p1)
  let c2 = red_img(p2)
  if c1 != @color.red() || c2 != @color.red() {
    fail("Constant image should return same color everywhere")
  }
}

///|
test "empty image" {
  let empty_img = @vg.Image::empty()
  let p = @vg.Point::new(5.0, 10.0)
  let c = empty_img(p)
  if c != @color.transparent() {
    fail("Empty image should be transparent everywhere")
  }
}

///|
test "circle image" {
  let circle_img = @vg.Image::circle(@color.blue(), 5.0)
  let inside = @vg.Point::new(3.0, 0.0) // Distance 3 < radius 5
  let outside = @vg.Point::new(10.0, 0.0) // Distance 10 > radius 5
  let on_edge = @vg.Point::new(5.0, 0.0) // Distance 5 = radius 5
  let c_inside = circle_img(inside)
  let c_outside = circle_img(outside)
  let c_edge = circle_img(on_edge)
  if c_inside != @color.blue() {
    fail("Point inside circle should be blue")
  }
  if c_outside != @color.transparent() {
    fail("Point outside circle should be transparent")
  }
  if c_edge != @color.blue() {
    fail("Point on circle edge should be blue")
  }
}

///|
test "rectangle image" {
  let rect_img = @vg.Image::rectangle(@color.green(), 10.0, 6.0)
  let inside = @vg.Point::new(2.0, 1.0) // Within [-5,5] x [-3,3]
  let outside = @vg.Point::new(8.0, 1.0) // Outside width bounds
  let on_edge = @vg.Point::new(5.0, 0.0) // On width edge
  let c_inside = rect_img(inside)
  let c_outside = rect_img(outside)
  let c_edge = rect_img(on_edge)
  if c_inside != @color.green() {
    fail("Point inside rectangle should be green")
  }
  if c_outside != @color.transparent() {
    fail("Point outside rectangle should be transparent")
  }
  if c_edge != @color.green() {
    fail("Point on rectangle edge should be green")
  }
}

///|
test "image translation" {
  let circle_img = @vg.Image::circle(@color.red(), 3.0)
  let translated = circle_img.translate_img(5.0, 0.0)
  let original_center = @vg.Point::new(0.0, 0.0)
  let new_center = @vg.Point::new(5.0, 0.0)
  let c_original = translated(original_center)
  let c_new = translated(new_center)
  if c_original != @color.transparent() {
    fail("Original center should be transparent after translation")
  }
  if c_new != @color.red() {
    fail("New center should be red after translation")
  }
}

///|
test "image scaling" {
  let circle_img = @vg.Image::circle(@color.blue(), 2.0)
  let scaled = circle_img.scale(2.0, 2.0)
  let p = @vg.Point::new(3.0, 0.0) // Would be outside original circle but inside scaled
  let c = scaled(p)
  if c != @color.blue() {
    fail("Scaled image should be larger")
  }
}

///|
test "image composition" {
  let red_circle = @vg.Image::circle(@color.red(), 3.0)
  let blue_circle = @vg.Image::circle(@color.blue(), 3.0).translate_img(2.0, 0.0)
  let composed = red_circle.compose(blue_circle)
  let red_only = @vg.Point::new(-2.0, 0.0) // Only in red circle
  let blue_only = @vg.Point::new(4.0, 0.0) // Only in blue circle
  let overlap = @vg.Point::new(1.0, 0.0) // In both circles
  let c_red = composed(red_only)
  let c_blue = composed(blue_only)
  let c_overlap = composed(overlap)
  if c_red != @color.red() {
    fail("Red-only area should be red")
  }
  if c_blue != @color.blue() {
    fail("Blue-only area should be blue")
  }

  // Overlap should be a blend of red and blue
  if c_overlap == @color.red() ||
    c_overlap == @color.blue() ||
    c_overlap == @color.transparent() {
    fail("Overlap area should be blended")
  }
}

///|
test "image cutting" {
  let red_rect = @vg.Image::rectangle(@color.red(), 10.0, 10.0)
  let circle_mask = @vg.Image::circle(@color.white(), 3.0) // White mask
  let cut_img = red_rect.cut(circle_mask)
  let inside_mask = @vg.Point::new(2.0, 0.0) // Inside circle mask
  let outside_mask = @vg.Point::new(8.0, 0.0) // Outside circle mask
  let c_inside = cut_img(inside_mask)
  let c_outside = cut_img(outside_mask)
  if c_inside != @color.red() {
    fail("Area inside mask should show original color")
  }
  if c_outside.a != 0.0 {
    fail("Area outside mask should be transparent")
  }
}

///|
test "linear gradient" {
  let gradient = @vg.Image::linear_gradient(
    @color.red(),
    @color.blue(),
    @vg.Point::new(-5.0, 0.0),
    @vg.Point::new(5.0, 0.0),
  )
  let left = @vg.Point::new(-5.0, 0.0) // Should be red
  let right = @vg.Point::new(5.0, 0.0) // Should be blue
  let center = @vg.Point::new(0.0, 0.0) // Should be mix
  let c_left = gradient(left)
  let c_right = gradient(right)
  let c_center = gradient(center)
  if c_left != @color.red() {
    fail("Gradient start should be red")
  }
  if c_right != @color.blue() {
    fail("Gradient end should be blue")
  }

  // Center should be a mix (not pure red or blue)
  if c_center == @color.red() || c_center == @color.blue() {
    fail("Gradient center should be interpolated")
  }
}

///|
test "radial gradient" {
  let gradient = @vg.Image::radial_gradient(
    @color.white(),
    @color.black(),
    @vg.Point::new(0.0, 0.0),
    5.0,
  )
  let center = @vg.Point::new(0.0, 0.0) // Should be white
  let edge = @vg.Point::new(5.0, 0.0) // Should be black
  let middle = @vg.Point::new(2.5, 0.0) // Should be gray
  let c_center = gradient(center)
  let c_edge = gradient(edge)
  let c_middle = gradient(middle)
  if c_center != @color.white() {
    fail("Radial gradient center should be white")
  }
  if c_edge != @color.black() {
    fail("Radial gradient edge should be black")
  }

  // Middle should be between white and black
  if c_middle == @color.white() || c_middle == @color.black() {
    fail("Radial gradient middle should be interpolated")
  }
}

///|
test "ellipse image" {
  let ellipse_img = @vg.Image::ellipse(@color.green(), 4.0, 2.0)
  let inside = @vg.Point::new(2.0, 1.0) // Inside ellipse
  let outside = @vg.Point::new(5.0, 0.0) // Outside ellipse
  let edge = @vg.Point::new(4.0, 0.0) // On edge
  let c_inside = ellipse_img(inside)
  let c_outside = ellipse_img(outside)
  let c_edge = ellipse_img(edge)
  inspect(c_inside, content="{r: 0, g: 1, b: 0, a: 1}")
  inspect(c_outside, content="{r: 0, g: 0, b: 0, a: 0}")
  inspect(c_edge, content="{r: 0, g: 1, b: 0, a: 1}")
  if c_inside != @color.green() {
    fail("Point inside ellipse should be green")
  }
  if c_outside != @color.transparent() {
    fail("Point outside ellipse should be transparent")
  }
  if c_edge != @color.green() {
    fail("Point on ellipse edge should be green")
  }
}

///|
test "polygon image" {
  let triangle_points = [
    @vg.Point::new(0.0, -2.0),
    @vg.Point::new(-2.0, 2.0),
    @vg.Point::new(2.0, 2.0),
  ]
  let triangle_img = @vg.Image::polygon(@color.blue(), triangle_points)
  let inside = @vg.Point::new(0.0, 0.0) // Inside triangle
  let outside = @vg.Point::new(0.0, -3.0) // Outside triangle
  let c_inside = triangle_img(inside)
  let c_outside = triangle_img(outside)
  if c_inside != @color.blue() {
    fail("Point inside triangle should be blue")
  }
  if c_outside != @color.transparent() {
    fail("Point outside triangle should be transparent")
  }
}

///|
test "opacity application" {
  let red_img = @vg.Image::circle(@color.red(), 5.0)
  let semi_transparent = red_img.with_opacity(0.5)
  let center = @vg.Point::new(0.0, 0.0)
  let color = semi_transparent(center)
  if color.r != 1.0 || color.g != 0.0 || color.b != 0.0 {
    fail("Color components should remain unchanged")
  }
  if color.a != 0.5 {
    fail("Alpha should be reduced to 0.5")
  }
}

///|
test "image rendering showcase" (it : @test.Test) {
  // Create a complex composed image
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
  // Linear gradients
  let horizontal_gradient = @vg.Image::linear_gradient(
    @color.red(),
    @color.blue(),
    @vg.Point::new(-50.0, 0.0),
    @vg.Point::new(50.0, 0.0),
  )
  let vertical_gradient = @vg.Image::linear_gradient(
    @color.green(),
    @color.yellow(),
    @vg.Point::new(0.0, -40.0),
    @vg.Point::new(0.0, 40.0),
  )
  let diagonal_gradient = @vg.Image::linear_gradient(
    @color.purple(),
    @color.cyan(),
    @vg.Point::new(-35.0, -35.0),
    @vg.Point::new(35.0, 35.0),
  )

  // Radial gradients
  let radial1 = @vg.Image::radial_gradient(
    @color.white(),
    @color.red(),
    @vg.Point::new(0.0, 0.0),
    30.0,
  )
  let radial2 = @vg.Image::radial_gradient(
    @color.yellow(),
    @color.purple(),
    @vg.Point::new(0.0, 0.0),
    25.0,
  )

  // Render each gradient
  let h_svg = horizontal_gradient.render_image_to_svg(100.0, 80.0, 25)
  let v_svg = vertical_gradient.render_image_to_svg(100.0, 80.0, 25)
  let d_svg = diagonal_gradient.render_image_to_svg(100.0, 80.0, 25)
  let r1_svg = radial1.render_image_to_svg(100.0, 80.0, 25)
  let r2_svg = radial2.render_image_to_svg(100.0, 80.0, 25)
  let combined_output = "<!-- Horizontal Linear Gradient -->\n" +
    h_svg +
    "\n\n<!-- Vertical Linear Gradient -->\n" +
    v_svg +
    "\n\n<!-- Diagonal Linear Gradient -->\n" +
    d_svg +
    "\n\n<!-- Radial Gradient 1 -->\n" +
    r1_svg +
    "\n\n<!-- Radial Gradient 2 -->\n" +
    r2_svg
  it.write(combined_output)
  it.snapshot(filename="gradient_gallery.txt")
}

///|
test "transform showcase" (it : @test.Test) {
  let base_circle = @vg.Image::circle(@color.red(), 20.0)

  // Apply different transformations
  let translated = base_circle.translate_img(60.0, 0.0)
  let scaled = base_circle.scale(1.5, 0.8)
  let rotated = base_circle.rotate(3.14159 / 4.0) // 45 degrees

  // Compose all transformations
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
