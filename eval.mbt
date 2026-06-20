// Denotational semantics of the image AST.
//
// An `Image` *means* a function from points of the plane to colours; this file
// computes that function. Backends render the same tree as native vector
// graphics, but `eval` is the ground-truth raster meaning and the fallback for
// genuinely procedural images.

///|
/// The colour of image `self` at point `pt`.
pub fn Image::eval(self : Image, pt : Point) -> Color {
  match self {
    // text is draw-only: it has no point -> colour denotation
    Text(_, _, _) => @color.transparent()
    Primitive(prim) => eval_primitive(prim, pt)
    Cut(area, path, img) =>
      if point_in_path(path, pt, area) {
        img.eval(pt)
      } else {
        @color.transparent()
      }
    Tr(t, img) =>
      match @geometry.invert(t) {
        Some(inv) => img.eval(@geometry.apply(inv, pt))
        None => @color.transparent()
      }
    Blend(op, alpha, top, bottom) =>
      blend_colors(op, alpha, top.eval(pt), bottom.eval(pt))
  }
}

///|
fn eval_primitive(prim : Primitive, pt : Point) -> Color {
  match prim {
    Const(c) => c
    Raster(f) => f(pt)
    Axial(stops, p0, p1) => {
      let dx = p1.x - p0.x
      let dy = p1.y - p0.y
      let len_sq = dx * dx + dy * dy
      let t = if len_sq == 0.0 {
        0.0
      } else {
        ((pt.x - p0.x) * dx + (pt.y - p0.y) * dy) / len_sq
      }
      sample_stops(stops, t)
    }
    // `focus` is approximated by the centre in the raster semantics.
    Radial(stops, _focus, centre, radius) => {
      let dx = pt.x - centre.x
      let dy = pt.y - centre.y
      let d = (dx * dx + dy * dy).sqrt()
      let t = if radius == 0.0 { 1.0 } else { d / radius }
      sample_stops(stops, t)
    }
  }
}

///|
/// Sample a gradient's stops at parameter `t` (clamped to [0, 1]).
fn sample_stops(stops : Array[Stop], t : Double) -> Color {
  let t = if t < 0.0 { 0.0 } else if t > 1.0 { 1.0 } else { t }
  guard stops.length() > 0 else { @color.transparent() }
  let n = stops.length()
  if t <= stops[0].offset {
    stops[0].color
  } else if t >= stops[n - 1].offset {
    stops[n - 1].color
  } else {
    let mut i = 0
    for k in 0..<(n - 1) {
      if stops[k].offset <= t && t <= stops[k + 1].offset {
        i = k
        break
      }
    }
    let a = stops[i]
    let b = stops[i + 1]
    let span = b.offset - a.offset
    let frac = if span == 0.0 { 0.0 } else { (t - a.offset) / span }
    @color.lerp_color(a.color, b.color, frac)
  }
}

///|
/// Composite `top` with `bottom` per the blender; `alpha` optionally scales the
/// top's opacity. Porter-Duff In/Out/Atop/Xor are approximated by source-over
/// in the raster semantics for now.
fn blend_colors(
  op : Blender,
  alpha : Double?,
  top : Color,
  bottom : Color,
) -> Color {
  let top = match alpha {
    Some(a) => @color.rgba(top.r, top.g, top.b, top.a * a)
    None => top
  }
  match op {
    Copy => top
    // additive, premultiplied by alpha so a faded/transparent top adds nothing
    Plus =>
      @color.clamp(
        @color.rgba(
          top.r * top.a + bottom.r * bottom.a,
          top.g * top.a + bottom.g * bottom.a,
          top.b * top.a + bottom.b * bottom.a,
          top.a + bottom.a,
        ),
      )
    Over | Atop | In | Out | Xor => @color.blend(top, bottom)
  }
}

///|
/// Whether `pt` lies inside `path` under the given fill `area` rule. Points
/// exactly on the boundary count as inside (matching the old shape fills).
fn point_in_path(path : Path, pt : Point, area : Area) -> Bool {
  let subs = flatten_path(path)
  match area {
    // a stroke: within half the width of the path
    Outline(w) => near_path(subs, pt, w / 2.0)
    // a fill: boundary counts as inside
    _ => {
      for poly in subs {
        if on_boundary(poly, pt) {
          return true
        }
      }
      match area {
        Aeo => {
          let mut inside = false
          for poly in subs {
            if crossings_odd(poly, pt) {
              inside = !inside
            }
          }
          inside
        }
        Anz => {
          let mut wind = 0
          for poly in subs {
            wind = wind + winding(poly, pt)
          }
          wind != 0
        }
        Outline(_) => false
      }
    }
  }
}

///|
/// Whether `pt` is within `r` of any segment of the (flattened) path.
fn near_path(subs : Array[Array[Point]], pt : Point, r : Double) -> Bool {
  for poly in subs {
    let n = poly.length()
    for i in 0..<(n - 1) {
      if dist_point_segment(pt, poly[i], poly[i + 1]) <= r {
        return true
      }
    }
  }
  false
}

