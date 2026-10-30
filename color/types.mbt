// Core color type definition

///|
/// RGBA color representation
pub struct Color {
  r : Double // Red component [0.0, 1.0]
  g : Double // Green component [0.0, 1.0]
  b : Double // Blue component [0.0, 1.0]
  a : Double // Alpha component [0.0, 1.0]
} derive(Eq, Debug)

///|
/// Keep `Color::equal` / `Color::not_equal` / `Color::to_repr` available as
/// regular methods (the implicit `impl`-to-method promotion is deprecated).
pub extend Color with Eq::{not_equal, equal}

///|
pub extend Color with Debug::{to_repr}
