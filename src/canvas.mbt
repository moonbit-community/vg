// HTML5 Canvas rendering backend

/// Canvas document structure for JavaScript generation
pub struct CanvasDocument {
  width : Double
  height : Double
  commands : Array[String]
} derive(Show)

/// Create a new Canvas document
pub fn new_canvas(width : Double, height : Double) -> CanvasDocument {
  { width, height, commands: [] }
}



/// Convert a color to Canvas color string
fn color_to_canvas(c : Color) -> String {
  if c.a < 1.0 {
    let r = (c.r * 255.0).to_int()
    let g = (c.g * 255.0).to_int()
    let b = (c.b * 255.0).to_int()
    "rgba(" + r.to_string() + "," + g.to_string() + "," + b.to_string() + "," + c.a.to_string() + ")"
  } else {
    to_hex(c)
  }
}









/// Convert a path to Canvas commands
fn path_to_canvas_commands(path : Path) -> Array[String] {
  let commands = Array::new()
  commands.push("ctx.beginPath();")
  
  for segment in path.0 {
    match segment {
      MoveTo(p) => commands.push("ctx.moveTo(" + p.x.to_string() + ", " + p.y.to_string() + ");")
      LineTo(p) => commands.push("ctx.lineTo(" + p.x.to_string() + ", " + p.y.to_string() + ");")
      CurveTo(cp1, cp2, end) => 
        commands.push("ctx.bezierCurveTo(" + cp1.x.to_string() + ", " + cp1.y.to_string() + ", " + 
                     cp2.x.to_string() + ", " + cp2.y.to_string() + ", " + 
                     end.x.to_string() + ", " + end.y.to_string() + ");")
      QCurveTo(cp, end) =>
        commands.push("ctx.quadraticCurveTo(" + cp.x.to_string() + ", " + cp.y.to_string() + ", " + 
                     end.x.to_string() + ", " + end.y.to_string() + ");")
      EArcTo(rx, ry, rotation, large_arc, sweep, end) => {
        // Canvas doesn't have native elliptical arcs, approximate with arc and transformations
        commands.push("// Elliptical arc: rx=" + rx.to_string() + " ry=" + ry.to_string() + 
                     " rotation=" + rotation.to_string() + " large=" + large_arc.to_string() + 
                     " sweep=" + sweep.to_string())
        commands.push("ctx.save();")
        commands.push("ctx.scale(" + (rx / ry).to_string() + ", 1);")
        commands.push("ctx.arc(" + (end.x / (rx / ry)).to_string() + ", " + end.y.to_string() + 
                     ", " + ry.to_string() + ", 0, " + (if sweep { "Math.PI" } else { "-Math.PI" }) + ");")
        commands.push("ctx.restore();")
      }
      Close => commands.push("ctx.closePath();")
    }
  }
  
  commands
}







// ===== OBJECT-ORIENTED API METHODS =====

/// Add a command to the Canvas document (OO-style)
pub fn CanvasDocument::add_command(self : CanvasDocument, command : String) -> CanvasDocument {
  let new_commands = Array::new()
  for cmd in self.commands {
    new_commands.push(cmd)
  }
  new_commands.push(command)
  { width: self.width, height: self.height, commands: new_commands }
}

/// Render a circle to Canvas (OO-style)
pub fn CanvasDocument::render_circle(self : CanvasDocument, center : Point, radius : Double, color : Color) -> CanvasDocument {
  let commands = [
    "ctx.beginPath();",
    "ctx.arc(" + center.x.to_string() + ", " + center.y.to_string() + ", " + radius.to_string() + ", 0, 2 * Math.PI);",
    "ctx.fillStyle = '" + color_to_canvas(color) + "';",
    "ctx.fill();"
  ]
  
  let mut result = self
  for cmd in commands {
    result = result.add_command(cmd)
  }
  result
}

/// Render a rectangle to Canvas (OO-style)
pub fn CanvasDocument::render_rectangle(self : CanvasDocument, x : Double, y : Double, width : Double, height : Double, color : Color) -> CanvasDocument {
  let commands = [
    "ctx.fillStyle = '" + color_to_canvas(color) + "';",
    "ctx.fillRect(" + x.to_string() + ", " + y.to_string() + ", " + width.to_string() + ", " + height.to_string() + ");"
  ]
  
  let mut result = self
  for cmd in commands {
    result = result.add_command(cmd)
  }
  result
}

/// Render a line to Canvas (OO-style)
pub fn CanvasDocument::render_line(self : CanvasDocument, start : Point, end : Point, color : Color, thickness : Double) -> CanvasDocument {
  let commands = [
    "ctx.beginPath();",
    "ctx.moveTo(" + start.x.to_string() + ", " + start.y.to_string() + ");",
    "ctx.lineTo(" + end.x.to_string() + ", " + end.y.to_string() + ");",
    "ctx.strokeStyle = '" + color_to_canvas(color) + "';",
    "ctx.lineWidth = " + thickness.to_string() + ";",
    "ctx.lineCap = 'round';",
    "ctx.stroke();"
  ]
  
  let mut result = self
  for cmd in commands {
    result = result.add_command(cmd)
  }
  result
}

