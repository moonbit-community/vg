// Tests for image combinators

test "constant image" {
  let red_img = const_image(red())
  let p1 = point(0.0, 0.0)
  let p2 = point(100.0, -50.0)
  
  let c1 = red_img(p1)
  let c2 = red_img(p2)
  
  if c1 != red() || c2 != red() {
    fail("Constant image should return same color everywhere")
  }
}

test "empty image" {
  let empty_img = empty()
  let p = point(5.0, 10.0)
  let c = empty_img(p)
  
  if c != transparent() {
    fail("Empty image should be transparent everywhere")
  }
}

test "circle image" {
  let circle_img = circle(blue(), 5.0)
  
  let inside = point(3.0, 0.0)  // Distance 3 < radius 5
  let outside = point(10.0, 0.0)  // Distance 10 > radius 5
  let on_edge = point(5.0, 0.0)  // Distance 5 = radius 5
  
  let c_inside = circle_img(inside)
  let c_outside = circle_img(outside)
  let c_edge = circle_img(on_edge)
  
  if c_inside != blue() {
    fail("Point inside circle should be blue")
  }
  
  if c_outside != transparent() {
    fail("Point outside circle should be transparent")
  }
  
  if c_edge != blue() {
    fail("Point on circle edge should be blue")
  }
}

test "rectangle image" {
  let rect_img = rectangle(green(), 10.0, 6.0)
  
  let inside = point(2.0, 1.0)  // Within [-5,5] x [-3,3]
  let outside = point(8.0, 1.0)  // Outside width bounds
  let on_edge = point(5.0, 0.0)  // On width edge
  
  let c_inside = rect_img(inside)
  let c_outside = rect_img(outside)
  let c_edge = rect_img(on_edge)
  
  if c_inside != green() {
    fail("Point inside rectangle should be green")
  }
  
  if c_outside != transparent() {
    fail("Point outside rectangle should be transparent")
  }
  
  if c_edge != green() {
    fail("Point on rectangle edge should be green")
  }
}

test "image translation" {
  let circle_img = circle(red(), 3.0)
  let translated = translate_image(5.0, 0.0, circle_img)
  
  let original_center = point(0.0, 0.0)
  let new_center = point(5.0, 0.0)
  
  let c_original = translated(original_center)
  let c_new = translated(new_center)
  
  if c_original != transparent() {
    fail("Original center should be transparent after translation")
  }
  
  if c_new != red() {
    fail("New center should be red after translation")
  }
}

test "image scaling" {
  let circle_img = circle(blue(), 2.0)
  let scaled = scale_image(2.0, 2.0, circle_img)
  
  let p = point(3.0, 0.0)  // Would be outside original circle but inside scaled
  let c = scaled(p)
  
  if c != blue() {
    fail("Scaled image should be larger")
  }
}

test "image composition" {
  let red_circle = circle(red(), 3.0)
  let blue_circle = translate_image(2.0, 0.0, circle(blue(), 3.0))
  let composed = compose_images(red_circle, blue_circle)
  
  let red_only = point(-2.0, 0.0)  // Only in red circle
  let blue_only = point(4.0, 0.0)  // Only in blue circle
  let overlap = point(1.0, 0.0)    // In both circles
  
  let c_red = composed(red_only)
  let c_blue = composed(blue_only)
  let c_overlap = composed(overlap)
  
  if c_red != red() {
    fail("Red-only area should be red")
  }
  
  if c_blue != blue() {
    fail("Blue-only area should be blue")
  }
  
  // Overlap should be a blend of red and blue
  if c_overlap == red() || c_overlap == blue() || c_overlap == transparent() {
    fail("Overlap area should be blended")
  }
}

test "image cutting" {
  let red_rect = rectangle(red(), 10.0, 10.0)
  let circle_mask = circle(white(), 3.0)  // White mask
  let cut_img = cut(red_rect, circle_mask)
  
  let inside_mask = point(2.0, 0.0)  // Inside circle mask
  let outside_mask = point(8.0, 0.0)  // Outside circle mask
  
  let c_inside = cut_img(inside_mask)
  let c_outside = cut_img(outside_mask)
  
  if c_inside != red() {
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
