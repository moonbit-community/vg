// Core image combinators and operations

///|
/// Create a constant color image
pub fn const_color(color : Color) -> Image {
  fn(_p : Point) -> Color { color }
}

///|
/// Create an empty (transparent) image
pub fn empty() -> Image {
  const_color(transparent())
}

///|
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

///|
/// Create a rectangle image
pub fn rectangle(color : Color, width : Double, height : Double) -> Image {
  fn(p : Point) -> Color {
    if p.x >= -width / 2.0 &&
      p.x <= width / 2.0 &&
      p.y >= -height / 2.0 &&
      p.y <= height / 2.0 {
      color
    } else {
      transparent()
    }
  }
}

///|
/// Create a line image (with thickness)
pub fn line(
  color : Color,
  start : Point,
  end : Point,
  thickness : Double,
) -> Image {
  fn(p : Point) -> Color {
    // Distance from point to line segment
    let line_vec = sub(end, start)
    let point_vec = sub(p, start)
    let line_len_sq = dot(line_vec, line_vec)
    if line_len_sq == 0.0 {
      // Degenerate line (point)
      if distance(p, start) <= thickness / 2.0 {
        color
      } else {
        transparent()
      }
    } else {
      let t = dot(point_vec, line_vec) / line_len_sq
      let t_clamped = if t < 0.0 { 0.0 } else if t > 1.0 { 1.0 } else { t }
      let closest = add(start, scale_point(line_vec, t_clamped))
      let dist = distance(p, closest)
      if dist <= thickness / 2.0 {
        color
      } else {
        transparent()
      }
    }
  }
}

///|
/// Transform an image
pub fn transform(t : Transform, img : Image) -> Image {
  fn(p : Point) -> Color {
    match invert(t) {
      Some(inv_t) => img(apply(inv_t, p))
      None => transparent()
    }
  }
}

///|
/// Translate an image
pub fn translate_img(dx : Double, dy : Double, img : Image) -> Image {
  transform(make_translate(dx, dy), img)
}

///|
/// Scale an image
pub fn scale_image(sx : Double, sy : Double, img : Image) -> Image {
  transform(make_scale(sx, sy), img)
}

///|
/// Rotate an image
pub fn rotate_image(angle : Double, img : Image) -> Image {
  transform(make_rotate(angle), img)
}

///|
/// Compose two images using alpha blending
pub fn compose_imgs(img1 : Image, img2 : Image) -> Image {
  fn(p : Point) -> Color {
    let c1 = img1(p)
    let c2 = img2(p)
    // If both colors are non-transparent, blend them
    if c1.a > 0.0 && c2.a > 0.0 {
      // Use additive blending for overlapping opaque areas
      {
        r: (c1.r + c2.r) / 2.0,
        g: (c1.g + c2.g) / 2.0,
        b: (c1.b + c2.b) / 2.0,
        a: (c1.a + c2.a) / 2.0,
      }
    } else {
      blend(c1, c2)
    }
  }
}

///|
/// Cut an image using another as a mask
pub fn cut(img : Image, mask : Image) -> Image {
  fn(p : Point) -> Color {
    let c = img(p)
    let m = mask(p)
    { r: c.r, g: c.g, b: c.b, a: c.a * m.a }
  }
}

///|
/// Create a gradient between two colors
pub fn linear_gradient(
  color1 : Color,
  color2 : Color,
  start : Point,
  end : Point,
) -> Image {
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
        a: color1.a + (color2.a - color1.a) * t_clamped,
      }
    }
  }
}

///|
/// Create a radial gradient
pub fn radial_gradient(
  color1 : Color,
  color2 : Color,
  center : Point,
  radius : Double,
) -> Image {
  fn(p : Point) -> Color {
    let dist = distance(p, center)
    let t = if radius == 0.0 { 1.0 } else { dist / radius }
    let t_clamped = if t < 0.0 { 0.0 } else if t > 1.0 { 1.0 } else { t }
    {
      r: color1.r + (color2.r - color1.r) * t_clamped,
      g: color1.g + (color2.g - color1.g) * t_clamped,
      b: color1.b + (color2.b - color1.b) * t_clamped,
      a: color1.a + (color2.a - color1.a) * t_clamped,
    }
  }
}

