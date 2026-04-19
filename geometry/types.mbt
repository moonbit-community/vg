// Core geometric types for the Vg vector graphics library

///|
/// A 2D point in the cartesian plane
#valtype
pub struct Point {
  x : Double
  y : Double
} derive(Eq, Debug)

///|
/// Bounding box
#valtype
pub struct Box {
  min_x : Double
  min_y : Double
  max_x : Double
  max_y : Double
} derive(Eq, Debug)

///|
/// Path segment types
pub enum PathSegment {
  MoveTo(Point)
  LineTo(Point)
  CurveTo(Point, Point, Point) // control1, control2, end (cubic Bézier)
  QCurveTo(Point, Point) // control, end (quadratic Bézier)
  EArcTo(Double, Double, Double, Bool, Bool, Point) // rx, ry, rotation, large_arc, sweep, end
  Close
} derive(Eq, Debug)

///|
/// A path is a sequence of segments
pub struct Path(Array[PathSegment]) derive(Eq, Debug)

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
} derive(Eq, Debug)

///|
pub impl Show for Point with output(self, logger) {
  logger.write_string(@debug.render(self.to_repr(), max_depth=2147483647))
}

///|
pub impl Show for Box with output(self, logger) {
  logger.write_string(@debug.render(self.to_repr(), max_depth=2147483647))
}

///|
pub impl Show for PathSegment with output(self, logger) {
  logger.write_string(@debug.render(self.to_repr(), max_depth=2147483647))
}

///|
pub impl Show for Path with output(self, logger) {
  logger.write_string(@debug.render(self.to_repr(), max_depth=2147483647))
}

///|
pub impl Show for Transform with output(self, logger) {
  logger.write_string(@debug.render(self.to_repr(), max_depth=2147483647))
}
