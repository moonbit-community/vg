// Color utilities and predefined colors

/// Create a color from RGBA components
pub fn rgba(r : Double, g : Double, b : Double, a : Double) -> Color {
  { r, g, b, a }
}

/// Create a color from RGB components (alpha = 1.0)
pub fn rgb(r : Double, g : Double, b : Double) -> Color {
  { r, g, b, a: 1.0 }
}

/// Create a grayscale color
pub fn gray(value : Double) -> Color {
  { r: value, g: value, b: value, a: 1.0 }
}

/// Transparent color
pub fn transparent() -> Color {
  { r: 0.0, g: 0.0, b: 0.0, a: 0.0 }
}

// Predefined colors
pub fn black() -> Color { rgb(0.0, 0.0, 0.0) }
pub fn white() -> Color { rgb(1.0, 1.0, 1.0) }
pub fn red() -> Color { rgb(1.0, 0.0, 0.0) }
pub fn green() -> Color { rgb(0.0, 1.0, 0.0) }
pub fn blue() -> Color { rgb(0.0, 0.0, 1.0) }
pub fn yellow() -> Color { rgb(1.0, 1.0, 0.0) }
pub fn cyan() -> Color { rgb(0.0, 1.0, 1.0) }
pub fn magenta() -> Color { rgb(1.0, 0.0, 1.0) }
pub fn gold() -> Color { rgb(1.0, 0.843, 0.0) }
pub fn orange() -> Color { rgb(1.0, 0.647, 0.0) }
pub fn purple() -> Color { rgb(0.5, 0.0, 0.5) }

/// Blend two colors using alpha compositing
pub fn blend(c1 : Color, c2 : Color) -> Color {
  let alpha = c1.a + c2.a * (1.0 - c1.a)
  if alpha == 0.0 {
    transparent()
  } else {
    let inv_alpha = 1.0 / alpha
    {
      r: (c1.r * c1.a + c2.r * c2.a * (1.0 - c1.a)) * inv_alpha,
      g: (c1.g * c1.a + c2.g * c2.a * (1.0 - c1.a)) * inv_alpha,
      b: (c1.b * c1.a + c2.b * c2.a * (1.0 - c1.a)) * inv_alpha,
      a: alpha
    }
  }
}

/// Multiply color by a scalar
pub fn scale(c : Color, factor : Double) -> Color {
  {
    r: c.r * factor,
    g: c.g * factor,
    b: c.b * factor,
    a: c.a
  }
}

/// Convert color to hex string
pub fn to_hex(c : Color) -> String {
  let r = (c.r * 255.0).to_int()
  let g = (c.g * 255.0).to_int()
  let b = (c.b * 255.0).to_int()
  let r_hex = if r < 16 { "0" + r.to_string() } else { r.to_string() }
  let g_hex = if g < 16 { "0" + g.to_string() } else { g.to_string() }
  let b_hex = if b < 16 { "0" + b.to_string() } else { b.to_string() }
  "#" + r_hex + g_hex + b_hex
}

/// Clamp color components to valid range [0.0, 1.0]
pub fn clamp(c : Color) -> Color {
  fn clamp_component(x : Double) -> Double {
    if x < 0.0 { 0.0 } else if x > 1.0 { 1.0 } else { x }
  }
  {
    r: clamp_component(c.r),
    g: clamp_component(c.g),
    b: clamp_component(c.b),
    a: clamp_component(c.a)
  }
}

/// Create color from HSV (Hue, Saturation, Value)
pub fn hsv(h : Double, s : Double, v : Double) -> Color {
  let h_norm = h - (h / 360.0).floor() * 360.0  // Normalize hue to [0, 360)
  let c = v * s
  let x = c * (1.0 - ((h_norm / 60.0) % 2.0 - 1.0).abs())
  let m = v - c
  
  let (r_prime, g_prime, b_prime) = if h_norm < 60.0 {
    (c, x, 0.0)
  } else if h_norm < 120.0 {
    (x, c, 0.0)
  } else if h_norm < 180.0 {
    (0.0, c, x)
  } else if h_norm < 240.0 {
    (0.0, x, c)
  } else if h_norm < 300.0 {
    (x, 0.0, c)
  } else {
    (c, 0.0, x)
  }
  
  rgb(r_prime + m, g_prime + m, b_prime + m)
}

/// Interpolate between two colors
pub fn lerp_color(c1 : Color, c2 : Color, t : Double) -> Color {
  let t_clamped = if t < 0.0 { 0.0 } else if t > 1.0 { 1.0 } else { t }
  {
    r: c1.r + (c2.r - c1.r) * t_clamped,
    g: c1.g + (c2.g - c1.g) * t_clamped,
    b: c1.b + (c2.b - c1.b) * t_clamped,
    a: c1.a + (c2.a - c1.a) * t_clamped
  }
}
