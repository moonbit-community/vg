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
    Cut(area, path, Primitive(prim)) =>
      cmds.push(FillPath(path.transform(acc), paint_of(prim, acc), area))
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
/// A primitive's paint with coordinates baked through `acc`.
fn paint_of(prim : Primitive, acc : Transform) -> Paint {
  match prim {
    Const(c) => Solid(c)
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
