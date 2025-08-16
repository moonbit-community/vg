// 2D transformation utilities

/// Identity transformation
pub fn identity() -> Transform {
  { m11: 1.0, m12: 0.0, m21: 0.0, m22: 1.0, m31: 0.0, m32: 0.0 }
}

/// Translation transformation
pub fn make_translate(dx : Double, dy : Double) -> Transform {
  { m11: 1.0, m12: 0.0, m21: 0.0, m22: 1.0, m31: dx, m32: dy }
}

/// Scale transformation
pub fn make_scale(sx : Double, sy : Double) -> Transform {
  { m11: sx, m12: 0.0, m21: 0.0, m22: sy, m31: 0.0, m32: 0.0 }
}

/// Uniform scale transformation
pub fn scale_uniform(s : Double) -> Transform {
  make_scale(s, s)
}

/// Rotation transformation (angle in radians)
pub fn make_rotate(angle : Double) -> Transform {
  let cos_a = angle.cos()
  let sin_a = angle.sin()
  { m11: cos_a, m12: -sin_a, m21: sin_a, m22: cos_a, m31: 0.0, m32: 0.0 }
}

/// Skew X transformation
pub fn skew_x(angle : Double) -> Transform {
  { m11: 1.0, m12: 0.0, m21: angle.tan(), m22: 1.0, m31: 0.0, m32: 0.0 }
}

/// Skew Y transformation
pub fn skew_y(angle : Double) -> Transform {
  { m11: 1.0, m12: angle.tan(), m21: 0.0, m22: 1.0, m31: 0.0, m32: 0.0 }
}

/// Compose two transformations (multiply matrices)
pub fn compose_transforms(t1 : Transform, t2 : Transform) -> Transform {
  {
    m11: t1.m11 * t2.m11 + t1.m12 * t2.m21,
    m12: t1.m11 * t2.m12 + t1.m12 * t2.m22,
    m21: t1.m21 * t2.m11 + t1.m22 * t2.m21,
    m22: t1.m21 * t2.m12 + t1.m22 * t2.m22,
    m31: t1.m31 * t2.m11 + t1.m32 * t2.m21 + t2.m31,
    m32: t1.m31 * t2.m12 + t1.m32 * t2.m22 + t2.m32
  }
}

/// Apply transformation to a point
pub fn apply(t : Transform, p : Point) -> Point {
  {
    x: t.m11 * p.x + t.m21 * p.y + t.m31,
    y: t.m12 * p.x + t.m22 * p.y + t.m32
  }
}

/// Invert a transformation matrix
pub fn invert(t : Transform) -> Transform? {
  let det = t.m11 * t.m22 - t.m12 * t.m21
  if det == 0.0 {
    None
  } else {
    let inv_det = 1.0 / det
    Some({
      m11: t.m22 * inv_det,
      m12: -t.m12 * inv_det,
      m21: -t.m21 * inv_det,
      m22: t.m11 * inv_det,
      m31: (t.m21 * t.m32 - t.m22 * t.m31) * inv_det,
      m32: (t.m12 * t.m31 - t.m11 * t.m32) * inv_det
    })
  }
}

/// Get the determinant of the transformation
pub fn determinant(t : Transform) -> Double {
  t.m11 * t.m22 - t.m12 * t.m21
}

/// Check if transformation preserves orientation
pub fn preserves_orientation(t : Transform) -> Bool {
  determinant(t) > 0.0
}
