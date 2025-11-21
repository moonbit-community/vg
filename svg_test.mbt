// Tests for SVG rendering

///|
test "SVG document creation" {
  let doc = @vg.new_svg(100.0, 200.0)
  if doc.width != 100.0 || doc.height != 200.0 {
    fail("SVG document dimensions incorrect")
  }
  if doc.elements.length() != 0 {
    fail("New SVG document should have no elements")
  }
}

///|
test "adding elements to SVG" {
  let doc = @vg.new_svg(100.0, 100.0)
    .add_element("<circle cx=\"50\" cy=\"50\" r=\"25\"/>")
    .add_element("<rect x=\"10\" y=\"10\" width=\"30\" height=\"20\"/>")
  if doc.elements.length() != 2 {
    fail("SVG document should have 2 elements")
  }
}

///|
test "circle rendering" (it : @test.Test) {
  let doc = @vg.new_svg(100.0, 100.0).render_circle(
    @vg.point(50.0, 50.0),
    25.0,
    @vg.red(),
  )
  inspect(
    doc,
    content=(
      #|{width: 100, height: 100, elements: ["<circle cx=\"50\" cy=\"50\" r=\"25\" fill=\"#FF0000\"/>"]}
    ),
  )
  let svg_string = doc.to_string()
  it.write(svg_string)
  it.snapshot(filename="circle_rendering.svg")
}

///|
test "rectangle rendering" (it : @test.Test) {
  let doc = @vg.new_svg(200.0, 150.0).render_rectangle(
    10.0,
    20.0,
    50.0,
    30.0,
    @vg.blue(),
  )
  let svg_string = doc.to_string()
  it.write(svg_string)
  it.snapshot(filename="rectangle_rendering.svg")
}

///|
test "path rendering" {
  let path = @vg.Path::rect(0.0, 0.0, 10.0, 10.0)
  let doc = @vg.new_svg(100.0, 100.0).render_path(path, @vg.green())
  if doc.elements.length() != 1 {
    fail("Should have one path element")
  }
  let element = doc.elements[0]
  if not(element.contains("path")) || not(element.contains("d=\"")) {
    fail("Path element should contain path data")
  }
}

///|
test "line rendering" {
  let start = @vg.point(0.0, 0.0)
  let end = @vg.point(100.0, 50.0)
  let doc = @vg.new_svg(150.0, 100.0).render_line(start, end, @vg.black(), 2.0)
  if doc.elements.length() != 1 {
    fail("Should have one line element")
  }
  let element = doc.elements[0]
  if not(element.contains("line")) || not(element.contains("x1=\"0\"")) {
    fail("Line element should contain correct coordinates")
  }
}

///|
test "text rendering" {
  let doc = @vg.new_svg(200.0, 100.0).render_text(
    "Hello World",
    @vg.point(50.0, 30.0),
    16.0,
    @vg.black(),
  )
  if doc.elements.length() != 1 {
    fail("Should have one text element")
  }
  let element = doc.elements[0]
  if not(element.contains("text")) || not(element.contains("Hello World")) {
    fail("Text element should contain the text content")
  }
}

///|
test "SVG string generation" {
  let doc = @vg.new_svg(100.0, 100.0).render_circle(
    @vg.point(50.0, 50.0),
    25.0,
    @vg.red(),
  )
  let svg_string = doc.to_string()
  if not(svg_string.contains("<?xml")) {
    fail("SVG string should contain XML declaration")
  }
  if not(svg_string.contains("<svg")) {
    fail("SVG string should contain SVG root element")
  }
  if not(svg_string.contains("width=\"100\"")) {
    fail("SVG string should contain correct width")
  }
  if not(svg_string.contains("</svg>")) {
    fail("SVG string should be properly closed")
  }
  if not(svg_string.contains("circle")) {
    fail("SVG string should contain the circle element")
  }
}

