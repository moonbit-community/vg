// PDF backend: interpret the backend-neutral `DrawCmd` list (see draw.mbt) into
// a PDF content stream. Shares the AST fold with the SVG/canvas backends.
//
// PDF has a y-up coordinate system, so every y is flipped to `height - y`.
// Limitations of this basic backend: gradients are approximated by a flat
// representative colour, group opacity is ignored, and quadratic curves / arcs
// are approximated (matching the existing PDF primitives).

///|
/// Render the image to a single-page PDF document of the given size.
pub fn Image::to_pdf(self : Image, width : Double, height : Double) -> String {
  let cmds = self.to_draw_list(width, height)
  let sb = StringBuilder()
  for cmd in cmds {
    pdf_cmd(cmd, width, height, sb)
  }
  @pdf.PdfDocument::PdfDocument(width, height)
  .add_raw(sb.to_string())
  .to_string()
}

///|
fn pdf_cmd(
  cmd : DrawCmd,
  width : Double,
  height : Double,
  sb : StringBuilder,
) -> Unit {
  match cmd {
    // a fully transparent fill paints nothing (this basic backend renders
    // partial alpha as opaque)
    FillPath(path, paint, area) => {
      let c = paint_color(paint)
      if c.a > 0.0 {
        match area {
          // stroke the outline with width w (round caps/joins)
          Outline(w) => {
            sb.write_string(
              "q\n\{pdf_num(c.r)} \{pdf_num(c.g)} \{pdf_num(c.b)} RG\n\{pdf_num(w)} w\n1 J\n1 j\n",
            )
            sb.write_string(pdf_path(path, height))
            sb.write_string("S\nQ\n")
          }
          _ => {
            sb.write_string("q\n\{pdf_color(c)}\n")
            sb.write_string(pdf_path(path, height))
            sb.write_string("\{pdf_fill_op(area)}\nQ\n")
          }
        }
      }
    }
    FillViewport(paint) =>
      // an infinite colour field fills the whole page
      if paint_color(paint).a > 0.0 {
        sb.write_string(
          "q\n\{pdf_fill_color(paint)}\n0 0 \{pdf_num(width)} \{pdf_num(height)} re\nf\nQ\n",
        )
      }
    RasterCell(x, y, w, h, c) =>
      if c.a > 0.0 {
        // re takes the lower-left corner in PDF's y-up space
        let yb = height - (y + h)
        sb.write_string(
          "q\n\{pdf_color(c)}\n\{pdf_num(x)} \{pdf_num(yb)} \{pdf_num(w)} \{pdf_num(h)} re\nf\nQ\n",
        )
      }
    // clip the following commands to the path's area (W / W*), then `n`
    PushClip(path, area) => {
      let clip = match area {
        Anz => "W n"
        Aeo => "W* n"
        Outline(_) => "W n" // outline cuts are stroked/rasterised, not clipped
      }
      sb.write_string("q\n\{pdf_path(path, height)}\{clip}\n")
    }
    PopClip => sb.write_string("Q\n")
    // group opacity is not expressed by this basic backend; keep q/Q balanced
    PushOpacity(_) => sb.write_string("q\n")
    PopOpacity => sb.write_string("Q\n")
    DrawText(content, x, y, size, color) => {
      // approximate centre alignment to match SVG/canvas (Helvetica is ~0.5em
      // per glyph; vertical centre ~0.35em above the baseline)
      let tx = x - content.length().to_double() * size * 0.5 / 2.0
      let ty = height - y - size * 0.35
      sb.write_string(
        "q\nBT\n/F1 \{pdf_num(size)} Tf\n\{pdf_num(color.r)} \{pdf_num(color.g)} \{pdf_num(color.b)} rg\n\{pdf_num(tx)} \{pdf_num(ty)} Td\n(\{pdf_text_escape(content)}) Tj\nET\nQ\n",
      )
    }
  }
}

///|
/// Escape a string for a PDF literal string `( ... )`.
fn pdf_text_escape(s : String) -> String {
  let parts : Array[String] = []
  for ch in s {
    parts.push(
      match ch {
        '\\' => "\\\\"
        '(' => "\\("
        ')' => "\\)"
        _ => ch.to_string()
      },
    )
  }
  parts.join("")
}

