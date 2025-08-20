// Core types for the Vg vector graphics library

/// A 2D point in the cartesian plane
pub struct Point {
  x : Double
  y : Double
} derive(Eq, Show)

/// RGBA color representation
pub struct Color {
  r : Double  // Red component [0.0, 1.0]
  g : Double  // Green component [0.0, 1.0]
  b : Double  // Blue component [0.0, 1.0]
  a : Double  // Alpha component [0.0, 1.0]
} derive(Eq, Show)

/// A 2D vector (reserved for future use)
pub struct Vec2 {
  x : Double
  y : Double
} derive(Eq, Show)

/// 2D transformation matrix
pub struct Transform {
  m11 : Double  // Scale X
  m12 : Double  // Skew Y
  m21 : Double  // Skew X
  m22 : Double  // Scale Y
  m31 : Double  // Translate X
  m32 : Double  // Translate Y
} derive(Eq, Show)

/// Bounding box
pub struct Box {
  min_x : Double
  min_y : Double
  max_x : Double
  max_y : Double
} derive(Eq, Show)

/// An image is a function from points to colors
pub typealias (Point) -> Color as Image

/// Path segment types
pub enum PathSegment {
  MoveTo(Point)
  LineTo(Point)
  CurveTo(Point, Point, Point)  // control1, control2, end (cubic Bézier)
  QCurveTo(Point, Point)        // control, end (quadratic Bézier)
  EArcTo(Double, Double, Double, Bool, Bool, Point)  // rx, ry, rotation, large_arc, sweep, end
  Close
} derive(Eq, Show)

/// A path is a sequence of segments
pub struct Path(Array[PathSegment]) derive(Eq, Show)

/// Primitive shapes (reserved for future rendering backends)
pub enum Primitive {
  Circle(Point, Double)  // center, radius
  Rectangle(Point, Point)  // top-left, bottom-right
  Path(Path)
  Text(String, Point, Double)  // text, position, size
} derive(Eq, Show)

/// Image operations for declarative composition (reserved for future optimization)
pub enum ImageOp {
  Const(Color)
  Primitive(Primitive, Color)
  Transform(Transform, Image)
  Compose(Image, Image)
  Cut(Image, Image)  // Cut first image with second as mask
}
