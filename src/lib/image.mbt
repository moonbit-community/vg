// Core image combinators and operations

/// Create a constant color image
pub fn const_color(color : Color) -> Image {
  fn(_p : Point) -> Color { color }
}

/// Create an empty (transparent) image
pub fn empty() -> Image {
  const_color(transparent())
}

/// Create a circle image
pub fn circle(color : Color, radius : Double) -> Image {
  fn(p : Point) -> Color {
    let dist = length(p)
    if dist <= radius {
      color
    } else {
      transparent()
    }
  }
}

/// Create a rectangle image
pub fn rectangle(color : Color, width : Double, height : Double) -> Image {
  fn(p : Point) -> Color {
    if p.x >= -width / 2.0 && p.x <= width / 2.0 && 
       p.y >= -height / 2.0 && p.y <= height / 2.0 {
      color
    } else {
      transparent()
    }
  }
}

/// Create a line image (with thickness)
pub fn line(color : Color, start : Point, end : Point, thickness : Double) -> Image {
  fn(p : Point) -> Color {
    // Distance from point to line segment
    let line_vec = sub(end, start)
    let point_vec = sub(p, start)
    let line_len_sq = dot(line_vec, line_vec)
    
    if line_len_sq == 0.0 {
      // Degenerate line (point)
      if distance(p, start) <= thickness / 2.0 { color } else { transparent() }
    } else {
      let t = dot(point_vec, line_vec) / line_len_sq
      let t_clamped = if t < 0.0 { 0.0 } else if t > 1.0 { 1.0 } else { t }
      let closest = add(start, scale(line_vec, t_clamped))
      let dist = distance(p, closest)
      if dist <= thickness / 2.0 { color } else { transparent() }
    }
  }
}

/// Transform an image
pub fn transform(t : Transform, img : Image) -> Image {
  fn(p : Point) -> Color {
    match invert(t) {
      Some(inv_t) => img(apply(inv_t, p))
      None => transparent()
    }
  }
}

/// Translate an image
pub fn translate_img(dx : Double, dy : Double, img : Image) -> Image {
  transform(make_translate(dx, dy), img)
}

/// Scale an image
pub fn scale_image(sx : Double, sy : Double, img : Image) -> Image {
  transform(make_scale(sx, sy), img)
}

/// Rotate an image
pub fn rotate_image(angle : Double, img : Image) -> Image {
  transform(make_rotate(angle), img)
}

/// Compose two images using alpha blending
pub fn compose_imgs(img1 : Image, img2 : Image) -> Image {
  fn(p : Point) -> Color {
    let c1 = img1(p)
    let c2 = img2(p)
    blend(c1, c2)
  }
}

/// Cut an image using another as a mask
pub fn cut(img : Image, mask : Image) -> Image {
  fn(p : Point) -> Color {
    let c = img(p)
    let m = mask(p)
    { r: c.r, g: c.g, b: c.b, a: c.a * m.a }
  }
}

/// Create a gradient between two colors
pub fn linear_gradient(color1 : Color, color2 : Color, start : Point, end : Point) -> Image {
  fn(p : Point) -> Color {
    let grad_vec = sub(end, start)
    let point_vec = sub(p, start)
    let grad_len_sq = dot(grad_vec, grad_vec)
    
    if grad_len_sq == 0.0 {
      color1
    } else {
      let t = dot(point_vec, grad_vec) / grad_len_sq
      let t_clamped = if t < 0.0 { 0.0 } else if t > 1.0 { 1.0 } else { t }
      
      // Linear interpolation between colors
      {
        r: color1.r + (color2.r - color1.r) * t_clamped,
        g: color1.g + (color2.g - color1.g) * t_clamped,
        b: color1.b + (color2.b - color1.b) * t_clamped,
        a: color1.a + (color2.a - color1.a) * t_clamped
      }
    }
  }
}

/// Create a radial gradient
pub fn radial_gradient(color1 : Color, color2 : Color, center : Point, radius : Double) -> Image {
  fn(p : Point) -> Color {
    let dist = distance(p, center)
    let t = if radius == 0.0 { 1.0 } else { dist / radius }
    let t_clamped = if t < 0.0 { 0.0 } else if t > 1.0 { 1.0 } else { t }
    
    {
      r: color1.r + (color2.r - color1.r) * t_clamped,
      g: color1.g + (color2.g - color1.g) * t_clamped,
      b: color1.b + (color2.b - color1.b) * t_clamped,
      a: color1.a + (color2.a - color1.a) * t_clamped
    }
  }
}