///|
/// Create an ellipse image
pub fn ellipse(color : Color, rx : Double, ry : Double) -> Image {
  fn(p : Point) -> Color {
    let normalized_x = p.x / rx
    let normalized_y = p.y / ry
    let dist_sq = normalized_x * normalized_x + normalized_y * normalized_y
    if dist_sq <= 1.0 {
      color
    } else {
      transparent()
    }
  }
}

///|
/// Create a polygon image from a list of points
pub fn polygon(color : Color, points : Array[Point]) -> Image {
  fn(p : Point) -> Color {
    // Point-in-polygon test using ray casting algorithm
    if points.length() < 3 {
      transparent()
    } else {
      let mut inside = false
      let mut j = points.length() - 1
      for i = 0; i < points.length(); i = i + 1 {
        let pi = points[i]
        let pj = points[j]
        if (pi.y > p.y) != (pj.y > p.y) &&
          p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x {
          inside = not(inside)
        }
        j = i
      }
      if inside {
        color
      } else {
        transparent()
      }
    }
  }
}

///|
/// Apply opacity to an image
pub fn with_opacity(img : Image, opacity : Double) -> Image {
  fn(p : Point) -> Color {
    let c = img(p)
    { r: c.r, g: c.g, b: c.b, a: c.a * opacity }
  }
}

///|
/// Create an axial gradient (alternative name for linear gradient)
pub fn axial_gradient(
  color1 : Color,
  color2 : Color,
  start : Point,
  end : Point,
) -> Image {
  linear_gradient(color1, color2, start, end)
}

///|
/// Create a conic gradient (angular gradient around a center point)
pub fn conic_gradient(
  color1 : Color,
  color2 : Color,
  center : Point,
  start_angle : Double,
) -> Image {
  fn(p : Point) -> Color {
    let vec = sub(p, center)
    // Simple angle calculation without atan2
    let angle = if vec.x == 0.0 {
      if vec.y >= 0.0 {
        3.14159265359 / 2.0
      } else {
        -3.14159265359 / 2.0
      }
    } else {
      let basic_angle = @math.atan(vec.y / vec.x)
      if vec.x < 0.0 {
        basic_angle + 3.14159265359
      } else {
        basic_angle
      }
    }
    let normalized_angle = (angle - start_angle + 2.0 * 3.14159265359) %
      (2.0 * 3.14159265359)
    let t = normalized_angle / (2.0 * 3.14159265359)
    {
      r: color1.r + (color2.r - color1.r) * t,
      g: color1.g + (color2.g - color1.g) * t,
      b: color1.b + (color2.b - color1.b) * t,
      a: color1.a + (color2.a - color1.a) * t,
    }
  }
}

///|
/// Create a repeated/tiled image
pub fn tile_image(
  img : Image,
  tile_width : Double,
  tile_height : Double,
) -> Image {
  fn(p : Point) -> Color {
    let tiled_x = p.x % tile_width
    let tiled_y = p.y % tile_height
    let normalized_x = if tiled_x < 0.0 {
      tiled_x + tile_width
    } else {
      tiled_x
    }
    let normalized_y = if tiled_y < 0.0 {
      tiled_y + tile_height
    } else {
      tiled_y
    }
    img(
      point(normalized_x - tile_width / 2.0, normalized_y - tile_height / 2.0),
    )
  }
}

///|
/// Create a checkerboard pattern
pub fn checkerboard(color1 : Color, color2 : Color, size : Double) -> Image {
  fn(p : Point) -> Color {
    let x_cell = (p.x / size).floor().to_int()
    let y_cell = (p.y / size).floor().to_int()
    if (x_cell + y_cell) % 2 == 0 {
      color1
    } else {
      color2
    }
  }
}
