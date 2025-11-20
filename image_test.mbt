// Tests for image combinators

///|
test "constant image" {
  let red_img = @vg.const_color(@vg.red())
  let p1 = @vg.point(0.0, 0.0)
  let p2 = @vg.point(100.0, -50.0)
  let c1 = red_img(p1)
  let c2 = red_img(p2)
  if c1 != @vg.red() || c2 != @vg.red() {
    fail("Constant image should return same color everywhere")
  }
}

///|
test "empty image" {
  let empty_img = @vg.empty()
  let p = @vg.point(5.0, 10.0)
  let c = empty_img(p)
  if c != @vg.transparent() {
    fail("Empty image should be transparent everywhere")
  }
}

///|
test "circle image" {
  let circle_img = @vg.circle(@vg.blue(), 5.0)
  let inside = @vg.point(3.0, 0.0) // Distance 3 < radius 5
  let outside = @vg.point(10.0, 0.0) // Distance 10 > radius 5
  let on_edge = @vg.point(5.0, 0.0) // Distance 5 = radius 5
  let c_inside = circle_img(inside)
  let c_outside = circle_img(outside)
  let c_edge = circle_img(on_edge)
  if c_inside != @vg.blue() {
    fail("Point inside circle should be blue")
  }
  if c_outside != @vg.transparent() {
    fail("Point outside circle should be transparent")
  }
  if c_edge != @vg.blue() {
    fail("Point on circle edge should be blue")
  }
}

///|
test "rectangle image" {
  let rect_img = @vg.rectangle(@vg.green(), 10.0, 6.0)
  let inside = @vg.point(2.0, 1.0) // Within [-5,5] x [-3,3]
  let outside = @vg.point(8.0, 1.0) // Outside width bounds
  let on_edge = @vg.point(5.0, 0.0) // On width edge
  let c_inside = rect_img(inside)
  let c_outside = rect_img(outside)
  let c_edge = rect_img(on_edge)
  if c_inside != @vg.green() {
    fail("Point inside rectangle should be green")
  }
  if c_outside != @vg.transparent() {
    fail("Point outside rectangle should be transparent")
  }
  if c_edge != @vg.green() {
    fail("Point on rectangle edge should be green")
  }
}

///|
test "image translation" {
  let circle_img = @vg.circle(@vg.red(), 3.0)
  let translated = @vg.translate_img(5.0, 0.0, circle_img)
  let original_center = @vg.point(0.0, 0.0)
  let new_center = @vg.point(5.0, 0.0)
  let c_original = translated(original_center)
  let c_new = translated(new_center)
  if c_original != @vg.transparent() {
    fail("Original center should be transparent after translation")
  }
  if c_new != @vg.red() {
    fail("New center should be red after translation")
  }
}

///|
test "image scaling" {
  let circle_img = @vg.circle(@vg.blue(), 2.0)
  let scaled = @vg.scale_image(2.0, 2.0, circle_img)
  let p = @vg.point(3.0, 0.0) // Would be outside original circle but inside scaled
  let c = scaled(p)
  if c != @vg.blue() {
    fail("Scaled image should be larger")
  }
}

///|
test "image composition" {
  let red_circle = @vg.circle(@vg.red(), 3.0)
  let blue_circle = @vg.translate_img(2.0, 0.0, @vg.circle(@vg.blue(), 3.0))
  let composed = @vg.compose_imgs(red_circle, blue_circle)
  let red_only = @vg.point(-2.0, 0.0) // Only in red circle
  let blue_only = @vg.point(4.0, 0.0) // Only in blue circle
  let overlap = @vg.point(1.0, 0.0) // In both circles
  let c_red = composed(red_only)
  let c_blue = composed(blue_only)
  let c_overlap = composed(overlap)
  if c_red != @vg.red() {
    fail("Red-only area should be red")
  }
  if c_blue != @vg.blue() {
    fail("Blue-only area should be blue")
  }

  // Overlap should be a blend of red and blue
  if c_overlap == @vg.red() ||
    c_overlap == @vg.blue() ||
    c_overlap == @vg.transparent() {
    fail("Overlap area should be blended")
  }
}

///|
test "image cutting" {
  let red_rect = @vg.rectangle(@vg.red(), 10.0, 10.0)
  let circle_mask = @vg.circle(@vg.white(), 3.0) // White mask
  let cut_img = @vg.cut(red_rect, circle_mask)
  let inside_mask = @vg.point(2.0, 0.0) // Inside circle mask
  let outside_mask = @vg.point(8.0, 0.0) // Outside circle mask
  let c_inside = cut_img(inside_mask)
  let c_outside = cut_img(outside_mask)
  if c_inside != @vg.red() {
    fail("Area inside mask should show original color")
  }
  if c_outside.a != 0.0 {
    fail("Area outside mask should be transparent")
  }
}

