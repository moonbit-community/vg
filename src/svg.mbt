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

/// Add an element to the SVG document
pub fn add_element(doc : SvgDocument, element : String) -> SvgDocument {
  let new_elements = Array::new()
  for elem in doc.elements {
    new_elements.push(elem)
  }
  new_elements.push(element)
  { width: doc.width, height: doc.height, elements: new_elements }
}

/// Convert a color to SVG color string
fn color_to_svg(c : Color) -> String {
  if c.a < 1.0 {
    let r = (c.r * 255.0).to_int()
    let g = (c.g * 255.0).to_int()
    let b = (c.b * 255.0).to_int()
    "rgba(" + r.to_string() + "," + g.to_string() + "," + b.to_string() + "," + c.a.to_string() + ")"
  } else {
    to_hex(c)
  }
}

/// Convert a point to SVG coordinate string
fn point_to_svg(p : Point) -> String {
  p.x.to_string() + "," + p.y.to_string()
}

/// Convert a path to SVG path data
fn path_to_svg_data(path : Path) -> String {
  let mut data = ""
  for segment in path.0 {
    match segment {
      MoveTo(p) => data = data + "M " + point_to_svg(p) + " "
      LineTo(p) => data = data + "L " + point_to_svg(p) + " "
      CurveTo(cp1, cp2, end) => 
        data = data + "C " + point_to_svg(cp1) + " " + point_to_svg(cp2) + " " + point_to_svg(end) + " "
      Close => data = data + "Z "
    }
  }
  data
}

/// Render a circle to SVG
pub fn render_circle(doc : SvgDocument, center : Point, radius : Double, color : Color) -> SvgDocument {
  let element = "<circle cx=\"" + center.x.to_string() + "\" cy=\"" + center.y.to_string() + 
                "\" r=\"" + radius.to_string() + "\" fill=\"" + color_to_svg(color) + "\"/>"
  add_element(doc, element)
}

/// Render a rectangle to SVG
pub fn render_rectangle(doc : SvgDocument, x : Double, y : Double, width : Double, height : Double, color : Color) -> SvgDocument {
  let element = "<rect x=\"" + x.to_string() + "\" y=\"" + y.to_string() + 
                "\" width=\"" + width.to_string() + "\" height=\"" + height.to_string() + 
                "\" fill=\"" + color_to_svg(color) + "\"/>"
  add_element(doc, element)
}

/// Render a path to SVG
pub fn render_path(doc : SvgDocument, path : Path, color : Color) -> SvgDocument {
  let data = path_to_svg_data(path)
  let element = "<path d=\"" + data + "\" fill=\"" + color_to_svg(color) + "\"/>"
  add_element(doc, element)
}

/// Render a line to SVG
pub fn render_line(doc : SvgDocument, start : Point, end : Point, color : Color, thickness : Double) -> SvgDocument {
  let element = "<line x1=\"" + start.x.to_string() + "\" y1=\"" + start.y.to_string() + 
                "\" x2=\"" + end.x.to_string() + "\" y2=\"" + end.y.to_string() + 
                "\" stroke=\"" + color_to_svg(color) + "\" stroke-width=\"" + thickness.to_string() + "\"/>"
  add_element(doc, element)
}

/// Render text to SVG
pub fn render_text(doc : SvgDocument, text : String, pos : Point, size : Double, color : Color) -> SvgDocument {
  let element = "<text x=\"" + pos.x.to_string() + "\" y=\"" + pos.y.to_string() + 
                "\" font-size=\"" + size.to_string() + "\" fill=\"" + color_to_svg(color) + "\">" + 
                text + "</text>"
  add_element(doc, element)
}

/// Render a linear gradient definition
pub fn render_linear_gradient(doc : SvgDocument, id : String, start : Point, end : Point, color1 : Color, color2 : Color) -> SvgDocument {
  let gradient = "<defs><linearGradient id=\"" + id + "\" x1=\"" + start.x.to_string() + "%\" y1=\"" + start.y.to_string() + 
                 "%\" x2=\"" + end.x.to_string() + "%\" y2=\"" + end.y.to_string() + "%\">" +
                 "<stop offset=\"0%\" stop-color=\"" + color_to_svg(color1) + "\"/>" +
                 "<stop offset=\"100%\" stop-color=\"" + color_to_svg(color2) + "\"/>" +
                 "</linearGradient></defs>"
  add_element(doc, gradient)
}

/// Convert SVG document to string
pub fn to_svg_string(doc : SvgDocument) -> String {
  let mut svg = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
  svg = svg + "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"" + doc.width.to_string() + 
        "\" height=\"" + doc.height.to_string() + "\" viewBox=\"0 0 " + doc.width.to_string() + 
        " " + doc.height.to_string() + "\">\n"
  
  for element in doc.elements {
    svg = svg + "  " + element + "\n"
  }
  
  svg = svg + "</svg>"
  svg
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
        doc = render_rectangle(doc, x, y, step, step, color)
      }
    }
  }
  
  to_svg_string(doc)
}

/// Render an ellipse to SVG
pub fn render_ellipse(doc : SvgDocument, center : Point, rx : Double, ry : Double, color : Color) -> SvgDocument {
  let element = "<ellipse cx=\"" + center.x.to_string() + "\" cy=\"" + center.y.to_string() + 
                "\" rx=\"" + rx.to_string() + "\" ry=\"" + ry.to_string() + 
                "\" fill=\"" + color_to_svg(color) + "\"/>"
  add_element(doc, element)
}

/// Render a polygon to SVG
pub fn render_polygon(doc : SvgDocument, points : Array[Point], color : Color) -> SvgDocument {
  if points.length() < 3 {
    doc  // Can't render polygon with less than 3 points
  } else {
    let mut points_str = ""
    for i = 0; i < points.length(); i = i + 1 {
      let p = points[i]
      points_str = points_str + p.x.to_string() + "," + p.y.to_string()
      if i < points.length() - 1 {
        points_str = points_str + " "
      }
    }
    
    let element = "<polygon points=\"" + points_str + "\" fill=\"" + color_to_svg(color) + "\"/>"
    add_element(doc, element)
  }
}
