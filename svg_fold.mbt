// Native SVG fold: turn the Image AST into compact vector graphics — one
// element per primitive — instead of the per-pixel `render_image_to_svg`
// sampler. This is the payoff of the AST: a circle becomes one `<path>` rather
// than thousands of `<rect>`s.

///|
/// Render the image to a standalone SVG document of the given size. The image's
/// coordinate origin is placed at the centre of the canvas (matching the
/// sampling renderer's convention).
pub fn Image::to_svg(self : Image, width : Double, height : Double) -> String {
  let defs : Array[String] = []
  let body = render_node(self, defs)
  let defs_str = if defs.length() > 0 {
    "<defs>" + defs.join("") + "</defs>"
  } else {
    ""
  }
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
  "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\{width}\" height=\"\{height}\" viewBox=\"0 0 \{width} \{height}\">" +
  defs_str +
  "<g transform=\"translate(\{width / 2.0},\{height / 2.0})\">" +
  body +
  "</g></svg>"
}

///|
/// Fold one AST node into SVG markup, accumulating gradient/clip `<defs>`.
fn render_node(img : Image, defs : Array[String]) -> String {
  match img {
    // a path filled with a primitive paint — the common, compact shape case
    Cut(area, path, Primitive(prim)) =>
      "<path d=\"\{path_data(path)}\" fill=\"\{paint_for(prim, defs)}\" fill-rule=\"\{fill_rule(area)}\"/>"
    // general clip: clip the inner image to the path's area
    Cut(area, path, inner) => {
      let id = "clip\{defs.length()}"
      defs.push(
        "<clipPath id=\"\{id}\" clipPathUnits=\"userSpaceOnUse\"><path d=\"\{path_data(path)}\" clip-rule=\"\{fill_rule(area)}\"/></clipPath>",
      )
      "<g clip-path=\"url(#\{id})\">" + render_node(inner, defs) + "</g>"
    }
    Tr(t, inner) =>
      "<g transform=\"matrix(\{t.m11},\{t.m21},\{t.m12},\{t.m22},\{t.m31},\{t.m32})\">" +
      render_node(inner, defs) +
      "</g>"
    // source-over: draw the bottom, then the top on top. Other Porter-Duff
    // operators are approximated by over for now (refined in a later step).
    Blend(_, alpha, top, bottom) => {
      let bottom_svg = render_node(bottom, defs)
      let top_svg = match alpha {
        Some(a) => "<g opacity=\"\{a}\">" + render_node(top, defs) + "</g>"
        None => render_node(top, defs)
      }
      bottom_svg + top_svg
    }
    // a bare colour field fills the whole plane
    Primitive(prim) =>
      "<rect x=\"-100000\" y=\"-100000\" width=\"200000\" height=\"200000\" fill=\"\{paint_for(prim, defs)}\"/>"
  }
}

///|
fn fill_rule(area : Area) -> String {
  match area {
    Anz => "nonzero"
    Aeo => "evenodd"
  }
}

///|
/// The SVG paint for a primitive: a solid colour, or a gradient registered in
/// `defs` and referenced by url.
fn paint_for(prim : Primitive, defs : Array[String]) -> String {
  match prim {
    Const(c) => color_svg(c)
    Axial(stops, p0, p1) => {
      let id = "grad\{defs.length()}"
      defs.push(
        "<linearGradient id=\"\{id}\" gradientUnits=\"userSpaceOnUse\" x1=\"\{p0.x}\" y1=\"\{p0.y}\" x2=\"\{p1.x}\" y2=\"\{p1.y}\">\{stops_svg(stops)}</linearGradient>",
      )
      "url(#\{id})"
    }
    Radial(stops, _focus, c, r) => {
      let id = "grad\{defs.length()}"
      defs.push(
        "<radialGradient id=\"\{id}\" gradientUnits=\"userSpaceOnUse\" cx=\"\{c.x}\" cy=\"\{c.y}\" r=\"\{r}\" fx=\"\{c.x}\" fy=\"\{c.y}\">\{stops_svg(stops)}</radialGradient>",
      )
      "url(#\{id})"
    }
  }
}

///|
fn stops_svg(stops : Array[Stop]) -> String {
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
fn color_svg(c : Color) -> String {
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
/// SVG `d` attribute for a path.
fn path_data(path : Path) -> String {
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
