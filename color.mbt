// Re-export color utilities from color package

///|
/// Create a color from RGBA components
pub fn rgba(r : Double, g : Double, b : Double, a : Double) -> Color {
  @color.rgba(r, g, b, a)
}

///|
/// Create a color from RGB components (alpha = 1.0)
pub fn rgb(r : Double, g : Double, b : Double) -> Color {
  @color.rgb(r, g, b)
}

///|
/// Create a grayscale color
pub fn gray(value : Double) -> Color {
  @color.gray(value)
}

///|
/// Transparent color
pub fn transparent() -> Color {
  @color.transparent()
}

// Predefined colors

///|
pub fn black() -> Color {
  @color.black()
}

///|
pub fn white() -> Color {
  @color.white()
}

///|
pub fn red() -> Color {
  @color.red()
}

///|
pub fn green() -> Color {
  @color.green()
}

///|
pub fn blue() -> Color {
  @color.blue()
}

///|
pub fn yellow() -> Color {
  @color.yellow()
}

///|
pub fn cyan() -> Color {
  @color.cyan()
}

///|
pub fn magenta() -> Color {
  @color.magenta()
}

///|
pub fn gold() -> Color {
  @color.gold()
}

///|
pub fn orange() -> Color {
  @color.orange()
}

///|
pub fn purple() -> Color {
  @color.purple()
}

///|
/// Blend two colors using alpha compositing
pub fn blend(c1 : Color, c2 : Color) -> Color {
  @color.blend(c1, c2)
}

///|
/// Multiply color by a scalar
pub fn scale(c : Color, factor : Double) -> Color {
  @color.scale(c, factor)
}

///|
/// Convert color to hex string
pub fn to_hex(c : Color) -> String {
  @color.to_hex(c)
}

///|
/// Clamp color components to valid range [0.0, 1.0]
pub fn clamp(c : Color) -> Color {
  @color.clamp(c)
}

///|
/// Create color from HSV (Hue, Saturation, Value)
pub fn hsv(h : Double, s : Double, v : Double) -> Color {
  @color.hsv(h, s, v)
}

///|
/// Interpolate between two colors
pub fn lerp_color(c1 : Color, c2 : Color, t : Double) -> Color {
  @color.lerp_color(c1, c2, t)
}

///|
/// Multiply blend mode
pub fn multiply_blend(c1 : Color, c2 : Color) -> Color {
  @color.multiply_blend(c1, c2)
}

///|
/// Screen blend mode  
pub fn screen_blend(c1 : Color, c2 : Color) -> Color {
  @color.screen_blend(c1, c2)
}

///|
/// Overlay blend mode
pub fn overlay_blend(c1 : Color, c2 : Color) -> Color {
  @color.overlay_blend(c1, c2)
}

///|
/// Hard light blend mode
pub fn hard_light_blend(c1 : Color, c2 : Color) -> Color {
  @color.hard_light_blend(c1, c2)
}

///|
/// Soft light blend mode
pub fn soft_light_blend(c1 : Color, c2 : Color) -> Color {
  @color.soft_light_blend(c1, c2)
}
