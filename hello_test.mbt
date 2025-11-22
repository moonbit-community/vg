// Integration tests for the Vg library

///|
test "example image creation" {
  let img = @vg.example()

  // Test that the example image returns appropriate colors at different points
  let center = @vg.Point::new(0.0, 0.0)
  let right = @vg.Point::new(50.0, 0.0)
  let far_right = @vg.Point::new(100.0, 0.0)
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

///|
test "complete workflow - create and render image" {
  // Create a complex image
  let background = @vg.Image::rectangle(@color.gray(0.9), 200.0, 200.0)
  let red_circle = @vg.Image::circle(@color.red(), 40.0)
  let blue_circle = @vg.Image::circle(@color.blue(), 30.0).translate_img(
    60.0, 0.0,
  )
  let green_rect = @vg.Image::rectangle(@color.green(), 30.0, 20.0).translate_img(
    -50.0, 50.0,
  )
  let complex_image = background
    .compose(red_circle)
    .compose(blue_circle)
    .compose(green_rect)

  // Render to SVG
  let svg = complex_image.render_image_to_svg(200.0, 200.0, 50)
  if not(svg.contains("svg")) {
    fail("Should produce valid SVG output")
  }
  if svg.length() < 100 {
    fail("SVG output should be substantial")
  }
}

///|
test "path to SVG integration" {
  // Create a complex path
  let path = @vg.Path::empty()
    .move_to(@vg.Point::new(50.0, 50.0))
    .line_to(@vg.Point::new(100.0, 50.0))
    .curve_to(
      @vg.Point::new(125.0, 50.0),
      @vg.Point::new(125.0, 75.0),
      @vg.Point::new(100.0, 75.0),
    )
    .line_to(@vg.Point::new(50.0, 75.0))
    .close_path()

  // Render to SVG
  let doc = @svg.new_svg(150.0, 100.0).render_path(path, @color.magenta())
  let svg_string = doc.to_string()
  if not(svg_string.contains("path")) {
    fail("Should contain path element")
  }
  if not(svg_string.contains("M 50,50")) {
    fail("Should contain correct path data")
  }
}

///|
test "gradient rendering" {
  let gradient_img = @vg.Image::linear_gradient(
    @color.red(),
    @color.blue(),
    @vg.Point::new(-50.0, 0.0),
    @vg.Point::new(50.0, 0.0),
  )

  // Test gradient at different points
  let left = gradient_img(@vg.Point::new(-50.0, 0.0))
  let center = gradient_img(@vg.Point::new(0.0, 0.0))
  let right = gradient_img(@vg.Point::new(50.0, 0.0))
  if left != @color.red() {
    fail("Gradient left should be red")
  }
  if right != @color.blue() {
    fail("Gradient right should be blue")
  }

  // Center should be a mix
  if center == @color.red() || center == @color.blue() {
    fail("Gradient center should be interpolated")
  }
}

///|
test "transformation chain" {
  let original = @vg.Image::circle(@color.yellow(), 10.0)

  // Apply multiple transformations
  let scaled = original.scale(2.0, 1.5)
  let rotated = scaled.rotate(3.14159 / 4.0) // 45 degrees
  let transformed = rotated.translate_img(20.0, 10.0)

  // Test that transformations work
  let origin_color = transformed(@vg.Point::new(0.0, 0.0))
  let translated_center = transformed(@vg.Point::new(20.0, 10.0))
  if origin_color.a > 0.1 {
    fail("Origin should be mostly transparent after transformation")
  }

  // The exact color at translated center depends on rotation, but should not be transparent
  if translated_center.a < 0.1 {
    fail("Transformed center area should have some color")
  }
}

///|
test "color operations" {
  let c1 = @color.rgba(1.0, 0.5, 0.0, 0.8)
  let c2 = @color.rgba(0.0, 0.5, 1.0, 0.6)
  let blended = @color.blend(c1, c2)
  let scaled = @color.scale(c1, 0.5)
  let clamped = @color.clamp(@color.rgba(1.5, -0.2, 0.5, 2.0))

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

///|
test "complete vg library showcase" (it : @test.Test) {
  // Create a comprehensive demo showcasing all VG features
  let doc = @svg.new_svg(600.0, 500.0)
    .render_rectangle(0.0, 0.0, 600.0, 500.0, @color.gray(0.97)) // Light background
    .render_text(
      "MoonBit VG Library - Complete Showcase",
      @vg.Point::new(300.0, 40.0),
      20.0,
      @color.black(),
    )

    // Section 1: Basic Shapes
    .render_text(
      "Basic Shapes",
      @vg.Point::new(100.0, 70.0),
      16.0,
      @color.black(),
    )
    .render_circle(@vg.Point::new(80.0, 110.0), 25.0, @color.red())
    .render_rectangle(130.0, 85.0, 50.0, 50.0, @color.green())
    .render_ellipse(@vg.Point::new(230.0, 110.0), 35.0, 20.0, @color.blue())

    // Section 2: Complex Shapes (Polygons)
    .render_text("Polygons", @vg.Point::new(350.0, 70.0), 16.0, @color.black())
    .render_polygon(
      [ // Pentagon
        @vg.Point::new(330.0, 95.0),
        @vg.Point::new(370.0, 95.0),
        @vg.Point::new(375.0, 118.0),
        @vg.Point::new(350.0, 130.0),
        @vg.Point::new(325.0, 118.0),
      ],
      @color.orange(),
    )
    .render_polygon(
      [ // Triangle
        @vg.Point::new(420.0, 90.0),
        @vg.Point::new(400.0, 130.0),
        @vg.Point::new(440.0, 130.0),
      ],
      @color.purple(),
    )
    .render_polygon(
      [ // Diamond
        @vg.Point::new(490.0, 90.0),
        @vg.Point::new(505.0, 110.0),
        @vg.Point::new(490.0, 130.0),
        @vg.Point::new(475.0, 110.0),
      ],
      @color.cyan(),
    )

    // Section 3: Lines and Strokes
    .render_text(
      "Lines & Strokes",
      @vg.Point::new(100.0, 180.0),
      16.0,
      @color.black(),
    )
    .render_line(
      @vg.Point::new(50.0, 210.0),
      @vg.Point::new(250.0, 210.0),
      @color.black(),
      3.0,
    )
    .render_line(
      @vg.Point::new(50.0, 230.0),
      @vg.Point::new(200.0, 250.0),
      @color.red(),
      2.0,
    )
    .render_line(
      @vg.Point::new(50.0, 270.0),
      @vg.Point::new(150.0, 230.0),
      @color.blue(),
      4.0,
    )

    // Section 4: Complex Paths
    .render_text(
      "Custom Paths",
      @vg.Point::new(350.0, 180.0),
      16.0,
      @color.black(),
    )

  // Create complex paths
  let wave_path = @vg.Path::empty()
    .move_to(@vg.Point::new(300.0, 220.0))
    .curve_to(
      @vg.Point::new(320.0, 200.0),
      @vg.Point::new(340.0, 240.0),
      @vg.Point::new(360.0, 220.0),
    )
    .curve_to(
      @vg.Point::new(380.0, 200.0),
      @vg.Point::new(400.0, 240.0),
      @vg.Point::new(420.0, 220.0),
    )
    .curve_to(
      @vg.Point::new(440.0, 200.0),
      @vg.Point::new(460.0, 240.0),
      @vg.Point::new(480.0, 220.0),
    )
  let heart_path = @vg.Path::empty()
    .move_to(@vg.Point::new(380.0, 270.0))
    .curve_to(
      @vg.Point::new(370.0, 260.0),
      @vg.Point::new(355.0, 260.0),
      @vg.Point::new(345.0, 270.0),
    )
    .curve_to(
      @vg.Point::new(335.0, 280.0),
      @vg.Point::new(335.0, 295.0),
      @vg.Point::new(345.0, 305.0),
    )
    .line_to(@vg.Point::new(380.0, 340.0))
    .line_to(@vg.Point::new(415.0, 305.0))
    .curve_to(
      @vg.Point::new(425.0, 295.0),
      @vg.Point::new(425.0, 280.0),
      @vg.Point::new(415.0, 270.0),
    )
    .curve_to(
      @vg.Point::new(405.0, 260.0),
      @vg.Point::new(390.0, 260.0),
      @vg.Point::new(380.0, 270.0),
    )
    .close_path()
  let final_doc = doc
    .render_path(wave_path, @color.magenta())
    .render_path(heart_path, @color.red())

    // Section 5: Text and Typography
    .render_text(
      "Typography Examples",
      @vg.Point::new(100.0, 320.0),
      16.0,
      @color.black(),
    )
    .render_text(
      "Regular Text",
      @vg.Point::new(100.0, 350.0),
      12.0,
      @color.black(),
    )
    .render_text(
      "Colored Text",
      @vg.Point::new(200.0, 350.0),
      12.0,
      @color.blue(),
    )
    .render_text(
      "Large Text",
      @vg.Point::new(100.0, 380.0),
      18.0,
      @color.green(),
    )
    .render_text(
      "Purple Text",
      @vg.Point::new(250.0, 380.0),
      14.0,
      @color.purple(),
    )

    // Footer
    .render_line(
      @vg.Point::new(50.0, 420.0),
      @vg.Point::new(550.0, 420.0),
      @color.gray(0.7),
      1.0,
    )
    .render_text(
      "Generated by MoonBit VG - Declarative 2D Vector Graphics",
      @vg.Point::new(300.0, 450.0),
      12.0,
      @color.gray(0.5),
    )
    .render_text(
      "Snapshot Testing Showcase",
      @vg.Point::new(300.0, 470.0),
      10.0,
      @color.gray(0.6),
    )
  let svg_string = final_doc.to_string()
  it.write(svg_string)
  it.snapshot(filename="complete_showcase.svg")
}
