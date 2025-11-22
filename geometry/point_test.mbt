// Tests for point utilities

///|
test "point creation" {
  let p = Point::new(3.0, 4.0)
  if p.x != 3.0 || p.y != 4.0 {
    fail("Point creation incorrect")
  }
}

///|
test "origin point" {
  let o = Point::origin()
  if o.x != 0.0 || o.y != 0.0 {
    fail("Origin should be (0, 0)")
  }
}

///|
test "point addition" {
  let p1 = Point::new(1.0, 2.0)
  let p2 = Point::new(3.0, 4.0)
  let sum = p1.add(p2)
  if sum.x != 4.0 || sum.y != 6.0 {
    fail("Point addition incorrect")
  }
}

///|
test "point subtraction" {
  let p1 = Point::new(5.0, 7.0)
  let p2 = Point::new(2.0, 3.0)
  let diff = p1.sub(p2)
  if diff.x != 3.0 || diff.y != 4.0 {
    fail("Point subtraction incorrect")
  }
}

///|
test "point scaling" {
  let p = Point::new(2.0, 3.0)
  let scaled = p.scale(2.5)
  if scaled.x != 5.0 || scaled.y != 7.5 {
    fail("Point scaling incorrect")
  }
}

///|
test "distance calculation" {
  let p1 = Point::new(0.0, 0.0)
  let p2 = Point::new(3.0, 4.0)
  let dist = p1.distance(p2)

  // Distance should be 5.0 (3-4-5 triangle)
  if (dist - 5.0).abs() > 0.0001 {
    fail("Distance calculation incorrect")
  }
}

///|
test "dot product" {
  let p1 = Point::new(2.0, 3.0)
  let p2 = Point::new(4.0, 5.0)
  let dot_result = p1.dot(p2)

  // 2*4 + 3*5 = 8 + 15 = 23
  if dot_result != 23.0 {
    fail("Dot product incorrect")
  }
}

///|
test "vector length" {
  let p = Point::new(3.0, 4.0)
  let len = p.length()

  // Length should be 5.0
  if (len - 5.0).abs() > 0.0001 {
    fail("Vector length incorrect")
  }
}

///|
test "vector normalization" {
  let p = Point::new(3.0, 4.0)
  let normalized = p.normalize()
  let norm_length = normalized.length()

  // Normalized vector should have length 1.0
  if (norm_length - 1.0).abs() > 0.0001 {
    fail("Normalized vector should have unit length")
  }

  // Components should be 0.6 and 0.8
  if (normalized.x - 0.6).abs() > 0.0001 || (normalized.y - 0.8).abs() > 0.0001 {
    fail("Normalized vector components incorrect")
  }
}

///|
test "zero vector normalization" {
  let zero = Point::origin()
  let normalized = zero.normalize()
  if normalized.x != 0.0 || normalized.y != 0.0 {
    fail("Normalized zero vector should remain zero")
  }
}

///|
test "linear interpolation" {
  let p1 = Point::new(0.0, 0.0)
  let p2 = Point::new(10.0, 20.0)
  let mid = p1.lerp(p2, 0.5)
  if mid.x != 5.0 || mid.y != 10.0 {
    fail("Midpoint interpolation incorrect")
  }
  let start = p1.lerp(p2, 0.0)
  if start.x != 0.0 || start.y != 0.0 {
    fail("Interpolation at t=0 should return first point")
  }
  let end = p1.lerp(p2, 1.0)
  if end.x != 10.0 || end.y != 20.0 {
    fail("Interpolation at t=1 should return second point")
  }
}

///|
test "point rotation" {
  let p = Point::new(1.0, 0.0)
  let rotated = p.rotate(3.14159265359 / 2.0) // 90 degrees

  // Should be approximately (0, 1)
  if rotated.x.abs() > 0.0001 || (rotated.y - 1.0).abs() > 0.0001 {
    fail("90 degree rotation incorrect")
  }
}
