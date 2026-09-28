// White-box property tests (moonbitlang/core/quickcheck) for private helpers
// of the renderers: the PDF number formatter and the path flattener used by
// `eval` and the PDF / canvas backends.

///|
/// A finite Double spanning tiny residues, ordinary values and huge
/// magnitudes (all of which `Double::to_string` may print with an exponent).
priv struct Num(Double) derive(Debug)

///|
impl @quickcheck.Arbitrary for Num with fn arbitrary(_, rs) {
  let sign = if rs.next_uint(limit=2) == 0 { 1.0 } else { -1.0 }
  let mag = match rs.next_uint(limit=4) {
    0 => rs.next_double() * 100.0
    1 => rs.next_double() * 1.0e-6
    2 => {
      // 10^k for k in [-12, 25], times a random mantissa
      let k = rs.next_uint(limit=38).reinterpret_as_int() - 12
      let mut p = 1.0
      if k >= 0 {
        for _ in 0..<k {
          p = p * 10.0
        }
      } else {
        for _ in 0..<-k {
          p = p / 10.0
        }
      }
      (1.0 + rs.next_double() * 9.0) * p
    }
    _ => 0.0
  }
  Num(sign * mag)
}

///|
impl @quickcheck.Shrink for Num with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).map(x => Num(x))
}

///|
test "qc: pdf_num prints plain decimals that read back as the same number" {
  @quickcheck.check(
    (x : Num) => {
      let s = pdf_num(x.0)
      let plain = s.to_array().iter().all(c => c is ('0'..='9' | '.' | '-'))
      let back = @string.parse_double(s) catch { _ => @double.not_a_number }
      plain &&
      (
      // values below 1e-9 are flushed to zero
        (x.0.abs() < 1.0e-9 && back == 0.0) ||
        (back - x.0).abs() <= 1.0e-12 * x.0.abs()
      )
    },
    observe=x => {
      [@quickcheck.classify(x.0.to_string().contains("e"), "exponent form")]
    },
    seed=61,
  )
}

///|
/// A transform built from a scale, a skew, a rotation, an optional reflection
/// and a translation (for the arc test below). The second scale factor is
/// usually moderate, but sometimes tiny (ill-conditioned, down to 1e-8) or
/// exactly 0 (singular: the plane is folded onto a line).
priv struct Aff(Double, Double, Double, Bool, Double, Double, Double) derive (
  Debug,
)

///|
impl @quickcheck.Arbitrary for Aff with fn arbitrary(_, rs) {
  let sx = 0.25 + rs.next_double() * 3.0
  let sy = match rs.next_uint(limit=6) {
    0 => {
      // 1e-3 .. 1e-8: flatter ellipses are not representable in SVG's
      // endpoint form (rounding of the end point exceeds the minor radius);
      // down to 1e-17 the radii are checked by the geometry package's
      // "transformed arc radii are the singular values" property
      let k = 3 + rs.next_uint(limit=6).reinterpret_as_int()
      let mut v = 1.0
      for _ in 0..<k {
        v = v / 10.0
      }
      v
    }
    1 => 0.0
    _ => 0.25 + rs.next_double() * 3.0
  }
  let rot = (rs.next_double() - 0.5) * 7.0
  let flip = rs.next_uint(limit=3) == 0
  let skew = (rs.next_double() - 0.5) * 1.0
  let dx = (rs.next_double() - 0.5) * 200.0
  Aff(sx, sy, rot, flip, skew, dx, (rs.next_double() - 0.5) * 200.0)
}

///|
impl @quickcheck.Shrink for Aff with fn shrink(_) {
  Iter::empty()
}

///|
fn Aff::tr(self : Aff) -> Transform {
  let Aff(sx, sy, rot, flip, skew, dx, dy) = self
  let mut t = @geometry.make_scale(sx, sy)
  t = @geometry.compose_transforms(t, @geometry.skew_x(skew))
  t = @geometry.compose_transforms(t, @geometry.make_rotate(rot))
  if flip {
    t = @geometry.compose_transforms(t, @geometry.make_scale(-1.0, 1.0))
  }
  @geometry.compose_transforms(t, @geometry.make_translate(dx, dy))
}

///|
/// An elliptical arc segment: start, radii, x-axis rotation (degrees), flags,
/// end.
priv struct Arc(
  Double,
  Double,
  Double,
  Double,
  Double,
  Bool,
  Bool,
  Double,
  Double
) derive(Debug)

///|
impl @quickcheck.Arbitrary for Arc with fn arbitrary(_, rs) {
  let x0 = (rs.next_double() - 0.5) * 100.0
  let y0 = (rs.next_double() - 0.5) * 100.0
  let rx = 1.0 + rs.next_double() * 60.0
  let ry = 1.0 + rs.next_double() * 60.0
  let rot = rs.next_double() * 360.0
  let la = rs.next_uint(limit=2) == 0
  let sw = rs.next_uint(limit=2) == 0
  let x1 = (rs.next_double() - 0.5) * 100.0
  Arc(x0, y0, rx, ry, rot, la, sw, x1, (rs.next_double() - 0.5) * 100.0)
}

///|
impl @quickcheck.Shrink for Arc with fn shrink(_) {
  Iter::empty()
}

///|
fn Arc::path(self : Arc) -> Path {
  let Arc(x0, y0, rx, ry, rot, la, sw, x1, y1) = self
  Path::empty()
  .move_to(Point(x0, y0))
  .earc_to(rx, ry, rot, la, sw, Point(x1, y1))
}

///|
fn dist_to_polyline(p : Point, poly : Array[Point]) -> Double {
  let mut best = @double.infinity
  for i in 0..<(poly.length() - 1) {
    let d = dist_point_segment(p, poly[i], poly[i + 1])
    if d < best {
      best = d
    }
  }
  best
}

///|
test "qc: Path::transform maps elliptical arcs onto the transformed arc" {
  @quickcheck.check(
    (input : (Arc, Aff)) => {
      let (arc, aff) = input
      let t = aff.tr()
      let path = arc.path()
      // the arc flattened then transformed, versus transformed then flattened
      let expected = flatten_path(path)[0].map(p => @geometry.apply(t, p))
      let actual = flatten_path(path.transform(t))[0]
      let mut size = 0.0
      for p in expected {
        let d = expected[0].distance(p)
        if d > size {
          size = d
        }
      }
      // flattening uses 24 chords; allow a few percent of the arc's extent
      let tol = 0.05 * size + 1.0e-6
      actual.iter().all(p => dist_to_polyline(p, expected) <= tol) &&
      expected.iter().all(p => dist_to_polyline(p, actual) <= tol)
    },
    observe=input => {
      let (arc, aff) = input
      [
        @quickcheck.classify(aff.3, "reflection"),
        @quickcheck.classify(aff.1 == 0.0, "singular"),
        @quickcheck.classify(aff.1 > 0.0 && aff.1 < 1.0e-2, "ill-conditioned"),
        @quickcheck.classify(arc.5, "large arc"),
        @quickcheck.classify(arc.2 != arc.3, "elliptical"),
      ]
    },
    seed=62,
  )
}
