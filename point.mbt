// Point and vector utilities

///|
/// Create a point
pub fn Point::new(x : Double, y : Double) -> Point {
  { x, y }
}

///|
/// Origin point (0, 0)
pub fn Point::origin() -> Point {
  { x: 0.0, y: 0.0 }
}

///|
/// Add two points
pub fn Point::add(self : Point, other : Point) -> Point {
  { x: self.x + other.x, y: self.y + other.y }
}

///|
/// Subtract two points
pub fn Point::sub(self : Point, other : Point) -> Point {
  { x: self.x - other.x, y: self.y - other.y }
}

///|
/// Scale a point by a scalar
pub fn Point::scale(self : Point, factor : Double) -> Point {
  { x: self.x * factor, y: self.y * factor }
}

///|
/// Distance between two points
pub fn Point::distance(self : Point, other : Point) -> Double {
  let dx = self.x - other.x
  let dy = self.y - other.y
  (dx * dx + dy * dy).sqrt()
}

///|
/// Dot product of two points (treated as vectors)
pub fn Point::dot(self : Point, other : Point) -> Double {
  self.x * other.x + self.y * other.y
}

///|
/// Length of a point (treated as vector from origin)
pub fn Point::length(self : Point) -> Double {
  (self.x * self.x + self.y * self.y).sqrt()
}

///|
/// Normalize a point (make it unit length)
pub fn Point::normalize(self : Point) -> Point {
  let len = self.length()
  if len == 0.0 {
    Point::origin()
  } else {
    { x: self.x / len, y: self.y / len }
  }
}

///|
/// Linear interpolation between two points
pub fn Point::lerp(self : Point, other : Point, t : Double) -> Point {
  { x: self.x + (other.x - self.x) * t, y: self.y + (other.y - self.y) * t }
}

///|
/// Rotate a point around the origin by angle (in radians)
pub fn Point::rotate(self : Point, angle : Double) -> Point {
  let cos_a = @math.cos(angle)
  let sin_a = @math.sin(angle)
  { x: self.x * cos_a - self.y * sin_a, y: self.x * sin_a + self.y * cos_a }
}

// Legacy functional-style functions for backward compatibility
// These will be deprecated in favor of the OO-style methods above

///|
/// Create a point (legacy function, use Point::new instead)
pub fn point(x : Double, y : Double) -> Point {
  Point::new(x, y)
}

///|
/// Origin point (legacy function, use Point::origin instead)
pub fn origin() -> Point {
  Point::origin()
}

///|
/// Add two points (legacy function, use p1.add(p2) instead)
pub fn add(p1 : Point, p2 : Point) -> Point {
  p1.add(p2)
}

///|
/// Subtract two points (legacy function, use p1.sub(p2) instead)
pub fn sub(p1 : Point, p2 : Point) -> Point {
  p1.sub(p2)
}

///|
/// Scale a point by a scalar (legacy function, use p.scale(factor) instead)
pub fn scale_point(p : Point, factor : Double) -> Point {
  p.scale(factor)
}

///|
/// Distance between two points (legacy function, use p1.distance(p2) instead)
pub fn distance(p1 : Point, p2 : Point) -> Double {
  p1.distance(p2)
}

///|
/// Dot product of two points (legacy function, use p1.dot(p2) instead)
pub fn dot(p1 : Point, p2 : Point) -> Double {
  p1.dot(p2)
}

///|
/// Length of a point (legacy function, use p.length() instead)
pub fn length(p : Point) -> Double {
  p.length()
}

///|
/// Normalize a point (legacy function, use p.normalize() instead)
pub fn normalize(p : Point) -> Point {
  p.normalize()
}

///|
/// Linear interpolation between two points (legacy function, use p1.lerp(p2, t) instead)
pub fn lerp(p1 : Point, p2 : Point, t : Double) -> Point {
  p1.lerp(p2, t)
}

///|
/// Rotate a point around the origin (legacy function, use p.rotate(angle) instead)
pub fn rotate_point(p : Point, angle : Double) -> Point {
  p.rotate(angle)
}