///|
fn pdf_fill_op(area : Area) -> String {
  match area {
    Anz => "f"
    Aeo => "f*"
    Outline(_) => "f" // strokes are handled before pdf_fill_op
  }
}

///|
fn pdf_color(c : Color) -> String {
  "\{pdf_num(c.r)} \{pdf_num(c.g)} \{pdf_num(c.b)} rg"
}

///|
/// A flat representative colour for a paint (gradients are approximated).
fn paint_color(paint : Paint) -> Color {
  match paint {
    Solid(c) => c
    Linear(stops, _, _) => avg_stops(stops)
    Radial(stops, _, _) => avg_stops(stops)
  }
}

///|
fn pdf_fill_color(paint : Paint) -> String {
  pdf_color(paint_color(paint))
}

///|
fn avg_stops(stops : Array[Stop]) -> Color {
  guard stops.length() > 0 else { @color.black() }
  @color.lerp_color(stops[0].color, stops[stops.length() - 1].color, 0.5)
}

///|
/// A (baked) path as PDF path-construction operators, with y flipped.
fn pdf_path(path : Path, height : Double) -> String {
  let parts : Array[String] = []
  let mut cur = Point(0.0, 0.0)
  let mut start = Point(0.0, 0.0)
  for seg in path.0 {
    match seg {
      MoveTo(p) => {
        parts.push("\{pdf_num(p.x)} \{pdf_num(height - p.y)} m")
        cur = p
        start = p
      }
      LineTo(p) => {
        parts.push("\{pdf_num(p.x)} \{pdf_num(height - p.y)} l")
        cur = p
      }
      CurveTo(c1, c2, e) => {
        parts.push(
          "\{pdf_num(c1.x)} \{pdf_num(height - c1.y)} \{pdf_num(c2.x)} \{pdf_num(height - c2.y)} \{pdf_num(e.x)} \{pdf_num(height - e.y)} c",
        )
        cur = e
      }
      // quadratic -> cubic by repeating the control point (approximation)
      QCurveTo(c, e) => {
        parts.push(
          "\{pdf_num(c.x)} \{pdf_num(height - c.y)} \{pdf_num(c.x)} \{pdf_num(height - c.y)} \{pdf_num(e.x)} \{pdf_num(height - e.y)} c",
        )
        cur = e
      }
      EArcTo(rx, ry, rot, la, sw, e) => {
        for pt in flatten_arc(cur, rx, ry, rot, la, sw, e) {
          parts.push("\{pdf_num(pt.x)} \{pdf_num(height - pt.y)} l")
        }
        cur = e
      }
      Close => {
        parts.push("h")
        cur = start
      }
    }
  }
  parts.join("\n") + "\n"
}

///|
/// Format a number for a PDF content stream. PDF has no exponent notation, so
/// values that `Double::to_string` prints as e.g. `2.842170943040401e-14` (a
/// rounding residue) are written as plain decimals; magnitudes below 1e-9 are
/// written as `0`.
fn pdf_num(x : Double) -> String {
  let s = x.to_string()
  guard s.contains("e") else { s }
  if x.abs() < 1.0e-9 {
    return "0"
  }
  // split "[-]d[.ddd]e[+|-]k" into its digits, integer length and exponent
  let chars = s.to_array()
  let digits = StringBuilder()
  let mut ndigits = 0
  let mut int_len = 0
  let mut seen_point = false
  let mut i = if chars[0] == '-' { 1 } else { 0 }
  while chars[i] != 'e' {
    if chars[i] == '.' {
      seen_point = true
    } else {
      digits.write_char(chars[i])
      ndigits += 1
      if !seen_point {
        int_len += 1
      }
    }
    i += 1
  }
  i += 1
  let exp_neg = chars[i] == '-'
  if chars[i] == '-' || chars[i] == '+' {
    i += 1
  }
  let mut exp = 0
  while i < chars.length() {
    exp = exp * 10 + (chars[i].to_int() - '0'.to_int())
    i += 1
  }
  let point = int_len + (if exp_neg { -exp } else { exp })
  let d = digits.to_string()
  let sign = if x < 0.0 { "-" } else { "" }
  if point <= 0 {
    sign + "0." + "0".repeat(-point) + d
  } else if point >= ndigits {
    sign + d + "0".repeat(point - ndigits)
  } else {
    sign +
    d.view(end_offset=point).to_owned() +
    "." +
    d.view(start_offset=point).to_owned()
  }
}