///|
test "complex SVG document" {
  let doc = @vg.new_svg(200.0, 200.0)
    .render_rectangle(10.0, 10.0, 180.0, 180.0, @vg.gray(0.9))
    .render_circle(@vg.point(100.0, 100.0), 50.0, @vg.red())
    .render_line(
      @vg.point(50.0, 50.0),
      @vg.point(150.0, 150.0),
      @vg.blue(),
      3.0,
    )
    .render_text("Test", @vg.point(100.0, 180.0), 14.0, @vg.black())
  if doc.elements.length() != 4 {
    fail("Complex document should have 4 elements")
  }
  let svg_string = doc.to_string()
  if not(svg_string.contains("rect")) ||
    not(svg_string.contains("circle")) ||
    not(svg_string.contains("line")) ||
    not(svg_string.contains("text")) {
    fail("Complex SVG should contain all element types")
  }
}

///|
test "image to SVG rendering" {
  let img = @vg.Image::circle(@vg.red(), 25.0)
  let svg_string = img.render_image_to_svg(100.0, 100.0, 20)
  if not(svg_string.contains("svg")) {
    fail("Image rendering should produce valid SVG")
  }
  if not(svg_string.contains("rect")) {
    fail("Image rendering should contain rectangle elements for pixels")
  }
}

///|
test "color with alpha in SVG" {
  let semi_transparent = @vg.rgba(1.0, 0.0, 0.0, 0.5)
  let doc = @vg.new_svg(100.0, 100.0).render_circle(
    @vg.point(50.0, 50.0),
    25.0,
    semi_transparent,
  )
  inspect(
    doc,
    content=(
      #|{width: 100, height: 100, elements: ["<circle cx=\"50\" cy=\"50\" r=\"25\" fill=\"rgba(255,0,0,0.5)\"/>"]}
    ),
  )
}

///|
test "comprehensive svg rendering" (it : @test.Test) {
  let complex_doc = @vg.new_svg(300.0, 200.0)
    .render_rectangle(10.0, 10.0, 280.0, 180.0, @vg.gray(0.95)) // Background
    .render_circle(@vg.point(80.0, 60.0), 30.0, @vg.red()) // Red circle
    .render_ellipse(@vg.point(150.0, 60.0), 25.0, 15.0, @vg.blue()) // Blue ellipse
    .render_rectangle(200.0, 30.0, 40.0, 60.0, @vg.green()) // Green rectangle
    .render_line(
      @vg.point(20.0, 120.0),
      @vg.point(280.0, 120.0),
      @vg.black(),
      2.0,
    ) // Divider line
    .render_text(
      "VG Graphics Demo",
      @vg.point(150.0, 150.0),
      16.0,
      @vg.purple(),
    ) // Title text
  inspect(
    complex_doc,
    content=(
      #|{width: 300, height: 200, elements: ["<rect x=\"10\" y=\"10\" width=\"280\" height=\"180\" fill=\"#F2F2F2\"/>", "<circle cx=\"80\" cy=\"60\" r=\"30\" fill=\"#FF0000\"/>", "<ellipse cx=\"150\" cy=\"60\" rx=\"25\" ry=\"15\" fill=\"#0000FF\"/>", "<rect x=\"200\" y=\"30\" width=\"40\" height=\"60\" fill=\"#00FF00\"/>", "<line x1=\"20\" y1=\"120\" x2=\"280\" y2=\"120\" stroke=\"#000000\" stroke-width=\"2\" stroke-linecap=\"round\" fill=\"none\"/>", "<text x=\"150\" y=\"150\" font-size=\"16\" font-family=\"Arial, sans-serif\" text-anchor=\"middle\" dominant-baseline=\"central\" fill=\"#7F007F\">VG Graphics Demo</text>"]}
    ),
  )
  let svg_string = complex_doc.to_string()
  it.write(svg_string)
  it.snapshot(filename="comprehensive_demo.svg")
}

