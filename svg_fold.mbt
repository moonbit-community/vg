// Native SVG fold: turn the Image AST into compact vector graphics — one
// element per primitive — instead of the per-pixel `render_image_to_svg`
// sampler. A circle becomes one `<path>` rather than thousands of `<rect>`s.
//
// Transforms are *baked* into coordinates (rather than emitted as `<g matrix>`)
// so that infinite colour fields keep covering the canvas and non-source-over
// blends can fall back to faithful `eval` rasterisation.

///|
/// Render the image to a standalone SVG document of the given size. The image's
/// coordinate origin is placed at the centre of the canvas (matching the
/// sampling renderer's convention).
pub fn Image::to_svg(self : Image, width : Double, height : Double) -> String {
  let defs : Array[String] = []
  // image origin -> canvas centre
  let acc = @geometry.make_translate(width / 2.0, height / 2.0)
  let body = render_node(self, acc, width, height, defs)
  let defs_str = if defs.length() > 0 {
    "<defs>" + defs.join("") + "</defs>"
  } else {
    ""
  }
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
  "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\{width}\" height=\"\{height}\" viewBox=\"0 0 \{width} \{height}\">" +
  defs_str +
  body +
  "</svg>"
}

///|
/// Fold one AST node into SVG markup. `acc` maps this node's coordinate space to
/// canvas space; it is baked into emitted geometry.
fn render_node(
  img : Image,
  acc : Transform,
  width : Double,
  height : Double,
  defs : Array[String],
) -> String {
  match img {
    // a path filled with a primitive paint — the common, compact shape case
    Cut(area, path, Primitive(prim)) =>
      "<path d=\"\{path_data(path, acc)}\" fill=\"\{paint_for(prim, acc, defs)}\" fill-rule=\"\{fill_rule(area)}\"/>"
    // general clip: clip the inner image to the path's area
    Cut(area, path, inner) => {
      let id = "clip\{defs.length()}"
      defs.push(
        "<clipPath id=\"\{id}\" clipPathUnits=\"userSpaceOnUse\"><path d=\"\{path_data(path, acc)}\" clip-rule=\"\{fill_rule(area)}\"/></clipPath>",
      )
      "<g clip-path=\"url(#\{id})\">" +
      render_node(inner, acc, width, height, defs) +
      "</g>"
    }
    // transform: compose into `acc` and recurse (baked, no <g matrix>)
    Tr(t, inner) =>
      render_node(
        inner,
        @geometry.compose_transforms(t, acc),
        width,
        height,
        defs,
      )
    // source-over: draw the bottom, then the top on top (opacity for alpha)
    Blend(Over, alpha, top, bottom) => {
      let bottom_svg = render_node(bottom, acc, width, height, defs)
      let top_svg = match alpha {
        Some(a) =>
          "<g opacity=\"\{a}\">" +
          render_node(top, acc, width, height, defs) +
          "</g>"
        None => render_node(top, acc, width, height, defs)
      }
      bottom_svg + top_svg
    }
    // other Porter-Duff operators have no faithful native SVG form: rasterise
    // the whole node via `eval` (correct, if not compact).
    Blend(_, _, _, _) => rasterize(img, acc, width, height)
    // an infinite colour field fills the whole canvas regardless of transform
    Primitive(prim) =>
      "<rect x=\"0\" y=\"0\" width=\"\{width}\" height=\"\{height}\" fill=\"\{paint_for(prim, acc, defs)}\"/>"
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
/// Rasterise a node by sampling `eval` over the canvas (the fallback for blends
/// SVG cannot express natively). Emits canvas-space rects.
fn rasterize(
  img : Image,
  acc : Transform,
  width : Double,
  height : Double,
) -> String {
  guard @geometry.invert(acc) is Some(inv) else { "" }
  let samples = 100
  let sx = width / samples.to_double()
  let sy = height / samples.to_double()
  let parts : Array[String] = []
  for i in 0..<samples {
    for j in 0..<samples {
      let cx = i.to_double() * sx
      let cy = j.to_double() * sy
      let c = img.eval(@geometry.apply(inv, Point(cx, cy)))
      if c.a > 0.0 {
        parts.push(
          "<rect x=\"\{cx}\" y=\"\{cy}\" width=\"\{sx}\" height=\"\{sy}\" fill=\"\{color_svg(c)}\"/>",
        )
      }
    }
  }
  parts.join("")
}

///|
/// The SVG paint for a primitive: a solid colour, or a gradient registered in
/// `defs` (with coordinates baked through `acc`).
fn paint_for(prim : Primitive, acc : Transform, defs : Array[String]) -> String {
  match prim {
    Const(c) => color_svg(c)
    Axial(stops, p0, p1) => {
      let q0 = @geometry.apply(acc, p0)
      let q1 = @geometry.apply(acc, p1)
      let id = "grad\{defs.length()}"
      defs.push(
        "<linearGradient id=\"\{id}\" gradientUnits=\"userSpaceOnUse\" x1=\"\{q0.x}\" y1=\"\{q0.y}\" x2=\"\{q1.x}\" y2=\"\{q1.y}\">\{stops_svg(stops)}</linearGradient>",
      )
      "url(#\{id})"
    }
    // radius is scaled by the transform's average magnitude (sqrt|det|); an
    // approximation for non-uniform scales.
    Radial(stops, _focus, c, r) => {
      let qc = @geometry.apply(acc, c)
      let scale = @geometry.determinant(acc).abs().sqrt()
      let id = "grad\{defs.length()}"
      defs.push(
        "<radialGradient id=\"\{id}\" gradientUnits=\"userSpaceOnUse\" cx=\"\{qc.x}\" cy=\"\{qc.y}\" r=\"\{r * scale}\" fx=\"\{qc.x}\" fy=\"\{qc.y}\">\{stops_svg(stops)}</radialGradient>",
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
/// SVG `d` attribute for a path, with all points baked through `acc`. (Arc
/// radii/rotation are left as-is, exact only for translations and rotations.)
fn path_data(path : Path, acc : Transform) -> String {
  let parts : Array[String] = []
  for seg in path.0 {
    match seg {
      MoveTo(p) => {
        let q = @geometry.apply(acc, p)
        parts.push("M \{q.x},\{q.y}")
      }
      LineTo(p) => {
        let q = @geometry.apply(acc, p)
        parts.push("L \{q.x},\{q.y}")
      }
      CurveTo(c1, c2, e) => {
        let a = @geometry.apply(acc, c1)
        let b = @geometry.apply(acc, c2)
        let d = @geometry.apply(acc, e)
        parts.push("C \{a.x},\{a.y} \{b.x},\{b.y} \{d.x},\{d.y}")
      }
      QCurveTo(c, e) => {
        let a = @geometry.apply(acc, c)
        let d = @geometry.apply(acc, e)
        parts.push("Q \{a.x},\{a.y} \{d.x},\{d.y}")
      }
      EArcTo(rx, ry, rot, large, sweep, e) => {
        let d = @geometry.apply(acc, e)
        let lf = if large { "1" } else { "0" }
        let sf = if sweep { "1" } else { "0" }
        parts.push("A \{rx} \{ry} \{rot} \{lf} \{sf} \{d.x},\{d.y}")
      }
      Close => parts.push("Z")
    }
  }
  parts.join(" ")
}
