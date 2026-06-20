// Core types for the Vg vector graphics library

// Re-export geometry types

///|
pub using @geometry {
  type Point,
  type Box,
  type Path,
  type PathSegment,
  type Transform,
}

// Re-export color type

///|
pub using @color {type Color}

///|
/// A gradient colour stop: `offset` in [0, 1] paired with a `color`.
pub(all) struct Stop {
  offset : Double
  color : Color
} derive(Eq, Debug)

///|
/// A *primitive* is an infinite colour field. Concrete shapes are obtained by
/// cutting a primitive with a path (see `Cut`). Mirrors `Vg`'s `primitive`.
pub(all) enum Primitive {
  Const(Color)
  Axial(Array[Stop], Point, Point) // stops, p0, p1 (linear gradient axis)
  Radial(Array[Stop], Point, Point, Double) // stops, focus, centre, radius
  Raster((Point) -> Color) // a procedural / sampled colour field
}

///|
/// How a path delimits an area when cutting an image: a non-zero or even-odd
/// fill of its interior, or a stroke of its outline with the given width.
pub(all) enum Area {
  Anz // non-zero winding fill
  Aeo // even-odd fill
  Outline(Double) // stroke the path with this width
} derive(Eq, Debug)

///|
/// Compositing operator for `Blend`.
pub(all) enum Blender {
  Over
  Plus
  Copy
  In
  Out
  Atop
  Xor
} derive(Eq, Debug)

///|
/// An image is a declarative value. Its *denotation* is a function from points
/// of the plane to colours (see `Image::eval`), but it is *represented* as a
/// tree so that backends can render it as native, compact vector graphics.
/// Mirrors `Vg.image`.
pub(all) enum Image {
  Primitive(Primitive)
  Cut(Area, Path, Image)
  Blend(Blender, Double?, Image, Image) // operator, alpha, top, bottom
  Tr(Transform, Image)
  // text anchored at the origin; draw-only (eval is transparent for it)
  Text(String, Double, Color) // content, size, colour
}
