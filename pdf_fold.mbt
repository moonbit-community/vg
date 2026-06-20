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
  let sb = StringBuilder::new()
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
    FillPath(path, paint, area) =>
      if paint_color(paint).a > 0.0 {
        sb.write_string("q\n\{pdf_fill_color(paint)}\n")
        sb.write_string(pdf_path(path, height))
        sb.write_string("\{pdf_fill_op(area)}\nQ\n")
      }
    FillViewport(paint) =>
      // an infinite colour field fills the whole page
      if paint_color(paint).a > 0.0 {
        sb.write_string(
          "q\n\{pdf_fill_color(paint)}\n0 0 \{width} \{height} re\nf\nQ\n",
        )
      }
    RasterCell(x, y, w, h, c) =>
      if c.a > 0.0 {
        // re takes the lower-left corner in PDF's y-up space
        let yb = height - (y + h)
        sb.write_string("q\n\{pdf_color(c)}\n\{x} \{yb} \{w} \{h} re\nf\nQ\n")
      }
    // clip the following commands to the path's area (W / W*), then `n`
    PushClip(path, area) => {
      let clip = match area {
        Anz => "W n"
        Aeo => "W* n"
      }
      sb.write_string("q\n\{pdf_path(path, height)}\{clip}\n")
    }
    PopClip => sb.write_string("Q\n")
    // group opacity is not expressed by this basic backend; keep q/Q balanced
    PushOpacity(_) => sb.write_string("q\n")
    PopOpacity => sb.write_string("Q\n")
  }
}

///|
fn pdf_fill_op(area : Area) -> String {
  match area {
    Anz => "f"
    Aeo => "f*"
  }
}

///|
fn pdf_color(c : Color) -> String {
  "\{c.r} \{c.g} \{c.b} rg"
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
        parts.push("\{p.x} \{height - p.y} m")
        cur = p
        start = p
      }
      LineTo(p) => {
        parts.push("\{p.x} \{height - p.y} l")
        cur = p
      }
      CurveTo(c1, c2, e) => {
        parts.push(
          "\{c1.x} \{height - c1.y} \{c2.x} \{height - c2.y} \{e.x} \{height - e.y} c",
        )
        cur = e
      }
      // quadratic -> cubic by repeating the control point (approximation)
      QCurveTo(c, e) => {
        parts.push(
          "\{c.x} \{height - c.y} \{c.x} \{height - c.y} \{e.x} \{height - e.y} c",
        )
        cur = e
      }
      EArcTo(rx, ry, rot, la, sw, e) => {
        for pt in flatten_arc(cur, rx, ry, rot, la, sw, e) {
          parts.push("\{pt.x} \{height - pt.y} l")
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
