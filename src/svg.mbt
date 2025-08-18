// SVG rendering backend

/// SVG document structure
pub struct SvgDocument {
  width : Double
  height : Double
  elements : Array[String]
} derive(Show)

/// Create a new SVG document
pub fn new_svg(width : Double, height : Double) -> SvgDocument {
  { width, height, elements: [] }
}

/// Add an element to the SVG document (OO-style)
pub fn SvgDocument::add_element(self : SvgDocument, element : String) -> SvgDocument {
  let new_elements = Array::new()
  for elem in self.elements {
    new_elements.push(elem)
  }
  new_elements.push(element)
  { width: self.width, height: self.height, elements: new_elements }
}

/// Convert a color to SVG color string
fn color_to_svg(c : Color) -> String {
  if c.a < 1.0 {
    let r = (c.r * 255.0).to_int()
    let g = (c.g * 255.0).to_int()
    let b = (c.b * 255.0).to_int()
    "rgba(\{r},\{g},\{b},\{c.a})"
  } else {
    to_hex(c)
  }
}

/// Convert a point to SVG coordinate string
fn point_to_svg(p : Point) -> String {
  "\{p.x},\{p.y}"
}

/// Convert a path to SVG path data
fn path_to_svg_data(path : Path) -> String {
  let mut data = ""
  for segment in path.0 {
    match segment {
      MoveTo(p) => data = data + "M \{point_to_svg(p)} "
      LineTo(p) => data = data + "L \{point_to_svg(p)} "
      CurveTo(cp1, cp2, end) => 
        data = data + "C \{point_to_svg(cp1)} \{point_to_svg(cp2)} \{point_to_svg(end)} "
      QCurveTo(cp, end) =>
        data = data + "Q \{point_to_svg(cp)} \{point_to_svg(end)} "
      EArcTo(rx, ry, rotation, large_arc, sweep, end) => {
        let large_flag = if large_arc { "1" } else { "0" }
        let sweep_flag = if sweep { "1" } else { "0" }
        data = data + "A \{rx} \{ry} \{rotation} \{large_flag} \{sweep_flag} \{point_to_svg(end)} "
      }
      Close => data = data + "Z "
    }
  }
  data
}

/// Render a circle to SVG (OO-style)
pub fn SvgDocument::render_circle(self : SvgDocument, center : Point, radius : Double, color : Color) -> SvgDocument {
  let element = "<circle cx=\"\{center.x}\" cy=\"\{center.y}\" r=\"\{radius}\" fill=\"\{color_to_svg(color)}\"/>"
  self.add_element(element)
}













// ===== OBJECT-ORIENTED API METHODS =====

/// Render a rectangle to SVG (OO-style)
pub fn SvgDocument::render_rectangle(self : SvgDocument, x : Double, y : Double, width : Double, height : Double, color : Color) -> SvgDocument {
  let element = "<rect x=\"\{x}\" y=\"\{y}\" width=\"\{width}\" height=\"\{height}\" fill=\"\{color_to_svg(color)}\"/>"
  self.add_element(element)
}

/// Render a path to SVG (OO-style)
pub fn SvgDocument::render_path(self : SvgDocument, path : Path, color : Color) -> SvgDocument {
  let data = path_to_svg_data(path)
  let element = "<path d=\"\{data}\" fill=\"\{color_to_svg(color)}\" stroke=\"none\"/>"
  self.add_element(element)
}

/// Render a line to SVG (OO-style)
pub fn SvgDocument::render_line(self : SvgDocument, start : Point, end : Point, color : Color, thickness : Double) -> SvgDocument {
  let element = "<line x1=\"\{start.x}\" y1=\"\{start.y}\" x2=\"\{end.x}\" y2=\"\{end.y}\" stroke=\"\{color_to_svg(color)}\" stroke-width=\"\{thickness}\" stroke-linecap=\"round\" fill=\"none\"/>"
  self.add_element(element)
}

/// Render text to SVG (OO-style)
pub fn SvgDocument::render_text(self : SvgDocument, text : String, pos : Point, size : Double, color : Color) -> SvgDocument {
  let element = "<text x=\"\{pos.x}\" y=\"\{pos.y}\" font-size=\"\{size}\" font-family=\"Arial, sans-serif\" text-anchor=\"middle\" dominant-baseline=\"central\" fill=\"\{color_to_svg(color)}\">\{text}</text>"
  self.add_element(element)
}

/// Render an ellipse to SVG (OO-style)
pub fn SvgDocument::render_ellipse(self : SvgDocument, center : Point, rx : Double, ry : Double, color : Color) -> SvgDocument {
  let element = "<ellipse cx=\"\{center.x}\" cy=\"\{center.y}\" rx=\"\{rx}\" ry=\"\{ry}\" fill=\"\{color_to_svg(color)}\"/>"
  self.add_element(element)
}