/// Render text to Canvas (OO-style)
pub fn CanvasDocument::render_text(self : CanvasDocument, text : String, pos : Point, size : Double, color : Color) -> CanvasDocument {
  let commands = [
    "ctx.font = '" + size.to_string() + "px Arial, sans-serif';",
    "ctx.fillStyle = '" + color_to_canvas(color) + "';",
    "ctx.textAlign = 'center';",
    "ctx.textBaseline = 'middle';",
    "ctx.fillText('" + text + "', " + pos.x.to_string() + ", " + pos.y.to_string() + ");"
  ]
  
  let mut result = self
  for cmd in commands {
    result = result.add_command(cmd)
  }
  result
}

/// Render a path to Canvas (OO-style)
pub fn CanvasDocument::render_path(self : CanvasDocument, path : Path, color : Color) -> CanvasDocument {
  let path_commands = path_to_canvas_commands(path)
  let fill_commands = [
    "ctx.fillStyle = '" + color_to_canvas(color) + "';",
    "ctx.fill();"
  ]
  
  let mut result = self
  for cmd in path_commands {
    result = result.add_command(cmd)
  }
  for cmd in fill_commands {
    result = result.add_command(cmd)
  }
  result
}

/// Convert to JavaScript (OO-style)
pub fn CanvasDocument::to_js(self : CanvasDocument) -> String {
  let mut js = "// Generated Canvas JavaScript\n"
  js = js + "function drawVgGraphics(canvas) {\n"
  js = js + "  const ctx = canvas.getContext('2d');\n"
  js = js + "  canvas.width = " + self.width.to_string() + ";\n"
  js = js + "  canvas.height = " + self.height.to_string() + ";\n"
  js = js + "  \n"
  js = js + "  // Clear canvas\n"
  js = js + "  ctx.clearRect(0, 0, canvas.width, canvas.height);\n"
  js = js + "  \n"
  js = js + "  // Drawing commands\n"
  
  for command in self.commands {
    js = js + "  " + command + "\n"
  }
  
  js = js + "}\n"
  js = js + "\n// Usage: drawVgGraphics(document.getElementById('myCanvas'));"
  js
}

/// Convert to HTML (OO-style)
pub fn CanvasDocument::to_html(self : CanvasDocument, title : String) -> String {
  let js_code = self.to_js()
  
  "<!DOCTYPE html>\n<html>\n<head>\n" +
  "  <title>" + title + "</title>\n" +
  "  <style>\n" +
  "    body { font-family: Arial, sans-serif; margin: 20px; text-align: center; }\n" +
  "    canvas { border: 1px solid #ccc; margin: 10px; }\n" +
  "  </style>\n" +
  "</head>\n<body>\n" +
  "  <h1>" + title + "</h1>\n" +
  "  <canvas id=\"vgCanvas\"></canvas>\n" +
  "  <script>\n" +
  js_code + "\n" +
  "    drawVgGraphics(document.getElementById('vgCanvas'));\n" +
  "  </script>\n" +
  "</body>\n</html>"
}

// ===== BACKWARD COMPATIBILITY WRAPPERS =====

/// Add a command to the Canvas document (functional-style wrapper)
pub fn add_canvas_command(doc : CanvasDocument, command : String) -> CanvasDocument {
  doc.add_command(command)
}

/// Render a circle to Canvas (functional-style wrapper)
pub fn render_canvas_circle(doc : CanvasDocument, center : Point, radius : Double, color : Color) -> CanvasDocument {
  doc.render_circle(center, radius, color)
}

/// Render a rectangle to Canvas (functional-style wrapper)
pub fn render_canvas_rectangle(doc : CanvasDocument, x : Double, y : Double, width : Double, height : Double, color : Color) -> CanvasDocument {
  doc.render_rectangle(x, y, width, height, color)
}

/// Render a line to Canvas (functional-style wrapper)
pub fn render_canvas_line(doc : CanvasDocument, start : Point, end : Point, color : Color, thickness : Double) -> CanvasDocument {
  doc.render_line(start, end, color, thickness)
}

/// Render text to Canvas (functional-style wrapper)
pub fn render_canvas_text(doc : CanvasDocument, text : String, pos : Point, size : Double, color : Color) -> CanvasDocument {
  doc.render_text(text, pos, size, color)
}

/// Render a path to Canvas (functional-style wrapper)
pub fn render_canvas_path(doc : CanvasDocument, path : Path, color : Color) -> CanvasDocument {
  doc.render_path(path, color)
}

/// Convert to JavaScript (functional-style wrapper)
pub fn to_canvas_js(doc : CanvasDocument) -> String {
  doc.to_js()
}

/// Convert to HTML (functional-style wrapper)
pub fn to_canvas_html(doc : CanvasDocument, title : String) -> String {
  doc.to_html(title)
}
