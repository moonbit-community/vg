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
  
  if doc.elements.length() != 1 {
    fail("Should have one circle element")
  }
  
  let element = doc.elements[0]
  if not(element.contains("circle")) || not(element.contains("cx=\"50\"")) {
    fail("Circle element should contain correct attributes")
  }
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
  
  let element = doc.elements[0]
  if not(element.contains("rgba")) {
    fail("Semi-transparent color should use rgba format")
  }
}
