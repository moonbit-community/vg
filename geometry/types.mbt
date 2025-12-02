// Core geometric types for the Vg vector graphics library

///|
/// A 2D point in the cartesian plane
#valtype
pub struct Point {
  x : Double
  y : Double
} derive(Eq, Show)

///|
/// Bounding box
#valtype
pub struct Box {
  min_x : Double
  min_y : Double
  max_x : Double
  max_y : Double
} derive(Eq, Show)

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
/// 2D transformation matrix
#valtype
pub struct Transform {
  m11 : Double // Scale X
  m12 : Double // Skew Y
  m21 : Double // Skew X
  m22 : Double // Scale Y
  m31 : Double // Translate X
  m32 : Double // Translate Y
} derive(Eq, Show)
