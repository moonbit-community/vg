// Core color type definition

///|
/// RGBA color representation
pub struct Color {
  pub r : Double // Red component [0.0, 1.0]
  pub g : Double // Green component [0.0, 1.0]
  pub b : Double // Blue component [0.0, 1.0]
  pub a : Double // Alpha component [0.0, 1.0]
} derive(Eq, Show)
