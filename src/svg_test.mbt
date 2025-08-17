// Tests for SVG rendering

test "SVG document creation" {
  let doc = @vg.new_svg(100.0, 200.0)
  
  if doc.width != 100.0 || doc.height != 200.0 {
    fail("SVG document dimensions incorrect")
  }
  
  if doc.elements.length() != 0 {
    fail("New SVG document should have no elements")
  }
}

test "adding elements to SVG" {
  let doc = @vg.new_svg(100.0, 100.0)
    |> @vg.add_element("<circle cx=\"50\" cy=\"50\" r=\"25\"/>")
    |> @vg.add_element("<rect x=\"10\" y=\"10\" width=\"30\" height=\"20\"/>")
  
  if doc.elements.length() != 2 {
    fail("SVG document should have 2 elements")
  }
}

test "circle rendering" {
  let doc = @vg.new_svg(100.0, 100.0)
    |> @vg.render_circle(@vg.point(50.0, 50.0), 25.0, @vg.red())
  
  inspect(doc, content=(
    #|{width: 100, height: 100, elements: ["<circle cx=\"50\" cy=\"50\" r=\"25\" fill=\"#FF0000\"/>"]}
  ))
}

test "rectangle rendering" {
  let doc = @vg.new_svg(200.0, 150.0)
    |> @vg.render_rectangle(10.0, 20.0, 50.0, 30.0, @vg.blue())
  
  if doc.elements.length() != 1 {
    fail("Should have one rectangle element")
  }
  
  let element = doc.elements[0]
  if not(element.contains("rect")) || not(element.contains("x=\"10\"")) {
    fail("Rectangle element should contain correct attributes")
  }
}

test "path rendering" {
  let path = @vg.Path::rect(0.0, 0.0, 10.0, 10.0)
  let doc = @vg.new_svg(100.0, 100.0)
    |> @vg.render_path(path, @vg.green())
  
  if doc.elements.length() != 1 {
    fail("Should have one path element")
  }
  
  let element = doc.elements[0]
  if not(element.contains("path")) || not(element.contains("d=\"")) {
    fail("Path element should contain path data")
  }
}

test "line rendering" {
  let start = @vg.point(0.0, 0.0)
  let end = @vg.point(100.0, 50.0)
  let doc = @vg.new_svg(150.0, 100.0)
    |> @vg.render_line(start, end, @vg.black(), 2.0)
  
  if doc.elements.length() != 1 {
    fail("Should have one line element")
  }
  
  let element = doc.elements[0]
  if not(element.contains("line")) || not(element.contains("x1=\"0\"")) {
    fail("Line element should contain correct coordinates")
  }
}

test "text rendering" {
  let doc = @vg.new_svg(200.0, 100.0)
    |> @vg.render_text("Hello World", @vg.point(50.0, 30.0), 16.0, @vg.black())
  
  if doc.elements.length() != 1 {
    fail("Should have one text element")
  }
  
  let element = doc.elements[0]
  if not(element.contains("text")) || not(element.contains("Hello World")) {
    fail("Text element should contain the text content")
  }
}

