// Core color type definition

///|
/// RGBA color representation
pub struct Color {
  r : Double // Red component [0.0, 1.0]
  g : Double // Green component [0.0, 1.0]
  b : Double // Blue component [0.0, 1.0]
  a : Double // Alpha component [0.0, 1.0]
} derive(Eq, Show)
