// Path construction and manipulation utilities

///|
/// Create an empty path
pub fn Path::empty() -> Path {
  Path([])
}

///|
/// Move to a point
pub fn Path::move_to(self : Path, p : Point) -> Path {
  Path([..self.0, MoveTo(p)])
}

///|
/// Line to a point
pub fn Path::line_to(self : Path, p : Point) -> Path {
  Path([..self.0, LineTo(p)])
}

///|
/// Cubic bezier curve to a point
pub fn Path::curve_to(
  self : Path,
  cp1 : Point,
  cp2 : Point,
  end : Point,
) -> Path {
  Path([..self.0, CurveTo(cp1, cp2, end)])
}

///|
/// Quadratic bezier curve to a point
pub fn Path::qcurve_to(self : Path, cp : Point, end : Point) -> Path {
  Path([..self.0, QCurveTo(cp, end)])
}

///|
/// Elliptical arc to a point
pub fn Path::earc_to(
  self : Path,
  rx : Double,
  ry : Double,
  rotation : Double,
  large_arc : Bool,
  sweep : Bool,
  end : Point,
) -> Path {
  Path([..self.0, EArcTo(rx, ry, rotation, large_arc, sweep, end)])
}

///|
/// Close the path
pub fn Path::close_path(self : Path) -> Path {
  Path([..self.0, Close])
}

///|
/// Create a rectangle path
pub fn Path::rect(
  x : Double,
  y : Double,
  width : Double,
  height : Double,
) -> Path {
  let top_left = Point::Point(x, y)
  let top_right = Point::Point(x + width, y)
  let bottom_right = Point::Point(x + width, y + height)
  let bottom_left = Point::Point(x, y + height)
  Path::empty()
  .move_to(top_left)
  .line_to(top_right)
  .line_to(bottom_right)
  .line_to(bottom_left)
  .close_path()
}

///|
/// Create a circle path (approximated with bezier curves)
pub fn Path::circle(center : Point, radius : Double) -> Path {
  let kappa = 0.5522847498 // Magic number for circle approximation
  let offset = radius * kappa
  let top = Point::Point(center.x, center.y - radius)
  let right = Point::Point(center.x + radius, center.y)
  let bottom = Point::Point(center.x, center.y + radius)
  let left = Point::Point(center.x - radius, center.y)
  Path::empty()
  .move_to(top)
  .curve_to(
    Point(center.x + offset, center.y - radius),
    Point(center.x + radius, center.y - offset),
    right,
  )
  .curve_to(
    Point(center.x + radius, center.y + offset),
    Point(center.x + offset, center.y + radius),
    bottom,
  )
  .curve_to(
    Point(center.x - offset, center.y + radius),
    Point(center.x - radius, center.y + offset),
    left,
  )
  .curve_to(
    Point(center.x - radius, center.y - offset),
    Point(center.x - offset, center.y - radius),
    top,
  )
  .close_path()
}

///|
/// Create an ellipse path
pub fn Path::ellipse(center : Point, rx : Double, ry : Double) -> Path {
  let kappa = 0.5522847498
  let offset_x = rx * kappa
  let offset_y = ry * kappa
  let top = Point::Point(center.x, center.y - ry)
  let right = Point::Point(center.x + rx, center.y)
  let bottom = Point::Point(center.x, center.y + ry)
  let left = Point::Point(center.x - rx, center.y)
  Path::empty()
  .move_to(top)
  .curve_to(
    Point(center.x + offset_x, center.y - ry),
    Point(center.x + rx, center.y - offset_y),
    right,
  )
  .curve_to(
    Point(center.x + rx, center.y + offset_y),
    Point(center.x + offset_x, center.y + ry),
    bottom,
  )
  .curve_to(
    Point(center.x - offset_x, center.y + ry),
    Point(center.x - rx, center.y + offset_y),
    left,
  )
  .curve_to(
    Point(center.x - rx, center.y - offset_y),
    Point(center.x - offset_x, center.y - ry),
    top,
  )
  .close_path()
}

