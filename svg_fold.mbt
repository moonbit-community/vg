// SVG backend: interpret the backend-neutral `DrawCmd` list (see draw.mbt) into
// compact native SVG. A circle becomes one `<path>` rather than thousands of
// sampled `<rect>`s. The same draw list drives the PDF and canvas backends.

///|
/// Render the image to a standalone SVG document of the given size.
pub fn Image::to_svg(self : Image, width : Double, height : Double) -> String {
  svg_of(self.to_draw_list(width, height), width, height)
}

///|
fn svg_of(cmds : Array[DrawCmd], width : Double, height : Double) -> String {
  let defs = StringBuilder::new()
  let body = StringBuilder::new()
  let id = [0] // shared counter for gradient/clip ids
  for cmd in cmds {
    match cmd {
      FillPath(path, paint, area) => {
        let paint_str = paint_svg(paint, defs, id)
        match area {
          Outline(w) =>
            body.write_string(
              "<path d=\"\{svg_path_d(path)}\" fill=\"none\" stroke=\"\{paint_str}\" stroke-width=\"\{w}\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>",
            )
          _ =>
            body.write_string(
              "<path d=\"\{svg_path_d(path)}\" fill=\"\{paint_str}\" fill-rule=\"\{svg_rule(area)}\"/>",
            )
        }
      }
      FillViewport(paint) =>
        body.write_string(
          "<rect x=\"0\" y=\"0\" width=\"\{width}\" height=\"\{height}\" fill=\"\{paint_svg(paint, defs, id)}\"/>",
        )
      RasterCell(x, y, w, h, c) =>
        body.write_string(
          "<rect x=\"\{x}\" y=\"\{y}\" width=\"\{w}\" height=\"\{h}\" fill=\"\{svg_color(c)}\"/>",
        )
      PushClip(path, area) => {
        let cid = "clip\{id[0]}"
        id[0] = id[0] + 1
        defs.write_string(
          "<clipPath id=\"\{cid}\" clipPathUnits=\"userSpaceOnUse\"><path d=\"\{svg_path_d(path)}\" clip-rule=\"\{svg_rule(area)}\"/></clipPath>",
        )
        body.write_string("<g clip-path=\"url(#\{cid})\">")
      }
      PopClip => body.write_string("</g>")
      PushOpacity(a) => body.write_string("<g opacity=\"\{a}\">")
      PopOpacity => body.write_string("</g>")
      DrawText(content, x, y, size, color) =>
        body.write_string(
          "<text x=\"\{x}\" y=\"\{y}\" font-size=\"\{size}\" font-family=\"Arial, sans-serif\" text-anchor=\"middle\" dominant-baseline=\"central\" fill=\"\{svg_color(color)}\">\{svg_xml_escape(content)}</text>",
        )
    }
  }
  let defs_str = defs.to_string()
  let defs_block = if defs_str.length() > 0 {
    "<defs>\{defs_str}</defs>"
  } else {
    ""
  }
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
  "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\{width}\" height=\"\{height}\" viewBox=\"0 0 \{width} \{height}\">" +
  defs_block +
  body.to_string() +
  "</svg>"
}

///|
fn svg_rule(area : Area) -> String {
  match area {
    Anz => "nonzero"
    Aeo => "evenodd"
    Outline(_) => "nonzero" // strokes are handled before svg_rule
  }
}

///|
/// SVG paint for a baked `Paint`; registers a gradient in `defs` if needed.
fn paint_svg(paint : Paint, defs : StringBuilder, id : Array[Int]) -> String {
  match paint {
    Solid(c) => svg_color(c)
    Linear(stops, p0, p1) => {
      let gid = "grad\{id[0]}"
      id[0] = id[0] + 1
      defs.write_string(
        "<linearGradient id=\"\{gid}\" gradientUnits=\"userSpaceOnUse\" x1=\"\{p0.x}\" y1=\"\{p0.y}\" x2=\"\{p1.x}\" y2=\"\{p1.y}\">\{svg_stops(stops)}</linearGradient>",
      )
      "url(#\{gid})"
    }
    Radial(stops, c, r) => {
      let gid = "grad\{id[0]}"
      id[0] = id[0] + 1
      defs.write_string(
        "<radialGradient id=\"\{gid}\" gradientUnits=\"userSpaceOnUse\" cx=\"\{c.x}\" cy=\"\{c.y}\" r=\"\{r}\" fx=\"\{c.x}\" fy=\"\{c.y}\">\{svg_stops(stops)}</radialGradient>",
      )
      "url(#\{gid})"
    }
  }
}

///|
fn svg_stops(stops : Array[Stop]) -> String {
  let parts : Array[String] = []
  for s in stops {
    let opacity = if s.color.a < 1.0 {
      " stop-opacity=\"\{s.color.a}\""
    } else {
      ""
    }
    parts.push(
      "<stop offset=\"\{s.offset}\" stop-color=\"\{@color.to_hex(s.color)}\"\{opacity}/>",
    )
  }
  parts.join("")
}

///|
fn svg_color(c : Color) -> String {
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
/// SVG `d` attribute for a (baked) path.
fn svg_path_d(path : Path) -> String {
  let parts : Array[String] = []
  for seg in path.0 {
    match seg {
      MoveTo(p) => parts.push("M \{p.x},\{p.y}")
      LineTo(p) => parts.push("L \{p.x},\{p.y}")
      CurveTo(c1, c2, e) =>
        parts.push("C \{c1.x},\{c1.y} \{c2.x},\{c2.y} \{e.x},\{e.y}")
      QCurveTo(c, e) => parts.push("Q \{c.x},\{c.y} \{e.x},\{e.y}")
      EArcTo(rx, ry, rot, large, sweep, e) => {
        let lf = if large { "1" } else { "0" }
        let sf = if sweep { "1" } else { "0" }
        parts.push("A \{rx} \{ry} \{rot} \{lf} \{sf} \{e.x},\{e.y}")
      }
      Close => parts.push("Z")
    }
  }
  parts.join(" ")
}

///|
/// Escape text for XML content/attributes.
fn svg_xml_escape(s : String) -> String {
  let parts : Array[String] = []
  for ch in s {
    parts.push(
      match ch {
        '&' => "&amp;"
        '<' => "&lt;"
        '>' => "&gt;"
        '"' => "&quot;"
        '\'' => "&apos;"
        _ => ch.to_string()
      },
    )
  }
  parts.join("")
}
