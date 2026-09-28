// White-box property tests (moonbitlang/core/quickcheck) for private helpers
// of the renderers: the path flattener used by `eval` and the PDF / canvas
// backends.

///|
/// A well-conditioned transform built from a scale, a rotation, an optional
/// reflection and a translation (for the arc test below).
priv struct Aff(Double, Double, Double, Bool, Double, Double, Double) derive (
  Debug,
)

///|
impl @quickcheck.Arbitrary for Aff with fn arbitrary(_, rs) {
  let sx = 0.25 + rs.next_double() * 3.0
  let sy = 0.25 + rs.next_double() * 3.0
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
        @quickcheck.classify(arc.5, "large arc"),
        @quickcheck.classify(arc.2 != arc.3, "elliptical"),
      ]
    },
    seed=62,
  )
}