///|
/// Get the bounding box of a path (approximate)
pub fn Path::bounds(self : Path) -> Box? {
  // the box starts at the first point (no sentinel extremes, which would
  // clamp paths lying entirely beyond them)
  let mut min_x = 0.0
  let mut min_y = 0.0
  let mut max_x = 0.0
  let mut max_y = 0.0
  let mut has_points = false
  fn update_bounds(p : Point) {
    if !has_points {
      has_points = true
      min_x = p.x
      max_x = p.x
      min_y = p.y
      max_y = p.y
    }
    if p.x < min_x {
      min_x = p.x
    }
    if p.x > max_x {
      max_x = p.x
    }
    if p.y < min_y {
      min_y = p.y
    }
    if p.y > max_y {
      max_y = p.y
    }
  }

  for segment in self.0 {
    match segment {
      MoveTo(p) | LineTo(p) => update_bounds(p)
      CurveTo(cp1, cp2, end) => {
        update_bounds(cp1)
        update_bounds(cp2)
        update_bounds(end)
      }
      QCurveTo(cp, end) => {
        update_bounds(cp)
        update_bounds(end)
      }
      EArcTo(_, _, _, _, _, end) => update_bounds(end) // Simplified bounds for arcs
      Close => ()
    }
  }
  if has_points {
    Some({ min_x, min_y, max_x, max_y, })
  } else {
    None
  }
}

///|
/// Create a smooth cubic curve that connects smoothly to the previous segment
pub fn Path::smooth_ccurve_to(self : Path, cp2 : Point, end : Point) -> Path {
  // reflect the previous cubic control point for a smooth join
  let cp1 = match self.0 {
    [.., CurveTo(_, prev_cp2, prev_end)] =>
      Point(2.0 * prev_end.x - prev_cp2.x, 2.0 * prev_end.y - prev_cp2.y)
    _ => cp2
  }
  Path([..self.0, CurveTo(cp1, cp2, end)])
}

///|
/// Create a smooth quadratic curve that connects smoothly to the previous segment
pub fn Path::smooth_qcurve_to(self : Path, end : Point) -> Path {
  // reflect the previous quadratic control point for a smooth join
  let cp = match self.0 {
    [.., QCurveTo(prev_cp, prev_end)] =>
      Point(2.0 * prev_end.x - prev_cp.x, 2.0 * prev_end.y - prev_cp.y)
    _ => end
  }
  Path([..self.0, QCurveTo(cp, end)])
}

///|
/// Transform a path using a transformation matrix.
///
/// Elliptical arcs are mapped exactly (new radii, rotation and sweep). When
/// the transform is singular an arc's image is a curve folded onto a line (or
/// a point), which no `EArcTo` can express; it is then emitted as line
/// segments through the projected extreme points of the arc, which trace the
/// same set in the same order.
pub fn Path::transform(self : Path, t : Transform) -> Path {
  let out : Array[PathSegment] = []
  // current point and subpath start, in source coordinates
  let mut cur = Point(0.0, 0.0)
  let mut start = Point(0.0, 0.0)
  for segment in self.0 {
    match segment {
      MoveTo(p) => {
        out.push(MoveTo(apply(t, p)))
        cur = p
        start = p
      }
      LineTo(p) => {
        out.push(LineTo(apply(t, p)))
        cur = p
      }
      CurveTo(cp1, cp2, end) => {
        out.push(CurveTo(apply(t, cp1), apply(t, cp2), apply(t, end)))
        cur = end
      }
      QCurveTo(cp, end) => {
        out.push(QCurveTo(apply(t, cp), apply(t, end)))
        cur = end
      }
      EArcTo(rx, ry, rotation, large_arc, sweep, end) => {
        transform_arc(out, t, cur, rx, ry, rotation, large_arc, sweep, end)
        cur = end
      }
      Close => {
        out.push(Close)
        cur = start
      }
    }
  }
  Path(out)
}

///|
/// Emit the image under `t` of the arc from `p0` described by the remaining
/// `EArcTo` parameters.
fn transform_arc(
  out : Array[PathSegment],
  t : Transform,
  p0 : Point,
  rx : Double,
  ry : Double,
  rotation : Double,
  large_arc : Bool,
  sweep : Bool,
  end : Point,
) -> Unit {
  // a zero radius makes the arc a straight line, and a pure translation
  // leaves the ellipse unchanged: keep the original parameters exactly
  if rx == 0.0 ||
    ry == 0.0 ||
    (t.m11 == 1.0 && t.m12 == 0.0 && t.m21 == 0.0 && t.m22 == 1.0) {
    out.push(EArcTo(rx, ry, rotation, large_arc, sweep, apply(t, end)))
    return
  }
  let det = determinant(t)
  if det == 0.0 {
    // singular: follow the projected curve through its turning points
    for p in arc_fold_points(t, p0, rx, ry, rotation, large_arc, sweep, end) {
      out.push(LineTo(apply(t, p)))
    }
    out.push(LineTo(apply(t, end)))
    return
  }
  let (rx, ry, rotation) = transform_arc_ellipse(t, rx, ry, rotation)
  // a reflection reverses the direction of travel along the arc
  let sweep = if det < 0.0 { !sweep } else { sweep }
  out.push(EArcTo(rx, ry, rotation, large_arc, sweep, apply(t, end)))
}

