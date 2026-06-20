// Backend-neutral draw list.
//
// Folding the Image AST produces a flat list of `DrawCmd`s with transforms
// already baked into canvas space. Each backend (SVG/PDF/canvas) interprets the
// same list, so the fold is written once. `PushClip`/`PopClip` and
// `PushOpacity`/`PopOpacity` bracket nested regions.

///|
/// A baked (canvas-space) fill style.
pub(all) enum Paint {
  Solid(Color)
  Linear(Array[Stop], Point, Point) // stops, p0, p1
  Radial(Array[Stop], Point, Double) // stops, centre, radius
} derive(Eq, Debug)

///|
/// One drawing instruction in canvas space.
pub(all) enum DrawCmd {
  FillPath(Path, Paint, Area)
  FillViewport(Paint) // an infinite colour field
  RasterCell(Double, Double, Double, Double, Color) // x, y, w, h, colour
  PushClip(Path, Area)
  PopClip
  PushOpacity(Double)
  PopOpacity
  DrawText(String, Double, Double, Double, Color) // content, x, y, size, colour
} derive(Eq, Debug)

///|
/// Fold the image into a backend-neutral draw list for a `width` x `height`
/// canvas (image origin at the centre).
pub fn Image::to_draw_list(
  self : Image,
  width : Double,
  height : Double,
) -> Array[DrawCmd] {
  let cmds : Array[DrawCmd] = []
  let acc = @geometry.make_translate(width / 2.0, height / 2.0)
  fold_into(self, acc, width, height, cmds)
  cmds
}

///|
fn fold_into(
  img : Image,
  acc : Transform,
  width : Double,
  height : Double,
  cmds : Array[DrawCmd],
) -> Unit {
  match img {
    // a raster (procedural) primitive has no native vector form: sample it
    Cut(_, _, Primitive(Raster(_))) | Primitive(Raster(_)) =>
      rasterize_into(img, acc, width, height, cmds)
    Cut(area, path, Primitive(prim)) =>
      cmds.push(
        FillPath(
          path.transform(acc),
          paint_of(prim, acc),
          scale_area(area, acc),
        ),
      )
    // an outline cut of a non-primitive image: rasterise (stroke-clip is hard)
    Cut(Outline(_), _, _) => rasterize_into(img, acc, width, height, cmds)
    Cut(area, path, inner) => {
      cmds.push(PushClip(path.transform(acc), area))
      fold_into(inner, acc, width, height, cmds)
      cmds.push(PopClip)
    }
    Tr(t, inner) =>
      fold_into(
        inner,
        @geometry.compose_transforms(t, acc),
        width,
        height,
        cmds,
      )
    Blend(Over, alpha, top, bottom) => {
      fold_into(bottom, acc, width, height, cmds)
      match alpha {
        Some(a) => {
          cmds.push(PushOpacity(a))
          fold_into(top, acc, width, height, cmds)
          cmds.push(PopOpacity)
        }
        None => fold_into(top, acc, width, height, cmds)
      }
    }
    // operators other than source-over have no faithful native form: rasterise
    Blend(_, _, _, _) => rasterize_into(img, acc, width, height, cmds)
    Primitive(prim) => cmds.push(FillViewport(paint_of(prim, acc)))
    // text is anchored at the origin, baked through `acc`; size scales with it
    Text(content, size, color) => {
      let p = @geometry.apply(acc, Point(0.0, 0.0))
      let s = size * @geometry.determinant(acc).abs().sqrt()
      cmds.push(DrawText(content, p.x, p.y, s, color))
    }
  }
}

///|
/// Sample a node via `eval` and emit raster cells (the fallback for blends a
/// vector backend cannot express).
fn rasterize_into(
  img : Image,
  acc : Transform,
  width : Double,
  height : Double,
  cmds : Array[DrawCmd],
) -> Unit {
  guard @geometry.invert(acc) is Some(inv) else {  }
  let samples = 100
  let sx = width / samples.to_double()
  let sy = height / samples.to_double()
  for i in 0..<samples {
    for j in 0..<samples {
      let cx = i.to_double() * sx
      let cy = j.to_double() * sy
      let c = img.eval(@geometry.apply(inv, Point(cx, cy)))
      if c.a > 0.0 {
        cmds.push(RasterCell(cx, cy, sx, sy, c))
      }
    }
  }
}