/// Render a polygon to SVG (OO-style)
pub fn SvgDocument::render_polygon(self : SvgDocument, points : Array[Point], color : Color) -> SvgDocument {
  if points.length() < 3 {
    self  // Can't render polygon with less than 3 points
  } else {
    let mut points_str = ""
    for i = 0; i < points.length(); i = i + 1 {
      let p = points[i]
      points_str = points_str + "\{p.x},\{p.y}"
      if i < points.length() - 1 {
        points_str = points_str + " "
      }
    }
    
    let element = "<polygon points=\"\{points_str}\" fill=\"\{color_to_svg(color)}\"/>"
    self.add_element(element)
  }
}

/// Render a linear gradient to SVG (OO-style)
pub fn SvgDocument::render_linear_gradient(self : SvgDocument, id : String, start : Point, end : Point, color1 : Color, color2 : Color) -> SvgDocument {
  let gradient = "<defs><linearGradient id=\"\{id}\" x1=\"\{start.x}%\" y1=\"\{start.y}%\" x2=\"\{end.x}%\" y2=\"\{end.y}%\"><stop offset=\"0%\" stop-color=\"\{color_to_svg(color1)}\"/><stop offset=\"100%\" stop-color=\"\{color_to_svg(color2)}\"/></linearGradient></defs>"
  self.add_element(gradient)
}

/// Convert to SVG string (OO-style)
pub fn SvgDocument::to_string(self : SvgDocument) -> String {
  let mut svg = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
  svg = svg + "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\{self.width}\" height=\"\{self.height}\" viewBox=\"0 0 \{self.width} \{self.height}\">\n"
  
  for element in self.elements {
    svg = svg + "  \{element}\n"
  }
  
  svg = svg + "</svg>"
  svg
}

// ===== BACKWARD COMPATIBILITY WRAPPERS =====

/// Add an element to the SVG document (functional-style wrapper)
pub fn add_element(doc : SvgDocument, element : String) -> SvgDocument {
  doc.add_element(element)
}

/// Render a circle to SVG (functional-style wrapper)
pub fn render_circle(doc : SvgDocument, center : Point, radius : Double, color : Color) -> SvgDocument {
  doc.render_circle(center, radius, color)
}

/// Render a rectangle to SVG (functional-style wrapper)
pub fn render_rectangle(doc : SvgDocument, x : Double, y : Double, width : Double, height : Double, color : Color) -> SvgDocument {
  doc.render_rectangle(x, y, width, height, color)
}

/// Render a path to SVG (functional-style wrapper)
pub fn render_path(doc : SvgDocument, path : Path, color : Color) -> SvgDocument {
  doc.render_path(path, color)
}

/// Render a line to SVG (functional-style wrapper)
pub fn render_line(doc : SvgDocument, start : Point, end : Point, color : Color, thickness : Double) -> SvgDocument {
  doc.render_line(start, end, color, thickness)
}

/// Render text to SVG (functional-style wrapper)
pub fn render_text(doc : SvgDocument, text : String, pos : Point, size : Double, color : Color) -> SvgDocument {
  doc.render_text(text, pos, size, color)
}

/// Render an ellipse to SVG (functional-style wrapper)
pub fn render_ellipse(doc : SvgDocument, center : Point, rx : Double, ry : Double, color : Color) -> SvgDocument {
  doc.render_ellipse(center, rx, ry, color)
}

/// Render a polygon to SVG (functional-style wrapper)
pub fn render_polygon(doc : SvgDocument, points : Array[Point], color : Color) -> SvgDocument {
  doc.render_polygon(points, color)
}

/// Render a linear gradient to SVG (functional-style wrapper)
pub fn render_linear_gradient(doc : SvgDocument, id : String, start : Point, end : Point, color1 : Color, color2 : Color) -> SvgDocument {
  doc.render_linear_gradient(id, start, end, color1, color2)
}

/// Convert SVG document to string (functional-style wrapper)
pub fn to_svg_string(doc : SvgDocument) -> String {
  doc.to_string()
}

/// Sample an image at regular intervals and render to SVG
pub fn render_image_to_svg(img : Image, width : Double, height : Double, samples : Int) -> String {
  let mut doc = new_svg(width, height)
  let step = width / samples.to_double()
  
  for i in 0..<samples {
    for j in 0..<samples {
      let x = i.to_double() * step
      let y = j.to_double() * step
      let p = point(x - width / 2.0, y - height / 2.0)  // Center coordinate system
      let color = img(p)
      
      if color.a > 0.0 {  // Only render non-transparent pixels
        doc = doc.render_rectangle(x, y, step, step, color)
      }
    }
  }
  
  doc.to_string()
}