///|
/// The radii and x-axis rotation (degrees) of the ellipse with radii `rx`,
/// `ry` and rotation `rotation` after the (non-singular) linear part of `t`.
///
/// The ellipse is the image of the unit circle under M = L * R(phi) *
/// diag(rx, ry); its new semi-axes are the singular values of M and its new
/// rotation is the angle of M's left singular vectors (closed-form 2x2 SVD).
/// The minor singular value is computed as |det M| / sigma_max rather than
/// as a difference, which would cancel to 0 for very flat ellipses.
fn transform_arc_ellipse(
  t : Transform,
  rx : Double,
  ry : Double,
  rotation : Double,
) -> (Double, Double, Double) {
  let pi = 3.141592653589793
  let (c, s) = rotation_cos_sin(rotation)
  let rx = rx.abs()
  let ry = ry.abs()
  let a = (t.m11 * c + t.m12 * s) * rx
  let b = (t.m12 * c - t.m11 * s) * ry
  let cc = (t.m21 * c + t.m22 * s) * rx
  let d = (t.m22 * c - t.m21 * s) * ry
  // an axis-aligned image keeps its axes exactly: the SVD below would pick
  // a 90 degree rotation for a tall ellipse, whose rounded cosine a later
  // large scale would amplify
  if b == 0.0 && cc == 0.0 {
    return (a.abs(), d.abs(), 0.0)
  }
  if a == 0.0 && d == 0.0 {
    return (b.abs(), cc.abs(), 0.0)
  }
  let e = (a + d) / 2.0
  let f = (a - d) / 2.0
  let g = (cc + b) / 2.0
  let h = (cc - b) / 2.0
  let q = (e * e + h * h).sqrt()
  let r = (f * f + g * g).sqrt()
  let major = q + r
  // det M = det L * det R(phi) * rx * ry, with det R(phi) = 1
  let minor = (determinant(t) * rx * ry).abs() / major
  // The major axis is the principal eigenvector of M M^T = [[p, k], [k, u]],
  // at angle atan2(2k, p - u) / 2. This keeps a tiny tilt of a very flat
  // ellipse, which the difference of two atan2 angles cancels away. When the
  // major axis is nearer y it becomes ry, so the rotation stays within 45
  // degrees of 0, where a small tilt is representable in degrees (next to
  // 90 it would round away).
  let p = a * a + b * b
  let k = a * cc + b * d
  let u = cc * cc + d * d
  if p >= u {
    (major, minor, @math.atan2(2.0 * k, p - u) / 2.0 * 180.0 / pi)
  } else {
    (minor, major, @math.atan2(-2.0 * k, u - p) / 2.0 * 180.0 / pi)
  }
}

///|
/// Cosine and sine of `deg` degrees, exact at multiples of 90 degrees
/// (`@math.cos(pi / 2)` is 6.1e-17, not 0).
fn rotation_cos_sin(deg : Double) -> (Double, Double) {
  let q = deg / 90.0
  if q == q.floor() && q.abs() < 1.0e15 {
    let k = q.to_int64() % 4L
    let k = if k < 0L { k + 4L } else { k }
    match k {
      0L => return (1.0, 0.0)
      1L => return (0.0, 1.0)
      2L => return (-1.0, 0.0)
      _ => return (0.0, -1.0)
    }
  }
  let phi = deg * 3.141592653589793 / 180.0
  (@math.cos(phi), @math.sin(phi))
}

