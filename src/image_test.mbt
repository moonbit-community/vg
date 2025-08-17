// Tests for image combinators

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

test "empty image" {
  let empty_img = @vg.empty()
  let p = @vg.point(5.0, 10.0)
  let c = empty_img(p)
  
  if c != @vg.transparent() {
    fail("Empty image should be transparent everywhere")
  }
}

test "circle image" {
  let circle_img = @vg.circle(@vg.blue(), 5.0)
  
  let inside = @vg.point(3.0, 0.0)  // Distance 3 < radius 5
  let outside = @vg.point(10.0, 0.0)  // Distance 10 > radius 5
  let on_edge = @vg.point(5.0, 0.0)  // Distance 5 = radius 5
  
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

test "rectangle image" {
  let rect_img = @vg.rectangle(@vg.green(), 10.0, 6.0)
  
  let inside = @vg.point(2.0, 1.0)  // Within [-5,5] x [-3,3]
  let outside = @vg.point(8.0, 1.0)  // Outside width bounds
  let on_edge = @vg.point(5.0, 0.0)  // On width edge
  
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

test "image scaling" {
  let circle_img = @vg.circle(@vg.blue(), 2.0)
  let scaled = @vg.scale_image(2.0, 2.0, circle_img)
  
  let p = @vg.point(3.0, 0.0)  // Would be outside original circle but inside scaled
  let c = scaled(p)
  
  if c != @vg.blue() {
    fail("Scaled image should be larger")
  }
}

test "image composition" {
  let red_circle = @vg.circle(@vg.red(), 3.0)
  let blue_circle = @vg.translate_img(2.0, 0.0, @vg.circle(@vg.blue(), 3.0))
  let composed = @vg.compose_imgs(red_circle, blue_circle)
  
  let red_only = @vg.point(-2.0, 0.0)  // Only in red circle
  let blue_only = @vg.point(4.0, 0.0)  // Only in blue circle
  let overlap = @vg.point(1.0, 0.0)    // In both circles
  
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
  if c_overlap == @vg.red() || c_overlap == @vg.blue() || c_overlap == @vg.transparent() {
    fail("Overlap area should be blended")
  }
}

test "image cutting" {
  let red_rect = @vg.rectangle(@vg.red(), 10.0, 10.0)
  let circle_mask = @vg.circle(@vg.white(), 3.0)  // White mask
  let cut_img = @vg.cut(red_rect, circle_mask)
  
  let inside_mask = @vg.point(2.0, 0.0)  // Inside circle mask
  let outside_mask = @vg.point(8.0, 0.0)  // Outside circle mask
  
  let c_inside = cut_img(inside_mask)
  let c_outside = cut_img(outside_mask)
  
  if c_inside != @vg.red() {
    fail("Area inside mask should show original color")
  }
  
  if c_outside.a != 0.0 {
    fail("Area outside mask should be transparent")
  }
}

test "linear gradient" {
  let gradient = linear_gradient(red(), blue(), point(-5.0, 0.0), point(5.0, 0.0))
  
  let left = point(-5.0, 0.0)   // Should be red
  let right = point(5.0, 0.0)   // Should be blue
  let center = point(0.0, 0.0)  // Should be mix
  
  let c_left = gradient(left)
  let c_right = gradient(right)
  let c_center = gradient(center)
  
  if c_left != red() {
    fail("Gradient start should be red")
  }
  
  if c_right != blue() {
    fail("Gradient end should be blue")
  }
  
  // Center should be a mix (not pure red or blue)
  if c_center == red() || c_center == blue() {
    fail("Gradient center should be interpolated")
  }
}

test "radial gradient" {
  let gradient = radial_gradient(white(), black(), point(0.0, 0.0), 5.0)
  
  let center = point(0.0, 0.0)  // Should be white
  let edge = point(5.0, 0.0)    // Should be black
  let middle = point(2.5, 0.0)  // Should be gray
  
  let c_center = gradient(center)
  let c_edge = gradient(edge)
  let c_middle = gradient(middle)
  
  if c_center != white() {
    fail("Radial gradient center should be white")
  }
  
  if c_edge != black() {
    fail("Radial gradient edge should be black")
  }
  
  // Middle should be between white and black
  if c_middle == white() || c_middle == black() {
    fail("Radial gradient middle should be interpolated")
  }
}

test "ellipse image" {
  let ellipse_img = ellipse(green(), 4.0, 2.0)
  
  let inside = point(2.0, 1.0)  // Inside ellipse
  let outside = point(5.0, 0.0)  // Outside ellipse
  let edge = point(4.0, 0.0)     // On edge
  
  let c_inside = ellipse_img(inside)
  let c_outside = ellipse_img(outside)
  let c_edge = ellipse_img(edge)
  
  inspect(c_inside, content="{r: 0, g: 1, b: 0, a: 1}")
  inspect(c_outside, content="{r: 0, g: 0, b: 0, a: 0}")
  inspect(c_edge, content="{r: 0, g: 1, b: 0, a: 1}")
  
  if c_inside != green() {
    fail("Point inside ellipse should be green")
  }
  
  if c_outside != transparent() {
    fail("Point outside ellipse should be transparent")
  }
  
  if c_edge != green() {
    fail("Point on ellipse edge should be green")
  }
}

test "polygon image" {
  let triangle_points = [point(0.0, -2.0), point(-2.0, 2.0), point(2.0, 2.0)]
  let triangle_img = polygon(blue(), triangle_points)
  
  let inside = point(0.0, 0.0)   // Inside triangle
  let outside = point(0.0, -3.0) // Outside triangle
  
  let c_inside = triangle_img(inside)
  let c_outside = triangle_img(outside)
  
  if c_inside != blue() {
    fail("Point inside triangle should be blue")
  }
  
  if c_outside != transparent() {
    fail("Point outside triangle should be transparent")
  }
}

test "opacity application" {
  let red_img = circle(red(), 5.0)
  let semi_transparent = with_opacity(red_img, 0.5)
  
  let center = point(0.0, 0.0)
  let color = semi_transparent(center)
  
  if color.r != 1.0 || color.g != 0.0 || color.b != 0.0 {
    fail("Color components should remain unchanged")
  }
  
  if color.a != 0.5 {
    fail("Alpha should be reduced to 0.5")
  }
}
