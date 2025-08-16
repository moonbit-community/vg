// Integration tests for the Vg library

test "example image creation" {
  let img = example()
  
  // Test that the example image returns appropriate colors at different points
  let center = point(0.0, 0.0)
  let right = point(50.0, 0.0)
  let far_right = point(100.0, 0.0)
  
  let c_center = img(center)
  let c_right = img(right)
  let c_far_right = img(far_right)
  
  // Center should have red from the circle
  if c_center.r <= 0.5 {
    fail("Center should be predominantly red")
  }
  
  // Right should have blue from the translated rectangle
  if c_right.b <= 0.5 {
    fail("Right area should be predominantly blue")
  }
  
  // Far right should be transparent (outside both shapes)
  if c_far_right.a > 0.1 {
    fail("Far right should be mostly transparent")
  }
}

test "complete workflow - create and render image" {
  // Create a complex image
  let background = rectangle(gray(0.9), 200.0, 200.0)
  let red_circle = circle(red(), 40.0)
  let blue_circle = translate_image(60.0, 0.0, circle(blue(), 30.0))
  let green_rect = translate_image(-50.0, 50.0, rectangle(green(), 30.0, 20.0))
  
  let complex_image = background
    |> compose_images(red_circle)
    |> compose_images(blue_circle)
    |> compose_images(green_rect)
  
  // Render to SVG
  let svg = render_image_to_svg(complex_image, 200.0, 200.0, 50)
  
  if not(svg.contains("svg")) {
    fail("Should produce valid SVG output")
  }
  
  if svg.length() < 100 {
    fail("SVG output should be substantial")
  }
}

test "path to SVG integration" {
  // Create a complex path
  let path = empty_path()
    |> move_to(point(50.0, 50.0))
    |> line_to(point(100.0, 50.0))
    |> curve_to(point(125.0, 50.0), point(125.0, 75.0), point(100.0, 75.0))
    |> line_to(point(50.0, 75.0))
    |> close_path()
  
  // Render to SVG
  let doc = new_svg(150.0, 100.0)
    |> render_path(path, magenta())
  
  let svg_string = to_svg_string(doc)
  
  if not(svg_string.contains("path")) {
    fail("Should contain path element")
  }
  
  if not(svg_string.contains("M 50,50")) {
    fail("Should contain correct path data")
  }
}

test "gradient rendering" {
  let gradient_img = linear_gradient(red(), blue(), point(-50.0, 0.0), point(50.0, 0.0))
  
  // Test gradient at different points
  let left = gradient_img(point(-50.0, 0.0))
  let center = gradient_img(point(0.0, 0.0))
  let right = gradient_img(point(50.0, 0.0))
  
  if left != red() {
    fail("Gradient left should be red")
  }
  
  if right != blue() {
    fail("Gradient right should be blue")
  }
  
  // Center should be a mix
  if center == red() || center == blue() {
    fail("Gradient center should be interpolated")
  }
}

test "transformation chain" {
  let original = circle(yellow(), 10.0)
  
  // Apply multiple transformations
  let transformed = original
    |> scale_image(2.0, 1.5)
    |> rotate_image(3.14159 / 4.0)  // 45 degrees
    |> translate_image(20.0, 10.0)
  
  // Test that transformations work
  let origin_color = transformed(point(0.0, 0.0))
  let translated_center = transformed(point(20.0, 10.0))
  
  if origin_color.a > 0.1 {
    fail("Origin should be mostly transparent after transformation")
  }
  
  // The exact color at translated center depends on rotation, but should not be transparent
  if translated_center.a < 0.1 {
    fail("Transformed center area should have some color")
  }
}

test "color operations" {
  let c1 = rgba(1.0, 0.5, 0.0, 0.8)
  let c2 = rgba(0.0, 0.5, 1.0, 0.6)
  
  let blended = blend(c1, c2)
  let scaled = scale_color(c1, 0.5)
  let clamped = clamp_color({ r: 1.5, g: -0.2, b: 0.5, a: 2.0 })
  
  // Blended should have higher alpha than individual colors
  if blended.a <= c1.a && blended.a <= c2.a {
    fail("Blended alpha should be higher")
  }
  
  // Scaled should have half the RGB values
  if (scaled.r - 0.5).abs() > 0.001 {
    fail("Scaled red component incorrect")
  }
  
  // Clamped should be within [0,1] range
  if clamped.r != 1.0 || clamped.g != 0.0 || clamped.a != 1.0 {
    fail("Color clamping failed")
  }
}
