// Core types for the Vg vector graphics library

///|
/// A 2D point in the cartesian plane
pub struct Point {
  x : Double
  y : Double
} derive(Eq, Show)

///|
/// RGBA color representation
pub struct Color {
  r : Double // Red component [0.0, 1.0]
  g : Double // Green component [0.0, 1.0]
  b : Double // Blue component [0.0, 1.0]
  a : Double // Alpha component [0.0, 1.0]
} derive(Eq, Show)

///|
/// 2D transformation matrix
pub struct Transform {
  m11 : Double // Scale X
  m12 : Double // Skew Y
  m21 : Double // Skew X
  m22 : Double // Scale Y
  m31 : Double // Translate X
  m32 : Double // Translate Y
} derive(Eq, Show)

///|
/// Bounding box
pub struct Box {
  min_x : Double
  min_y : Double
  max_x : Double
  max_y : Double
} derive(Eq, Show)

///|
/// An image is a function from points to colors
pub(all) struct Image ((Point) -> Color)

///|
/// Path segment types
pub enum PathSegment {
  MoveTo(Point)
  LineTo(Point)
  CurveTo(Point, Point, Point) // control1, control2, end (cubic Bézier)
  QCurveTo(Point, Point) // control, end (quadratic Bézier)
  EArcTo(Double, Double, Double, Bool, Bool, Point) // rx, ry, rotation, large_arc, sweep, end
  Close
} derive(Eq, Show)

///|
/// A path is a sequence of segments
pub struct Path(Array[PathSegment]) derive(Eq, Show)

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