///|
test "svg string generation" (it : @test.Test) {
  let doc = @vg.new_svg(100.0, 100.0).render_circle(
    @vg.point(50.0, 50.0),
    25.0,
    @vg.red(),
  )
  let svg_string = doc.to_string()
  inspect(
    svg_string,
    content=(
      #|<?xml version="1.0" encoding="UTF-8"?>
      #|<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">
      #|  <circle cx="50" cy="50" r="25" fill="#FF0000"/>
      #|</svg>
    ),
  )
  it.write(svg_string)
  it.snapshot(filename="svg_string.svg")
}

///|
test "path rendering to svg" (it : @test.Test) {
  let custom_path = @vg.Path::empty()
    .move_to(@vg.point(10.0, 10.0))
    .line_to(@vg.point(90.0, 10.0))
    .curve_to(
      @vg.point(110.0, 10.0),
      @vg.point(110.0, 30.0),
      @vg.point(90.0, 30.0),
    )
    .line_to(@vg.point(10.0, 30.0))
    .close_path()
  let doc = @vg.new_svg(120.0, 50.0).render_path(custom_path, @vg.magenta())
  inspect(
    doc,
    content=(
      #|{width: 120, height: 50, elements: ["<path d=\"M 10,10 L 90,10 C 110,10 110,30 90,30 L 10,30 Z \" fill=\"#FF00FF\" stroke=\"none\"/>"]}
    ),
  )
  let svg_string = doc.to_string()
  it.write(svg_string)
  it.snapshot(filename="path_rendering.svg")
}

///|
test "gradient showcase" (it : @test.Test) {
  // Create a simple SVG to test gradient rendering
  let gradient_img = @vg.Image::linear_gradient(
    @vg.red(),
    @vg.blue(),
    @vg.point(-50.0, 0.0),
    @vg.point(50.0, 0.0),
  )
  let gradient_svg = gradient_img.render_image_to_svg(100.0, 50.0, 20)
  let radial_img = @vg.Image::radial_gradient(
    @vg.yellow(),
    @vg.purple(),
    @vg.point(0.0, 0.0),
    25.0,
  )
  let radial_svg = radial_img.render_image_to_svg(100.0, 50.0, 20)
  it.write(
    "<!-- Linear Gradient -->\n" +
    gradient_svg +
    "\n\n<!-- Radial Gradient -->\n" +
    radial_svg,
  )
  it.snapshot(filename="gradient_showcase.txt")
}

///|
test "shape gallery" (it : @test.Test) {
  let doc = @vg.new_svg(500.0, 400.0)
    .render_rectangle(0.0, 0.0, 500.0, 400.0, @vg.gray(0.98)) // Light background
    .render_text("VG Shape Gallery", @vg.point(250.0, 30.0), 24.0, @vg.black())

    // Row 1: Basic shapes
    .render_circle(@vg.point(80.0, 100.0), 30.0, @vg.red())
    .render_rectangle(130.0, 70.0, 60.0, 60.0, @vg.green())
    .render_ellipse(@vg.point(250.0, 100.0), 40.0, 25.0, @vg.blue())

    // Row 2: Complex shapes
    .render_polygon(
      [
        @vg.point(325.0, 80.0),
        @vg.point(375.0, 80.0),
        @vg.point(385.0, 110.0),
        @vg.point(350.0, 125.0),
        @vg.point(315.0, 110.0),
      ],
      @vg.orange(),
    )
    .render_polygon(
      [@vg.point(420.0, 75.0), @vg.point(395.0, 125.0), @vg.point(445.0, 125.0)],
      @vg.purple(),
    )

    // Row 3: Lines and text
    .render_line(
      @vg.point(50.0, 180.0),
      @vg.point(450.0, 180.0),
      @vg.black(),
      3.0,
    )
    .render_line(
      @vg.point(50.0, 200.0),
      @vg.point(450.0, 220.0),
      @vg.cyan(),
      2.0,
    )
    .render_line(
      @vg.point(50.0, 240.0),
      @vg.point(450.0, 200.0),
      @vg.magenta(),
      2.0,
    )

    // Labels
    .render_text("Circle", @vg.point(80.0, 150.0), 12.0, @vg.black())
    .render_text("Rectangle", @vg.point(160.0, 150.0), 12.0, @vg.black())
    .render_text("Ellipse", @vg.point(250.0, 150.0), 12.0, @vg.black())
    .render_text("Pentagon", @vg.point(350.0, 150.0), 12.0, @vg.black())
    .render_text("Triangle", @vg.point(420.0, 150.0), 12.0, @vg.black())

    // Footer
    .render_text(
      "Powered by MoonBit VG Library",
      @vg.point(250.0, 350.0),
      14.0,
      @vg.gray(0.6),
    )
  let svg_string = doc.to_string()
  it.write(svg_string)
  it.snapshot(filename="shape_gallery.svg")
}

