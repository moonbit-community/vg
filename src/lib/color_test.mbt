// Tests for color utilities

test "rgba color creation" {
  let c = rgba(0.5, 0.7, 0.9, 0.8)
  if c.r != 0.5 || c.g != 0.7 || c.b != 0.9 || c.a != 0.8 {
    fail("RGBA color components incorrect")
  }
}

test "rgb color creation" {
  let c = rgb(0.2, 0.4, 0.6)
  if c.r != 0.2 || c.g != 0.4 || c.b != 0.6 || c.a != 1.0 {
    fail("RGB color components incorrect")
  }
}

test "gray color creation" {
  let c = gray(0.5)
  if c.r != 0.5 || c.g != 0.5 || c.b != 0.5 || c.a != 1.0 {
    fail("Gray color components incorrect")
  }
}

test "transparent color" {
  let c = transparent()
  if c.r != 0.0 || c.g != 0.0 || c.b != 0.0 || c.a != 0.0 {
    fail("Transparent color should be (0,0,0,0)")
  }
}

test "predefined colors" {
  let r = red()
  let g = green()
  let b = blue()
  let w = white()
  let bl = black()
  
  if r.r != 1.0 || r.g != 0.0 || r.b != 0.0 {
    fail("Red color incorrect")
  }
  
  if g.r != 0.0 || g.g != 1.0 || g.b != 0.0 {
    fail("Green color incorrect")
  }
  
  if b.r != 0.0 || b.g != 0.0 || b.b != 1.0 {
    fail("Blue color incorrect")
  }
  
  if w.r != 1.0 || w.g != 1.0 || w.b != 1.0 {
    fail("White color incorrect")
  }
  
  if bl.r != 0.0 || bl.g != 0.0 || bl.b != 0.0 {
    fail("Black color incorrect")
  }
}

test "color blending" {
  let c1 = rgba(1.0, 0.0, 0.0, 0.5)  // Semi-transparent red
  let c2 = rgba(0.0, 1.0, 0.0, 0.5)  // Semi-transparent green
  let blended = blend(c1, c2)
  
  // Should result in a mix of red and green
  if blended.a <= 0.5 {
    fail("Blended alpha should be greater than individual alphas")
  }
  
  if blended.r <= 0.0 || blended.g <= 0.0 {
    fail("Blended color should contain both red and green components")
  }
}

test "color scaling" {
  let c = rgb(0.8, 0.6, 0.4)
  let scaled = scale_color(c, 0.5)
  
  if scaled.r != 0.4 || scaled.g != 0.3 || scaled.b != 0.2 {
    fail("Color scaling incorrect")
  }
  
  if scaled.a != c.a {
    fail("Alpha should not be affected by scaling")
  }
}

test "color clamping" {
  let c = { r: 1.5, g: -0.5, b: 0.5, a: 2.0 }
  let clamped = clamp_color(c)
  
  if clamped.r != 1.0 || clamped.g != 0.0 || clamped.b != 0.5 || clamped.a != 1.0 {
    fail("Color clamping incorrect")
  }
}

test "color to hex conversion" {
  let c = rgb(1.0, 0.5, 0.0)  // Orange
  let hex = to_hex(c)
  
  // Should be approximately #FF7F00 (allowing for rounding)
  if hex.length() != 7 || not(hex.starts_with("#")) {
    fail("Hex color format incorrect")
  }
}
