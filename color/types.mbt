// Core color type definition

///|
/// RGBA color representation
pub struct Color {
  r : Double // Red component [0.0, 1.0]
  g : Double // Green component [0.0, 1.0]
  b : Double // Blue component [0.0, 1.0]
  a : Double // Alpha component [0.0, 1.0]
} derive(Eq)

///|
pub impl Show for Color with output(self, logger) {
  logger.write_string("{r: ")
  self.r.output(logger)
  logger.write_string(", g: ")
  self.g.output(logger)
  logger.write_string(", b: ")
  self.b.output(logger)
  logger.write_string(", a: ")
  self.a.output(logger)
  logger.write_string("}")
}