///|
test "path showcase" (it : @test.Test) {
  let doc = @vg.new_svg(400.0, 300.0)
    .render_rectangle(0.0, 0.0, 400.0, 300.0, @vg.gray(0.95))
    .render_text(
      "Path Construction Showcase",
      @vg.point(200.0, 30.0),
      18.0,
      @vg.black(),
    )

  // Complex curved path
  let curved_path = @vg.Path::empty()
    .move_to(@vg.point(50.0, 80.0))
    .curve_to(
      @vg.point(100.0, 60.0),
      @vg.point(150.0, 100.0),
      @vg.point(200.0, 80.0),
    )
    .curve_to(
      @vg.point(250.0, 60.0),
      @vg.point(300.0, 100.0),
      @vg.point(350.0, 80.0),
    )
    .line_to(@vg.point(350.0, 120.0))
    .curve_to(
      @vg.point(300.0, 140.0),
      @vg.point(250.0, 100.0),
      @vg.point(200.0, 120.0),
    )
    .curve_to(
      @vg.point(150.0, 140.0),
      @vg.point(100.0, 100.0),
      @vg.point(50.0, 120.0),
    )
    .close_path()

  // Heart shape
  let heart_path = @vg.Path::empty()
    .move_to(@vg.point(100.0, 180.0))
    .curve_to(
      @vg.point(85.0, 165.0),
      @vg.point(65.0, 165.0),
      @vg.point(50.0, 180.0),
    )
    .curve_to(
      @vg.point(35.0, 195.0),
      @vg.point(35.0, 215.0),
      @vg.point(50.0, 230.0),
    )
    .line_to(@vg.point(100.0, 280.0))
    .line_to(@vg.point(150.0, 230.0))
    .curve_to(
      @vg.point(165.0, 215.0),
      @vg.point(165.0, 195.0),
      @vg.point(150.0, 180.0),
    )
    .curve_to(
      @vg.point(135.0, 165.0),
      @vg.point(115.0, 165.0),
      @vg.point(100.0, 180.0),
    )
    .close_path()

  // Star path
  let star_path = @vg.Path::empty()
    .move_to(@vg.point(300.0, 170.0))
    .line_to(@vg.point(310.0, 200.0))
    .line_to(@vg.point(340.0, 200.0))
    .line_to(@vg.point(318.0, 218.0))
    .line_to(@vg.point(328.0, 248.0))
    .line_to(@vg.point(300.0, 230.0))
    .line_to(@vg.point(272.0, 248.0))
    .line_to(@vg.point(282.0, 218.0))
    .line_to(@vg.point(260.0, 200.0))
    .line_to(@vg.point(290.0, 200.0))
    .close_path()
  let final_doc = doc
    .render_path(curved_path, @vg.blue())
    .render_path(heart_path, @vg.red())
    .render_path(star_path, @vg.gold())
    .render_text("Curved Path", @vg.point(200.0, 150.0), 12.0, @vg.blue())
    .render_text("Heart", @vg.point(100.0, 160.0), 12.0, @vg.red())
    .render_text("Star", @vg.point(300.0, 160.0), 12.0, @vg.gold())
  let svg_string = final_doc.to_string()
  it.write(svg_string)
  it.snapshot(filename="path_showcase.svg")
}

