// Point and vector utilities

/// Create a point
pub fn point(x : Double, y : Double) -> Point {
  { x, y }
}

/// Origin point (0, 0)
pub fn origin() -> Point {
  { x: 0.0, y: 0.0 }
}

/// Add two points
pub fn add(p1 : Point, p2 : Point) -> Point {
  { x: p1.x + p2.x, y: p1.y + p2.y }
}

/// Subtract two points
pub fn sub(p1 : Point, p2 : Point) -> Point {
  { x: p1.x - p2.x, y: p1.y - p2.y }
}

/// Scale a point by a scalar
pub fn scale_point(p : Point, factor : Double) -> Point {
  { x: p.x * factor, y: p.y * factor }
}

/// Distance between two points
pub fn distance(p1 : Point, p2 : Point) -> Double {
  let dx = p1.x - p2.x
  let dy = p1.y - p2.y
  (dx * dx + dy * dy).sqrt()
}

/// Dot product of two points (treated as vectors)
pub fn dot(p1 : Point, p2 : Point) -> Double {
  p1.x * p2.x + p1.y * p2.y
}

/// Length of a point (treated as vector from origin)
pub fn length(p : Point) -> Double {
  (p.x * p.x + p.y * p.y).sqrt()
}

/// Normalize a point (make it unit length)
pub fn normalize(p : Point) -> Point {
  let len = length(p)
  if len == 0.0 {
    origin()
  } else {
    { x: p.x / len, y: p.y / len }
  }
}

/// Linear interpolation between two points
pub fn lerp(p1 : Point, p2 : Point, t : Double) -> Point {
  {
    x: p1.x + (p2.x - p1.x) * t,
    y: p1.y + (p2.y - p1.y) * t
  }
}

/// Rotate a point around the origin by angle (in radians)
pub fn rotate_point(p : Point, angle : Double) -> Point {
  let cos_a = @math.cos(angle)
  let sin_a = @math.sin(angle)
  {
    x: p.x * cos_a - p.y * sin_a,
    y: p.x * sin_a + p.y * cos_a
  }
}
