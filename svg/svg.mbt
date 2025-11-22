// SVG rendering utilities

///|
/// Create a new SVG document
pub fn new_svg(width : Double, height : Double) -> SvgDocument {
  { width, height, elements: [] }
}

///|
/// Add an element to the SVG document (OO-style)
pub fn SvgDocument::add_element(
  self : SvgDocument,
  element : String,
) -> SvgDocument {
  { ..self, elements: [..self.elements, element] }
}

///|
/// Convert a color to SVG color string
fn color_to_svg(c : @color.Color) -> String {
  if c.a < 1.0 {
    let r = (c.r * 255.0).to_int()
    let g = (c.g * 255.0).to_int()
    let b = (c.b * 255.0).to_int()
    "rgba(\{r},\{g},\{b},\{c.a})"
  } else {
    @color.to_hex(c)
  }
}

///|
/// Convert a point to SVG coordinate string
fn point_to_svg(p : @geometry.Point) -> String {
  "\{p.x},\{p.y}"
}

///|
/// Convert a path to SVG path data
fn path_to_svg_data(path : @geometry.Path) -> String {
  let mut data = ""
  for segment in path.0 {
    match segment {
      MoveTo(p) => data = data + "M \{point_to_svg(p)} "
      LineTo(p) => data = data + "L \{point_to_svg(p)} "
      CurveTo(cp1, cp2, end) =>
        data = data +
          "C \{point_to_svg(cp1)} \{point_to_svg(cp2)} \{point_to_svg(end)} "
      QCurveTo(cp, end) =>
        data = data + "Q \{point_to_svg(cp)} \{point_to_svg(end)} "
      EArcTo(rx, ry, rotation, large_arc, sweep, end) => {
        let large_flag = if large_arc { "1" } else { "0" }
        let sweep_flag = if sweep { "1" } else { "0" }
        data = data +
          "A \{rx} \{ry} \{rotation} \{large_flag} \{sweep_flag} \{point_to_svg(end)} "
      }
      Close => data = data + "Z "
    }
  }
  data
}

///|
/// Render a circle to SVG (OO-style)
pub fn SvgDocument::render_circle(
  self : SvgDocument,
  center : @geometry.Point,
  radius : Double,
  color : @color.Color,
) -> SvgDocument {
  let element =
    $|<circle cx="\{center.x}" cy="\{center.y}" r="\{radius}" fill="\{color_to_svg(color)}"/>
  self.add_element(element)
}

// ===== OBJECT-ORIENTED API METHODS =====

///|
/// Render a rectangle to SVG (OO-style)
pub fn SvgDocument::render_rectangle(
  self : SvgDocument,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  color : @color.Color,
) -> SvgDocument {
  let element =
    $|<rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" fill="\{color_to_svg(color)}"/>
  self.add_element(element)
}

///|
/// Render a path to SVG (OO-style)
pub fn SvgDocument::render_path(
  self : SvgDocument,
  path : @geometry.Path,
  color : @color.Color,
) -> SvgDocument {
  let data = path_to_svg_data(path)
  let element =
    $|<path d="\{data}" fill="\{color_to_svg(color)}" stroke="none"/>
  self.add_element(element)
}

///|
/// Render a line to SVG (OO-style)
pub fn SvgDocument::render_line(
  self : SvgDocument,
  start : @geometry.Point,
  end : @geometry.Point,
  color : @color.Color,
  thickness : Double,
) -> SvgDocument {
  let element =
    $|<line x1="\{start.x}" y1="\{start.y}" x2="\{end.x}" y2="\{end.y}" stroke="\{color_to_svg(color)}" stroke-width="\{thickness}" stroke-linecap="round" fill="none"/>
  self.add_element(element)
}

///|
/// Render text to SVG (OO-style)
pub fn SvgDocument::render_text(
  self : SvgDocument,
  text : String,
  pos : @geometry.Point,
  size : Double,
  color : @color.Color,
) -> SvgDocument {
  let element =
    $|<text x="\{pos.x}" y="\{pos.y}" font-size="\{size}" font-family="Arial, sans-serif" text-anchor="middle" dominant-baseline="central" fill="\{color_to_svg(color)}">\{text}</text>
  self.add_element(element)
}

///|
/// Render an ellipse to SVG (OO-style)
pub fn SvgDocument::render_ellipse(
  self : SvgDocument,
  center : @geometry.Point,
  rx : Double,
  ry : Double,
  color : @color.Color,
) -> SvgDocument {
  let element =
    $|<ellipse cx="\{center.x}" cy="\{center.y}" rx="\{rx}" ry="\{ry}" fill="\{color_to_svg(color)}"/>
  self.add_element(element)
}

///|
/// Render a polygon to SVG (OO-style)
pub fn SvgDocument::render_polygon(
  self : SvgDocument,
  points : Array[@geometry.Point],
  color : @color.Color,
) -> SvgDocument {
  if points.length() < 3 {
    self // Can't render polygon with less than 3 points
  } else {
    let mut points_str = ""
    for i = 0; i < points.length(); i = i + 1 {
      let p = points[i]
      points_str = points_str + "\{p.x},\{p.y}"
      if i < points.length() - 1 {
        points_str = points_str + " "
      }
    }
    let element =
      $|<polygon points="\{points_str}" fill="\{color_to_svg(color)}"/>
    self.add_element(element)
  }
}

///|
/// Render a linear gradient to SVG (OO-style)
pub fn SvgDocument::render_linear_gradient(
  self : SvgDocument,
  id : String,
  start : @geometry.Point,
  end : @geometry.Point,
  color1 : @color.Color,
  color2 : @color.Color,
) -> SvgDocument {
  let gradient =
    $|<defs><linearGradient id="\{id}" x1="\{start.x}%" y1="\{start.y}%" x2="\{end.x}%" y2="\{end.y}%"><stop offset="0%" stop-color="\{color_to_svg(color1)}"/><stop offset="100%" stop-color="\{color_to_svg(color2)}"/></linearGradient></defs>"
  self.add_element(gradient)
}

///|
/// Convert to SVG string (OO-style)
pub fn SvgDocument::to_string(self : SvgDocument) -> String {
  (
    $|<?xml version="1.0" encoding="UTF-8"?>
    $|<svg xmlns="http://www.w3.org/2000/svg" width="\{self.width}" height="\{self.height}" viewBox="0 0 \{self.width} \{self.height}">
    $|\{self.elements.map(e => "  " + e).join("\n")}
    $|</svg>
  )
}
