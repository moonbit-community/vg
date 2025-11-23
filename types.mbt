// Core types for the Vg vector graphics library

// Re-export geometry types

///|
pub type Point = @geometry.Point

///|
pub type Box = @geometry.Box

///|
pub type Path = @geometry.Path

///|
pub type PathSegment = @geometry.PathSegment

///|
pub type Transform = @geometry.Transform

// Re-export color type

///|
pub type Color = @color.Color

// Re-export pdf type

///|
pub type PdfDocument = @pdf.PdfDocument

///|
/// An image is a function from points to colors
pub(all) struct Image((Point) -> Color)

///|
/// Primitive shapes (reserved for future rendering backends)
pub enum Primitive {
  Circle(Point, Double) // center, radius
  Rectangle(Point, Point) // top-left, bottom-right
  Path(Path)
  Text(String, Point, Double) // text, position, size
} derive(Eq, Show)

///|
/// Create a circle primitive
pub fn primitive_circle(center : Point, radius : Double) -> Primitive {
  Primitive::Circle(center, radius)
}

///|
/// Create a rectangle primitive
pub fn primitive_rectangle(top_left : Point, bottom_right : Point) -> Primitive {
  Primitive::Rectangle(top_left, bottom_right)
}

///|
/// Create a path primitive
pub fn primitive_path(path : Path) -> Primitive {
  Primitive::Path(path)
}

///|
/// Create a text primitive
pub fn primitive_text(
  text : String,
  position : Point,
  size : Double,
) -> Primitive {
  Primitive::Text(text, position, size)
}

///|
/// Image operations for declarative composition (reserved for future optimization)
pub enum ImageOp {
  Const(Color)
  Primitive(Primitive, Color)
  Transform(Transform, Image)
  Compose(Image, Image)
  Cut(Image, Image) // Cut first image with second as mask
}

///|
/// Create a constant color image operation
pub fn imageop_const(color : Color) -> ImageOp {
  ImageOp::Const(color)
}

///|
/// Create a primitive image operation
pub fn imageop_primitive(primitive : Primitive, color : Color) -> ImageOp {
  ImageOp::Primitive(primitive, color)
}

///|
/// Create a transform image operation
pub fn imageop_transform(transform : Transform, image : Image) -> ImageOp {
  ImageOp::Transform(transform, image)
}

///|
/// Create a compose image operation
pub fn imageop_compose(image1 : Image, image2 : Image) -> ImageOp {
  ImageOp::Compose(image1, image2)
}

///|
/// Create a cut image operation
pub fn imageop_cut(image : Image, mask : Image) -> ImageOp {
  ImageOp::Cut(image, mask)
}