///|
test "linear gradient" {
  let gradient = @vg.linear_gradient(
    @vg.red(),
    @vg.blue(),
    @vg.point(-5.0, 0.0),
    @vg.point(5.0, 0.0),
  )
  let left = @vg.point(-5.0, 0.0) // Should be red
  let right = @vg.point(5.0, 0.0) // Should be blue
  let center = @vg.point(0.0, 0.0) // Should be mix
  let c_left = gradient(left)
  let c_right = gradient(right)
  let c_center = gradient(center)
  if c_left != @vg.red() {
    fail("Gradient start should be red")
  }
  if c_right != @vg.blue() {
    fail("Gradient end should be blue")
  }

  // Center should be a mix (not pure red or blue)
  if c_center == @vg.red() || c_center == @vg.blue() {
    fail("Gradient center should be interpolated")
  }
}

///|
test "radial gradient" {
  let gradient = @vg.radial_gradient(
    @vg.white(),
    @vg.black(),
    @vg.point(0.0, 0.0),
    5.0,
  )
  let center = @vg.point(0.0, 0.0) // Should be white
  let edge = @vg.point(5.0, 0.0) // Should be black
  let middle = @vg.point(2.5, 0.0) // Should be gray
  let c_center = gradient(center)
  let c_edge = gradient(edge)
  let c_middle = gradient(middle)
  if c_center != @vg.white() {
    fail("Radial gradient center should be white")
  }
  if c_edge != @vg.black() {
    fail("Radial gradient edge should be black")
  }

  // Middle should be between white and black
  if c_middle == @vg.white() || c_middle == @vg.black() {
    fail("Radial gradient middle should be interpolated")
  }
}

///|
test "ellipse image" {
  let ellipse_img = @vg.ellipse(@vg.green(), 4.0, 2.0)
  let inside = @vg.point(2.0, 1.0) // Inside ellipse
  let outside = @vg.point(5.0, 0.0) // Outside ellipse
  let edge = @vg.point(4.0, 0.0) // On edge
  let c_inside = ellipse_img(inside)
  let c_outside = ellipse_img(outside)
  let c_edge = ellipse_img(edge)
  inspect(c_inside, content="{r: 0, g: 1, b: 0, a: 1}")
  inspect(c_outside, content="{r: 0, g: 0, b: 0, a: 0}")
  inspect(c_edge, content="{r: 0, g: 1, b: 0, a: 1}")
  if c_inside != @vg.green() {
    fail("Point inside ellipse should be green")
  }
  if c_outside != @vg.transparent() {
    fail("Point outside ellipse should be transparent")
  }
  if c_edge != @vg.green() {
    fail("Point on ellipse edge should be green")
  }
}

///|
test "polygon image" {
  let triangle_points = [
    @vg.point(0.0, -2.0),
    @vg.point(-2.0, 2.0),
    @vg.point(2.0, 2.0),
  ]
  let triangle_img = @vg.polygon(@vg.blue(), triangle_points)
  let inside = @vg.point(0.0, 0.0) // Inside triangle
  let outside = @vg.point(0.0, -3.0) // Outside triangle
  let c_inside = triangle_img(inside)
  let c_outside = triangle_img(outside)
  if c_inside != @vg.blue() {
    fail("Point inside triangle should be blue")
  }
  if c_outside != @vg.transparent() {
    fail("Point outside triangle should be transparent")
  }
}

///|
test "opacity application" {
  let red_img = @vg.circle(@vg.red(), 5.0)
  let semi_transparent = @vg.with_opacity(red_img, 0.5)
  let center = @vg.point(0.0, 0.0)
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
  let background = @vg.rectangle(@vg.gray(0.95), 200.0, 150.0)
  let red_circle = @vg.circle(@vg.red(), 25.0)
  let blue_ellipse = @vg.ellipse(@vg.blue(), 30.0, 20.0)
  let green_rect = @vg.rectangle(@vg.green(), 40.0, 30.0)
  let composed = background
    |> @vg.compose_imgs(@vg.translate_img(50.0, 40.0, red_circle))
    |> @vg.compose_imgs(@vg.translate_img(100.0, 60.0, blue_ellipse))
    |> @vg.compose_imgs(@vg.translate_img(150.0, 50.0, green_rect))
    |> @vg.compose_imgs(
      @vg.translate_img(
        75.0,
        90.0,
        @vg.with_opacity(@vg.circle(@vg.yellow(), 20.0), 0.7),
      ),
    )
  let svg_string = composed.render_image_to_svg(200.0, 150.0, 40)
  it.write(svg_string)
  it.snapshot(filename="image_composition.svg")
}