///|
fn dist_point_segment(p : Point, a : Point, b : Point) -> Double {
  let dx = b.x - a.x
  let dy = b.y - a.y
  let len_sq = dx * dx + dy * dy
  let (cx, cy) = if len_sq == 0.0 {
    (a.x, a.y)
  } else {
    let t0 = ((p.x - a.x) * dx + (p.y - a.y) * dy) / len_sq
    let t = if t0 < 0.0 { 0.0 } else if t0 > 1.0 { 1.0 } else { t0 }
    (a.x + t * dx, a.y + t * dy)
  }
  ((p.x - cx) * (p.x - cx) + (p.y - cy) * (p.y - cy)).sqrt()
}

///|
/// Whether `pt` lies on any edge of the closed polyline.
fn on_boundary(poly : Array[Point], pt : Point) -> Bool {
  let n = poly.length()
  guard n >= 2 else { false }
  for i in 0..<n {
    if point_on_segment(poly[i], poly[(i + 1) % n], pt) {
      return true
    }
  }
  false
}

///|
/// Whether `p` lies on the segment a-b (collinear and within its extent).
fn point_on_segment(a : Point, b : Point, p : Point) -> Bool {
  let len_sq = (b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y)
  // skip degenerate (zero-length) edges, else any point looks "collinear"
  guard len_sq > 1.0e-18 else { false }
  let cross = (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x)
  guard cross.abs() <= 1.0e-9 else { false }
  let dot = (p.x - a.x) * (b.x - a.x) + (p.y - a.y) * (b.y - a.y)
  dot >= -1.0e-9 && dot <= len_sq + 1.0e-9
}

///|
/// Flatten a path into closed polylines (one per subpath), sampling curves.
fn flatten_path(path : Path) -> Array[Array[Point]] {
  let subs : Array[Array[Point]] = []
  let mut current : Array[Point] = []
  let mut start = Point(0.0, 0.0)
  let mut cur = Point(0.0, 0.0)
  for seg in path.0 {
    match seg {
      MoveTo(p) => {
        if current.length() > 0 {
          subs.push(current)
        }
        current = [p]
        start = p
        cur = p
      }
      LineTo(p) => {
        current.push(p)
        cur = p
      }
      CurveTo(c1, c2, e) => {
        flatten_cubic(current, cur, c1, c2, e)
        cur = e
      }
      QCurveTo(c, e) => {
        flatten_quad(current, cur, c, e)
        cur = e
      }
      EArcTo(rx, ry, rot, la, sw, e) => {
        for pt in flatten_arc(cur, rx, ry, rot, la, sw, e) {
          current.push(pt)
        }
        cur = e
      }
      Close => {
        current.push(start)
        subs.push(current)
        current = []
        cur = start
      }
    }
  }
  if current.length() > 0 {
    subs.push(current)
  }
  subs
}

///|
fn flatten_cubic(
  pts : Array[Point],
  p0 : Point,
  c1 : Point,
  c2 : Point,
  p3 : Point,
) -> Unit {
  let steps = 16
  for i in 1..<=steps {
    let t = i.to_double() / steps.to_double()
    let u = 1.0 - t
    let x = u * u * u * p0.x +
      3.0 * u * u * t * c1.x +
      3.0 * u * t * t * c2.x +
      t * t * t * p3.x
    let y = u * u * u * p0.y +
      3.0 * u * u * t * c1.y +
      3.0 * u * t * t * c2.y +
      t * t * t * p3.y
    pts.push(Point(x, y))
  }
}

///|
fn flatten_quad(pts : Array[Point], p0 : Point, c : Point, p2 : Point) -> Unit {
  let steps = 16
  for i in 1..<=steps {
    let t = i.to_double() / steps.to_double()
    let u = 1.0 - t
    let x = u * u * p0.x + 2.0 * u * t * c.x + t * t * p2.x
    let y = u * u * p0.y + 2.0 * u * t * c.y + t * t * p2.y
    pts.push(Point(x, y))
  }
}

///|
/// Signed cross product (b - a) x (p - a); >0 means p is left of a->b.
fn is_left(a : Point, b : Point, p : Point) -> Double {
  (b.x - a.x) * (p.y - a.y) - (p.x - a.x) * (b.y - a.y)
}

///|
/// Winding number of a closed polyline around `pt` (non-zero rule).
fn winding(poly : Array[Point], pt : Point) -> Int {
  let n = poly.length()
  guard n >= 2 else { 0 }
  let mut w = 0
  for i in 0..<n {
    let a = poly[i]
    let b = poly[(i + 1) % n]
    if a.y <= pt.y {
      if b.y > pt.y && is_left(a, b, pt) > 0.0 {
        w = w + 1
      }
    } else if b.y <= pt.y && is_left(a, b, pt) < 0.0 {
      w = w - 1
    }
  }
  w
}

///|
/// Whether a horizontal ray from `pt` crosses the polyline an odd number of
/// times (even-odd rule).
fn crossings_odd(poly : Array[Point], pt : Point) -> Bool {
  let n = poly.length()
  guard n >= 2 else { false }
  let mut c = false
  for i in 0..<n {
    let a = poly[i]
    let b = poly[(i + 1) % n]
    if (a.y > pt.y) != (b.y > pt.y) {
      let x_int = (b.x - a.x) * (pt.y - a.y) / (b.y - a.y) + a.x
      if pt.x < x_int {
        c = !c
      }
    }
  }
  c
}
