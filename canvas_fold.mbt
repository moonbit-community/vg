// Canvas backend: interpret the backend-neutral `DrawCmd` list (see draw.mbt)
// into HTML5 Canvas `ctx.*` JavaScript. Shares the AST fold with SVG/PDF.
//
// Canvas is y-down like the baked draw list (no flip), and supports gradients
// and per-region clipping/alpha natively, so it is the most faithful backend.

///|
/// Render the image to Canvas-drawing JavaScript for the given size.
pub fn Image::to_js(self : Image, width : Double, height : Double) -> String {
  let js : Array[String] = []
  let id = [0] // gradient variable counter
  for cmd in self.to_draw_list(width, height) {
    canvas_cmd(cmd, width, height, js, id)
  }
  let mut doc = @canvas.new_canvas(width, height)
  for c in js {
    doc = doc.add_command(c)
  }
  doc.to_js()
}

///|
fn canvas_cmd(
  cmd : DrawCmd,
  width : Double,
  height : Double,
  js : Array[String],
  id : Array[Int],
) -> Unit {
  match cmd {
    FillPath(path, paint, area) => {
      canvas_path(path, js)
      match area {
        Outline(w) => {
          canvas_set_paint(paint, "strokeStyle", js, id)
          js.push("ctx.lineWidth = \{w};")
          js.push("ctx.lineCap = 'round';")
          js.push("ctx.lineJoin = 'round';")
          js.push("ctx.stroke();")
        }
        _ => {
          canvas_set_paint(paint, "fillStyle", js, id)
          js.push("ctx.fill('\{canvas_rule(area)}');")
        }
      }
    }
    FillViewport(paint) => {
      canvas_set_paint(paint, "fillStyle", js, id)
      js.push("ctx.fillRect(0, 0, \{width}, \{height});")
    }
    RasterCell(x, y, w, h, c) => {
      js.push("ctx.fillStyle = '\{canvas_color(c)}';")
      js.push("ctx.fillRect(\{x}, \{y}, \{w}, \{h});")
    }
    PushClip(path, area) => {
      js.push("ctx.save();")
      canvas_path(path, js)
      js.push("ctx.clip('\{canvas_rule(area)}');")
    }
    PopClip => js.push("ctx.restore();")
    PushOpacity(a) => {
      js.push("ctx.save();")
      js.push("ctx.globalAlpha = \{a};")
    }
    PopOpacity => js.push("ctx.restore();")
    DrawText(content, x, y, size, color) => {
      js.push("ctx.font = '\{size}px Arial, sans-serif';")
      js.push("ctx.fillStyle = '\{canvas_color(color)}';")
      js.push("ctx.textAlign = 'center';")
      js.push("ctx.textBaseline = 'middle';")
      js.push("ctx.fillText('\{js_text_escape(content)}', \{x}, \{y});")
    }
  }
}

///|
/// Escape a string for a single-quoted JavaScript literal.
fn js_text_escape(s : String) -> String {
  let parts : Array[String] = []
  for ch in s {
    parts.push(
      match ch {
        '\\' => "\\\\"
        '\'' => "\\'"
        _ => ch.to_string()
      },
    )
  }
  parts.join("")
}

///|
fn canvas_rule(area : Area) -> String {
  match area {
    Anz => "nonzero"
    Aeo => "evenodd"
    Outline(_) => "nonzero" // strokes are handled before canvas_rule
  }
}

///|
/// Set `ctx.<prop>` ("fillStyle" or "strokeStyle") from a paint, creating a
/// gradient object if needed.
fn canvas_set_paint(
  paint : Paint,
  prop : String,
  js : Array[String],
  id : Array[Int],
) -> Unit {
  match paint {
    Solid(c) => js.push("ctx.\{prop} = '\{canvas_color(c)}';")
    Linear(stops, p0, p1) => {
      let g = "grad\{id[0]}"
      id[0] = id[0] + 1
      js.push(
        "const \{g} = ctx.createLinearGradient(\{p0.x}, \{p0.y}, \{p1.x}, \{p1.y});",
      )
      canvas_stops(g, stops, js)
      js.push("ctx.\{prop} = \{g};")
    }
    Radial(stops, c, r) => {
      let g = "grad\{id[0]}"
      id[0] = id[0] + 1
      js.push(
        "const \{g} = ctx.createRadialGradient(\{c.x}, \{c.y}, 0, \{c.x}, \{c.y}, \{r});",
      )
      canvas_stops(g, stops, js)
      js.push("ctx.\{prop} = \{g};")
    }
  }
}

///|
fn canvas_stops(g : String, stops : Array[Stop], js : Array[String]) -> Unit {
  for s in stops {
    js.push("\{g}.addColorStop(\{s.offset}, '\{canvas_color(s.color)}');")
  }
}

///|
fn canvas_color(c : Color) -> String {
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
/// Emit `ctx` path-construction calls for a (baked) path.
fn canvas_path(path : Path, js : Array[String]) -> Unit {
  js.push("ctx.beginPath();")
  let mut cur = Point(0.0, 0.0)
  let mut start = Point(0.0, 0.0)
  for seg in path.0 {
    match seg {
      MoveTo(p) => {
        js.push("ctx.moveTo(\{p.x}, \{p.y});")
        cur = p
        start = p
      }
      LineTo(p) => {
        js.push("ctx.lineTo(\{p.x}, \{p.y});")
        cur = p
      }
      CurveTo(c1, c2, e) => {
        js.push(
          "ctx.bezierCurveTo(\{c1.x}, \{c1.y}, \{c2.x}, \{c2.y}, \{e.x}, \{e.y});",
        )
        cur = e
      }
      QCurveTo(c, e) => {
        js.push("ctx.quadraticCurveTo(\{c.x}, \{c.y}, \{e.x}, \{e.y});")
        cur = e
      }
      EArcTo(rx, ry, rot, la, sw, e) => {
        for pt in flatten_arc(cur, rx, ry, rot, la, sw, e) {
          js.push("ctx.lineTo(\{pt.x}, \{pt.y});")
        }
        cur = e
      }
      Close => {
        js.push("ctx.closePath();")
        cur = start
      }
    }
  }
}