///|
test "gradient images showcase" (it : @test.Test) {
  // Linear gradients
  let horizontal_gradient = @vg.linear_gradient(
    @vg.red(),
    @vg.blue(),
    @vg.point(-50.0, 0.0),
    @vg.point(50.0, 0.0),
  )
  let vertical_gradient = @vg.linear_gradient(
    @vg.green(),
    @vg.yellow(),
    @vg.point(0.0, -40.0),
    @vg.point(0.0, 40.0),
  )
  let diagonal_gradient = @vg.linear_gradient(
    @vg.purple(),
    @vg.cyan(),
    @vg.point(-35.0, -35.0),
    @vg.point(35.0, 35.0),
  )

  // Radial gradients
  let radial1 = @vg.radial_gradient(
    @vg.white(),
    @vg.red(),
    @vg.point(0.0, 0.0),
    30.0,
  )
  let radial2 = @vg.radial_gradient(
    @vg.yellow(),
    @vg.purple(),
    @vg.point(0.0, 0.0),
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
  let base_circle = @vg.circle(@vg.red(), 20.0)

  // Apply different transformations
  let translated = @vg.translate_img(60.0, 0.0, base_circle)
  let scaled = @vg.scale_image(1.5, 0.8, base_circle)
  let rotated = @vg.rotate_image(3.14159 / 4.0, base_circle) // 45 degrees

  // Compose all transformations
  let background = @vg.rectangle(@vg.gray(0.9), 200.0, 100.0)
  let showcase = background
    |> @vg.compose_imgs(@vg.translate_img(40.0, 50.0, base_circle))
    |> @vg.compose_imgs(@vg.translate_img(100.0, 50.0, translated))
    |> @vg.compose_imgs(@vg.translate_img(40.0, 30.0, scaled))
    |> @vg.compose_imgs(@vg.translate_img(140.0, 30.0, rotated))
  let svg_string = showcase.render_image_to_svg(200.0, 100.0, 30)
  it.write(svg_string)
  it.snapshot(filename="transform_showcase.svg")
}

///|
test "oo-style image transformations" {
  let circle_img = @vg.circle(@vg.red(), 2.0)
  
  // Test OO-style scale method
  let scaled = circle_img.scale(2.0, 2.0)
  let p = @vg.point(3.0, 0.0) // Would be outside original circle but inside scaled
  let c = scaled(p)
  if c != @vg.red() {
    fail("OO-style scaled image should be larger")
  }
  
  // Test OO-style translate method
  let translated = circle_img.translate(5.0, 0.0)
  let original_center = @vg.point(0.0, 0.0)
  let new_center = @vg.point(5.0, 0.0)
  let c_original = translated(original_center)
  let c_new = translated(new_center)
  if c_original != @vg.transparent() {
    fail("OO-style: Original center should be transparent after translation")
  }
  if c_new != @vg.red() {
    fail("OO-style: New center should be red after translation")
  }
  
  // Test OO-style rotate method
  let rotated = circle_img.rotate(3.14159 / 4.0) // 45 degrees
  let center = @vg.point(0.0, 0.0)
  let c_center = rotated(center)
  if c_center != @vg.red() {
    fail("OO-style: Circle center should remain red after rotation")
  }
}

///|
test "oo-style vs functional style equivalence" {
  let circle_img = @vg.circle(@vg.blue(), 3.0)
  
  // Test that OO-style and functional style produce the same results
  let functional_scaled = @vg.scale_image(2.0, 1.5, circle_img)
  let oo_scaled = circle_img.scale(2.0, 1.5)
  
  let functional_translated = @vg.translate_img(10.0, 5.0, circle_img)
  let oo_translated = circle_img.translate(10.0, 5.0)
  
  let functional_rotated = @vg.rotate_image(1.57, circle_img)
  let oo_rotated = circle_img.rotate(1.57)
  
  // Test several points
  let test_point = @vg.point(2.0, 1.0)
  
  if functional_scaled(test_point) != oo_scaled(test_point) {
    fail("OO-style and functional scale should produce identical results")
  }
  
  if functional_translated(test_point) != oo_translated(test_point) {
    fail("OO-style and functional translate should produce identical results")
  }
  
  if functional_rotated(test_point) != oo_rotated(test_point) {
    fail("OO-style and functional rotate should produce identical results")
  }
}

///|
test "oo-style image method chaining" {
  let base_circle = @vg.circle(@vg.green(), 5.0)
  
  // Test method chaining
  let transformed = base_circle
    .scale(2.0, 2.0)
    .translate(10.0, 5.0)
    .rotate(0.5)
  
  // Verify the chain works
  let test_point = @vg.point(10.0, 5.0)
  let color = transformed(test_point)
  
  // The color should be either green or transparent, not an error
  if color.r < 0.0 || color.r > 1.0 ||
     color.g < 0.0 || color.g > 1.0 ||
     color.b < 0.0 || color.b > 1.0 ||
     color.a < 0.0 || color.a > 1.0 {
    fail("OO-style method chaining should produce valid colors")
  }
}