///|
/// Centre parameterisation of an SVG endpoint arc (radii scaled up when too
/// small to span the endpoints): (centre, rx, ry, cos phi, sin phi, start
/// angle, signed sweep angle), or `None` when the arc is empty (coincident
/// endpoints) or a straight line (a zero radius).
fn arc_center(
  p0 : Point,
  rx0 : Double,
  ry0 : Double,
  phi_deg : Double,
  large : Bool,
  sweep : Bool,
  p1 : Point,
) -> (Point, Double, Double, Double, Double, Double, Double)? {
  let mut rx = rx0.abs()
  let mut ry = ry0.abs()
  guard rx > 0.0 && ry > 0.0 && p0 != p1 else { None }
  let pi = 3.141592653589793
  let (cphi, sphi) = rotation_cos_sin(phi_deg)
  let dx = (p0.x - p1.x) / 2.0
  let dy = (p0.y - p1.y) / 2.0
  let x1 = cphi * dx + sphi * dy
  let y1 = -sphi * dx + cphi * dy
  let lam = x1 * x1 / (rx * rx) + y1 * y1 / (ry * ry)
  if lam > 1.0 {
    let k = lam.sqrt()
    rx = rx * k
    ry = ry * k
  }
  let num0 = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
  let den = rx * rx * y1 * y1 + ry * ry * x1 * x1
  let num = if num0 < 0.0 { 0.0 } else { num0 }
  let mut co = if den == 0.0 { 0.0 } else { (num / den).sqrt() }
  if large == sweep {
    co = -co
  }
  let cxp = co * rx * y1 / ry
  let cyp = -co * ry * x1 / rx
  let cx = cphi * cxp - sphi * cyp + (p0.x + p1.x) / 2.0
  let cy = sphi * cxp + cphi * cyp + (p0.y + p1.y) / 2.0
  let theta1 = @math.atan2((y1 - cyp) / ry, (x1 - cxp) / rx)
  let mut dtheta = @math.atan2((-y1 - cyp) / ry, (-x1 - cxp) / rx) - theta1
  if !sweep && dtheta > 0.0 {
    dtheta = dtheta - 2.0 * pi
  }
  if sweep && dtheta < 0.0 {
    dtheta = dtheta + 2.0 * pi
  }
  Some((Point(cx, cy), rx, ry, cphi, sphi, theta1, dtheta))
}

///|
/// For a singular `t`, the points of the arc (in source coordinates, in
/// travel order, endpoints excluded) where its image under `t` turns back:
/// the image lies on a line, and its coordinate along that line is
/// A cos(theta) + B sin(theta) + const, extremal at atan2(B, A) (+ pi).
fn arc_fold_points(
  t : Transform,
  p0 : Point,
  rx : Double,
  ry : Double,
  rotation : Double,
  large : Bool,
  sweep : Bool,
  p1 : Point,
) -> Array[Point] {
  guard arc_center(p0, rx, ry, rotation, large, sweep, p1)
    is Some((centre, rx, ry, cphi, sphi, theta1, dtheta)) else {
    return []
  }
  // point of the ellipse at parameter theta
  fn at(theta : Double) -> Point {
    let ct = @math.cos(theta)
    let st = @math.sin(theta)
    Point(
      centre.x + rx * ct * cphi - ry * st * sphi,
      centre.y + rx * ct * sphi + ry * st * cphi,
    )
  }

  // image of the ellipse's axes: the columns of M = L * R(phi) * diag(rx, ry)
  let a = (t.m11 * cphi + t.m12 * sphi) * rx
  let cc = (t.m21 * cphi + t.m22 * sphi) * rx
  let b = (t.m12 * cphi - t.m11 * sphi) * ry
  let d = (t.m22 * cphi - t.m21 * sphi) * ry
  // direction of the image line: the longer column
  let (ux, uy) = if a * a + cc * cc >= b * b + d * d { (a, cc) } else { (b, d) }
  let len = (ux * ux + uy * uy).sqrt()
  guard len > 0.0 else { return [] } // everything maps to one point
  let big_a = (ux * a + uy * cc) / len
  let big_b = (ux * b + uy * d) / len
  let pi = 3.141592653589793
  let two_pi = 2.0 * pi
  let found : Array[(Double, Point)] = []
  let theta_star = @math.atan2(big_b, big_a)
  for cand in [theta_star, theta_star + pi] {
    // how far along the sweep (in radians) the candidate angle lies
    let raw = if dtheta >= 0.0 { cand - theta1 } else { theta1 - cand }
    let delta = raw - (raw / two_pi).floor() * two_pi
    if delta > 0.0 && delta < dtheta.abs() {
      found.push((delta, at(cand)))
    }
  }
  if found.length() == 2 && found[1].0 < found[0].0 {
    found.swap(0, 1)
  }
  found.map(x => x.1)
}