///|
test "svg rendering validation" (it : @test.Test) {
  // Create a simple test to validate SVG structure
  let doc = @vg.new_svg(200.0, 100.0)
    .render_rectangle(10.0, 10.0, 180.0, 80.0, @vg.gray(0.95))
    .render_circle(@vg.point(100.0, 50.0), 20.0, @vg.red())
    .render_text("SVG Test", @vg.point(100.0, 30.0), 14.0, @vg.black())
    .render_line(@vg.point(20.0, 80.0), @vg.point(180.0, 80.0), @vg.blue(), 2.0)
  let svg_string = doc.to_string()

  // Basic validation checks
  if not(svg_string.contains("<?xml")) {
    fail("SVG should start with XML declaration")
  }
  if not(svg_string.contains("<svg")) {
    fail("SVG should contain svg element")
  }
  if not(svg_string.contains("</svg>")) {
    fail("SVG should be properly closed")
  }
  if not(svg_string.contains("font-family")) {
    fail("SVG text should have font-family attribute")
  }
  it.write(svg_string)
  it.snapshot(filename="svg_validation_test.svg")
}

///|
test "minimal svg rendering test" (it : @test.Test) {
  // Create the simplest possible SVG to test basic rendering
  let doc = @vg.new_svg(300.0, 200.0)
    .render_rectangle(0.0, 0.0, 300.0, 200.0, @vg.white()) // White background
    .render_circle(@vg.point(150.0, 100.0), 50.0, @vg.red()) // Red circle in center
    .render_rectangle(50.0, 50.0, 200.0, 100.0, @vg.rgba(0.0, 0.0, 1.0, 0.5)) // Semi-transparent blue rect
    .render_text("Hello SVG", @vg.point(150.0, 100.0), 16.0, @vg.black()) // Centered text
  let svg_string = doc.to_string()
  it.write(svg_string)
  it.snapshot(filename="minimal_svg_test.svg")
}

///|
test "simple rendering test" (it : @test.Test) {
  // Ultra-simple SVG that should definitely render
  let doc = @vg.new_svg(100.0, 100.0).render_circle(
    @vg.point(50.0, 50.0),
    30.0,
    @vg.red(),
  )
  let svg_string = doc.to_string()
  it.write(svg_string)
  it.snapshot(filename="simple_test.svg")
}

///|
test "html wrapped svg test" (it : @test.Test) {
  // Create an HTML file with embedded SVG for testing in browsers
  let doc = @vg.new_svg(400.0, 300.0)
    .render_rectangle(0.0, 0.0, 400.0, 300.0, @vg.white())
    .render_circle(@vg.point(200.0, 150.0), 50.0, @vg.red())
    .render_rectangle(100.0, 100.0, 200.0, 100.0, @vg.rgba(0.0, 1.0, 0.0, 0.5))
    .render_text("VG Library Test", @vg.point(200.0, 50.0), 18.0, @vg.black())
    .render_line(
      @vg.point(50.0, 250.0),
      @vg.point(350.0, 250.0),
      @vg.blue(),
      3.0,
    )
  let svg_string = doc.to_string()
  let html_content = "<!DOCTYPE html>\n<html>\n<head>\n" +
    "  <title>VG Library Test</title>\n" +
    "  <style>\n" +
    "    body { font-family: Arial, sans-serif; margin: 20px; }\n" +
    "    .svg-container { border: 1px solid #ccc; margin: 10px 0; }\n" +
    "  </style>\n" +
    "</head>\n<body>\n" +
    "  <h1>MoonBit VG Library - SVG Rendering Test</h1>\n" +
    "  <div class=\"svg-container\">\n" +
    svg_string +
    "\n" +
    "  </div>\n" +
    "  <p>If you can see the red circle, green rectangle, blue line, and text above, the SVG is rendering correctly!</p>\n" +
    "</body>\n</html>"
  it.write(html_content)
  it.snapshot(filename="svg_browser_test.html")
}
