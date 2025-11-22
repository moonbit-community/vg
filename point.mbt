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
