// Core geometric types for the Vg vector graphics library

///|
/// A 2D point in the cartesian plane
#valtype
pub struct Point {
  x : Double
  y : Double
} derive(Eq)

///|
pub impl Show for Point with output(self, logger) {
  logger.write_string("{x: ")
  self.x.output(logger)
  logger.write_string(", y: ")
  self.y.output(logger)
  logger.write_string("}")
}

///|
/// Bounding box
#valtype
pub struct Box {
  min_x : Double
  min_y : Double
  max_x : Double
  max_y : Double
} derive(Eq)

///|
pub impl Show for Box with output(self, logger) {
  logger.write_string("{min_x: ")
  self.min_x.output(logger)
  logger.write_string(", min_y: ")
  self.min_y.output(logger)
  logger.write_string(", max_x: ")
  self.max_x.output(logger)
  logger.write_string(", max_y: ")
  self.max_y.output(logger)
  logger.write_string("}")
}

///|
/// Path segment types
pub enum PathSegment {
  MoveTo(Point)
  LineTo(Point)
  CurveTo(Point, Point, Point) // control1, control2, end (cubic Bézier)
  QCurveTo(Point, Point) // control, end (quadratic Bézier)
  EArcTo(Double, Double, Double, Bool, Bool, Point) // rx, ry, rotation, large_arc, sweep, end
  Close
} derive(Eq)

///|
pub impl Show for PathSegment with output(self, logger) {
  match self {
    MoveTo(point) => {
      logger.write_string("MoveTo(")
      point.output(logger)
      logger.write_string(")")
    }
    LineTo(point) => {
      logger.write_string("LineTo(")
      point.output(logger)
      logger.write_string(")")
    }
    CurveTo(control1, control2, end) => {
      logger.write_string("CurveTo(")
      control1.output(logger)
      logger.write_string(", ")
      control2.output(logger)
      logger.write_string(", ")
      end.output(logger)
      logger.write_string(")")
    }
    QCurveTo(control, end) => {
      logger.write_string("QCurveTo(")
      control.output(logger)
      logger.write_string(", ")
      end.output(logger)
      logger.write_string(")")
    }
    EArcTo(rx, ry, rotation, large_arc, sweep, end) => {
      logger.write_string("EArcTo(")
      rx.output(logger)
      logger.write_string(", ")
      ry.output(logger)
      logger.write_string(", ")
      rotation.output(logger)
      logger.write_string(", ")
      large_arc.output(logger)
      logger.write_string(", ")
      sweep.output(logger)
      logger.write_string(", ")
      end.output(logger)
      logger.write_string(")")
    }
    Close => logger.write_string("Close")
  }
}

///|
/// A path is a sequence of segments
pub struct Path(Array[PathSegment]) derive(Eq)

///|
pub impl Show for Path with output(self, logger) {
  logger.write_string("Path(")
  self.0.output(logger)
  logger.write_string(")")
}

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
} derive(Eq)

///|
pub impl Show for Transform with output(self, logger) {
  logger.write_string("{m11: ")
  self.m11.output(logger)
  logger.write_string(", m12: ")
  self.m12.output(logger)
  logger.write_string(", m21: ")
  self.m21.output(logger)
  logger.write_string(", m22: ")
  self.m22.output(logger)
  logger.write_string(", m31: ")
  self.m31.output(logger)
  logger.write_string(", m32: ")
  self.m32.output(logger)
  logger.write_string("}")
}
