// HTML5 Canvas rendering backend

///| Canvas document structure for JavaScript generation
pub struct CanvasDocument {
  width : Double
  height : Double
  commands : Array[String]
} derive(Show)

///| Create a new Canvas document
pub fn new_canvas(width : Double, height : Double) -> CanvasDocument {
  { width, height, commands: [] }
}

///| Convert a color to Canvas color string
fn color_to_canvas(c : Color) -> String {
  if c.a < 1.0 {
    let r = (c.r * 255.0).to_int()
    let g = (c.g * 255.0).to_int()
    let b = (c.b * 255.0).to_int()
    "rgba(\{r},\{g},\{b},\{c.a})"
  } else {
    to_hex(c)
  }
}

///| Convert a path to Canvas commands
fn path_to_canvas_commands(path : Path) -> Array[String] {
  let commands = Array::new()
  commands.push("ctx.beginPath();")
  for segment in path.0 {
    match segment {
      MoveTo(p) => commands.push("ctx.moveTo(\{p.x}, \{p.y});")
      LineTo(p) => commands.push("ctx.lineTo(\{p.x}, \{p.y});")
      CurveTo(cp1, cp2, end) =>
        commands.push(
          "ctx.bezierCurveTo(\{cp1.x}, \{cp1.y}, \{cp2.x}, \{cp2.y}, \{end.x}, \{end.y});",
        )
      QCurveTo(cp, end) =>
        commands.push(
          "ctx.quadraticCurveTo(\{cp.x}, \{cp.y}, \{end.x}, \{end.y});",
        )
      EArcTo(rx, ry, rotation, large_arc, sweep, end) => {
        // Canvas doesn't have native elliptical arcs, approximate with arc and transformations
        commands.push(
          "// Elliptical arc: rx=" +
          rx.to_string() +
          " ry=" +
          ry.to_string() +
          " rotation=\{rotation} large=\{large_arc} sweep=\{sweep}",
        )
        commands.push("ctx.save();")
        commands.push("ctx.scale(\{rx / ry}, 1);")
        let sweep_angle = if sweep { "Math.PI" } else { "-Math.PI" }
        commands.push(
          "ctx.arc(\{end.x / (rx / ry)}, \{end.y}, \{ry}, 0, \{sweep_angle});",
        )
        commands.push("ctx.restore();")
      }
      Close => commands.push("ctx.closePath();")
    }
  }
  commands
}

// ===== OBJECT-ORIENTED API METHODS =====

///| Add a command to the Canvas document (OO-style)
pub fn CanvasDocument::add_command(
  self : CanvasDocument,
  command : String,
) -> CanvasDocument {
  let new_commands = Array::new()
  for cmd in self.commands {
    new_commands.push(cmd)
  }
  new_commands.push(command)
  { width: self.width, height: self.height, commands: new_commands }
}

///| Render a circle to Canvas (OO-style)
pub fn CanvasDocument::render_circle(
  self : CanvasDocument,
  center : Point,
  radius : Double,
  color : Color,
) -> CanvasDocument {
  let commands = [
    "ctx.beginPath();",
    "ctx.arc(\{center.x}, \{center.y}, \{radius}, 0, 2 * Math.PI);",
    "ctx.fillStyle = '\{color_to_canvas(color)}';",
    "ctx.fill();",
  ]
  let mut result = self
  for cmd in commands {
    result = result.add_command(cmd)
  }
  result
}

///| Render a rectangle to Canvas (OO-style)
pub fn CanvasDocument::render_rectangle(
  self : CanvasDocument,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  color : Color,
) -> CanvasDocument {
  let commands = [
    "ctx.fillStyle = '\{color_to_canvas(color)}';",
    "ctx.fillRect(\{x}, \{y}, \{width}, \{height});",
  ]
  let mut result = self
  for cmd in commands {
    result = result.add_command(cmd)
  }
  result
}

///| Render a line to Canvas (OO-style)
pub fn CanvasDocument::render_line(
  self : CanvasDocument,
  start : Point,
  end : Point,
  color : Color,
  thickness : Double,
) -> CanvasDocument {
  let commands = [
    "ctx.beginPath();",
    "ctx.moveTo(\{start.x}, \{start.y});",
    "ctx.lineTo(\{end.x}, \{end.y});",
    "ctx.strokeStyle = '\{color_to_canvas(color)}';",
    "ctx.lineWidth = \{thickness};",
    "ctx.lineCap = 'round';",
    "ctx.stroke();",
  ]
  let mut result = self
  for cmd in commands {
    result = result.add_command(cmd)
  }
  result
}

///| Render text to Canvas (OO-style)
pub fn CanvasDocument::render_text(
  self : CanvasDocument,
  text : String,
  pos : Point,
  size : Double,
  color : Color,
) -> CanvasDocument {
  let commands = [
    "ctx.font = '\{size}px Arial, sans-serif';",
    "ctx.fillStyle = '\{color_to_canvas(color)}';",
    "ctx.textAlign = 'center';",
    "ctx.textBaseline = 'middle';",
    "ctx.fillText('\{text}', \{pos.x}, \{pos.y});",
  ]
  let mut result = self
  for cmd in commands {
    result = result.add_command(cmd)
  }
  result
}

///| Render a path to Canvas (OO-style)
pub fn CanvasDocument::render_path(
  self : CanvasDocument,
  path : Path,
  color : Color,
) -> CanvasDocument {
  let path_commands = path_to_canvas_commands(path)
  let fill_commands = [
    "ctx.fillStyle = '\{color_to_canvas(color)}';",
    "ctx.fill();",
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

///| Convert to JavaScript (OO-style)
pub fn CanvasDocument::to_js(self : CanvasDocument) -> String {
  let mut js = "// Generated Canvas JavaScript\n"
  js = js + "function drawVgGraphics(canvas) {\n"
  js = js + "  const ctx = canvas.getContext('2d');\n"
  js = js + "  canvas.width = \{self.width};\n"
  js = js + "  canvas.height = \{self.height};\n"
  js = js + "  \n"
  js = js + "  // Clear canvas\n"
  js = js + "  ctx.clearRect(0, 0, canvas.width, canvas.height);\n"
  js = js + "  \n"
  js = js + "  // Drawing commands\n"
  for command in self.commands {
    js = js + "  \{command}\n"
  }
  js = js + "}\n"
  js = js + "\n// Usage: drawVgGraphics(document.getElementById('myCanvas'));"
  js
}

///| Convert to HTML (OO-style)
pub fn CanvasDocument::to_html(self : CanvasDocument, title : String) -> String {
  let js_code = self.to_js()
  "<!DOCTYPE html>\n<html>\n<head>\n  <title>\{title}</title>\n  <style>\n    body { font-family: Arial, sans-serif; margin: 20px; text-align: center; }\n    canvas { border: 1px solid #ccc; margin: 10px; }\n  </style>\n</head>\n<body>\n  <h1>\{title}</h1>\n  <canvas id=\"vgCanvas\"></canvas>\n  <script>\n\{js_code}\n    drawVgGraphics(document.getElementById('vgCanvas'));\n  </script>\n</body>\n</html>"
}