test "SVG string generation" {
  let doc = @vg.new_svg(100.0, 100.0)
    |> @vg.render_circle(@vg.point(50.0, 50.0), 25.0, @vg.red())
  
  let svg_string = @vg.to_svg_string(doc)
  
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

test "complex SVG document" {
  let doc = @vg.new_svg(200.0, 200.0)
    |> @vg.render_rectangle(10.0, 10.0, 180.0, 180.0, @vg.gray(0.9))
    |> @vg.render_circle(@vg.point(100.0, 100.0), 50.0, @vg.red())
    |> @vg.render_line(@vg.point(50.0, 50.0), @vg.point(150.0, 150.0), @vg.blue(), 3.0)
    |> @vg.render_text("Test", @vg.point(100.0, 180.0), 14.0, @vg.black())
  
  if doc.elements.length() != 4 {
    fail("Complex document should have 4 elements")
  }
  
  let svg_string = @vg.to_svg_string(doc)
  if not(svg_string.contains("rect")) || not(svg_string.contains("circle")) ||
     not(svg_string.contains("line")) || not(svg_string.contains("text")) {
    fail("Complex SVG should contain all element types")
  }
}

test "image to SVG rendering" {
  let img = @vg.circle(@vg.red(), 25.0)
  let svg_string = @vg.render_image_to_svg(img, 100.0, 100.0, 20)
  
  if not(svg_string.contains("svg")) {
    fail("Image rendering should produce valid SVG")
  }
  
  if not(svg_string.contains("rect")) {
    fail("Image rendering should contain rectangle elements for pixels")
  }
}

test "color with alpha in SVG" {
  let semi_transparent = rgba(1.0, 0.0, 0.0, 0.5)
  let doc = new_svg(100.0, 100.0)
    |> render_circle(point(50.0, 50.0), 25.0, semi_transparent)
  
  inspect(doc, content=(
    #|{width: 100, height: 100, elements: ["<circle cx=\"50\" cy=\"50\" r=\"25\" fill=\"rgba(255,0,0,0.5)\"/>"]}
  ))
}

test "comprehensive svg rendering" {
  let complex_doc = @vg.new_svg(300.0, 200.0)
    |> @vg.render_rectangle(10.0, 10.0, 280.0, 180.0, @vg.gray(0.95))  // Background
    |> @vg.render_circle(@vg.point(80.0, 60.0), 30.0, @vg.red())       // Red circle
    |> @vg.render_ellipse(@vg.point(150.0, 60.0), 25.0, 15.0, @vg.blue()) // Blue ellipse
    |> @vg.render_rectangle(200.0, 30.0, 40.0, 60.0, @vg.green())      // Green rectangle
    |> @vg.render_line(@vg.point(20.0, 120.0), @vg.point(280.0, 120.0), @vg.black(), 2.0) // Divider line
    |> @vg.render_text("VG Graphics Demo", @vg.point(150.0, 150.0), 16.0, @vg.purple()) // Title text
  
  inspect(complex_doc, content=(
    #|{width: 300, height: 200, elements: ["<rect x=\"10\" y=\"10\" width=\"280\" height=\"180\" fill=\"#F2F2F2\"/>", "<circle cx=\"80\" cy=\"60\" r=\"30\" fill=\"#FF0000\"/>", "<ellipse cx=\"150\" cy=\"60\" rx=\"25\" ry=\"15\" fill=\"#0000FF\"/>", "<rect x=\"200\" y=\"30\" width=\"40\" height=\"60\" fill=\"#00FF00\"/>", "<line x1=\"20\" y1=\"120\" x2=\"280\" y2=\"120\" stroke=\"#000000\" stroke-width=\"2\"/>", "<text x=\"150\" y=\"150\" font-size=\"16\" fill=\"#7F007F\">VG Graphics Demo</text>"]}
  ))
}

test "svg string generation" {
  let doc = @vg.new_svg(100.0, 100.0)
    |> @vg.render_circle(@vg.point(50.0, 50.0), 25.0, @vg.red())
  
  let svg_string = @vg.to_svg_string(doc)
  inspect(svg_string, content=(
    #|<?xml version="1.0" encoding="UTF-8"?>
    #|<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">
    #|  <circle cx="50" cy="50" r="25" fill="#FF0000"/>
    #|</svg>
  ))
}

test "path rendering to svg" {
  let custom_path = @vg.Path::empty()
    .move_to(@vg.point(10.0, 10.0))
    .line_to(@vg.point(90.0, 10.0))
    .curve_to(@vg.point(110.0, 10.0), @vg.point(110.0, 30.0), @vg.point(90.0, 30.0))
    .line_to(@vg.point(10.0, 30.0))
    .close_path()
  
  let doc = @vg.new_svg(120.0, 50.0)
    |> @vg.render_path(custom_path, @vg.magenta())
  
  inspect(doc, content=(
    #|{width: 120, height: 50, elements: ["<path d=\"M 10,10 L 90,10 C 110,10 110,30 90,30 L 10,30 Z \" fill=\"#FF00FF\"/>"]}
  ))
}