///|
/// Scale an `Outline` width by the transform's average magnitude (sqrt|det|), so
/// a native stroke matches `eval` under uniform scales. Fills are unchanged.
fn scale_area(area : Area, acc : Transform) -> Area {
  match area {
    Outline(w) => Outline(w * @geometry.determinant(acc).abs().sqrt())
    _ => area
  }
}

///|
/// A primitive's paint with coordinates baked through `acc`.
fn paint_of(prim : Primitive, acc : Transform) -> Paint {
  match prim {
    Const(c) => Solid(c)
    // raster nodes are rasterised by the fold, never painted as a solid
    Raster(_) => Solid(@color.transparent())
    Axial(stops, p0, p1) =>
      Linear(stops, @geometry.apply(acc, p0), @geometry.apply(acc, p1))
    // radius scaled by sqrt|det| (approximate for non-uniform scales)
    Radial(stops, _focus, c, r) =>
      Radial(
        stops,
        @geometry.apply(acc, c),
        r * @geometry.determinant(acc).abs().sqrt(),
      )
  }
}

///|
/// Approximate an SVG endpoint-parameterised elliptical arc (from `p0` to `p1`)
/// as a polyline of points along the arc (excluding `p0`). Shared by the
/// backends so arcs render consistently; SVG keeps its native `A` command.
fn flatten_arc(
  p0 : Point,
  rx0 : Double,
  ry0 : Double,
  phi_deg : Double,
  large : Bool,
  sweep : Bool,
  p1 : Point,
) -> Array[Point] {
  let out : Array[Point] = []
  let mut rx = rx0.abs()
  let mut ry = ry0.abs()
  guard rx > 0.0 && ry > 0.0 else {
    out.push(p1)
    return out
  }
  let pi = 3.141592653589793
  let phi = phi_deg * pi / 180.0
  let cphi = @math.cos(phi)
  let sphi = @math.sin(phi)
  let dx = (p0.x - p1.x) / 2.0
  let dy = (p0.y - p1.y) / 2.0
  let x1 = cphi * dx + sphi * dy
  let y1 = -sphi * dx + cphi * dy
  let lam = x1 * x1 / (rx * rx) + y1 * y1 / (ry * ry)
  if lam > 1.0 {
    let s = lam.sqrt()
    rx = rx * s
    ry = ry * s
  }
  let num0 = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
  let den = rx * rx * y1 * y1 + ry * ry * x1 * x1
  let num = if num0 < 0.0 { 0.0 } else { num0 }
  let mut co = if den == 0.0 { 0.0 } else { (num / den).sqrt() }
  if large == sweep {
    co = -co
  }
  let cxp = co * rx * y1 / ry
  let cyp = -co * ry * x1 / rx
  let cx = cphi * cxp - sphi * cyp + (p0.x + p1.x) / 2.0
  let cy = sphi * cxp + cphi * cyp + (p0.y + p1.y) / 2.0
  let theta1 = @math.atan2((y1 - cyp) / ry, (x1 - cxp) / rx)
  let two_pi = 2.0 * pi
  let mut dtheta = @math.atan2((-y1 - cyp) / ry, (-x1 - cxp) / rx) - theta1
  if !sweep && dtheta > 0.0 {
    dtheta = dtheta - two_pi
  }
  if sweep && dtheta < 0.0 {
    dtheta = dtheta + two_pi
  }
  let steps = 24
  for i in 1..<=steps {
    let t = theta1 + dtheta * i.to_double() / steps.to_double()
    let ct = @math.cos(t)
    let st = @math.sin(t)
    out.push(
      Point(
        cx + rx * ct * cphi - ry * st * sphi,
        cy + rx * ct * sphi + ry * st * cphi,
      ),
    )
  }
  out
}
