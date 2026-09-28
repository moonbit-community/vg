// Property-based tests (moonbitlang/core/quickcheck) for the geometry core:
// points/vectors, affine transforms, and paths.

// ----- generators -----

///|
/// A finite, bounded Double. The mix covers zero, small integers, dyadic
/// fractions, "ordinary" magnitudes, and tiny values.
priv struct D(Double) derive(Debug)

///|
fn gen_double(rs : @quickcheck.RandomState) -> Double {
  match rs.next_uint(limit=10) {
    0 => (rs.next_uint(limit=21).reinterpret_as_int() - 10).to_double()
    1 => 0.0
    2 => (rs.next_uint(limit=33).reinterpret_as_int() - 16).to_double() / 8.0
    3 => (rs.next_double() - 0.5) * 1.0e-6
    4 => (rs.next_double() - 0.5) * 2.0e4
    _ => (rs.next_double() - 0.5) * 200.0
  }
}

///|
impl @quickcheck.Arbitrary for D with fn arbitrary(_, rs) {
  D(gen_double(rs))
}

///|
impl @quickcheck.Shrink for D with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).map(x => D(x))
}

///|
/// A generated point.
priv struct P(Double, Double) derive(Debug)

///|
fn P::pt(self : P) -> @geometry.Point {
  Point(self.0, self.1)
}

///|
impl @quickcheck.Arbitrary for P with fn arbitrary(_, rs) {
  // the origin (zero vector) is an edge case for normalize / rotate
  if rs.next_uint(limit=10) == 0 {
    return P(0.0, 0.0)
  }
  let x = gen_double(rs)
  P(x, gen_double(rs))
}

///|
impl @quickcheck.Shrink for P with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.0, self.1)).map(t => P(t.0, t.1))
}

///|
/// One primitive transform constructor with its parameters.
priv enum Op {
  Rot(Double)
  Scale(Double, Double)
  Trans(Double, Double)
  SkewX(Double)
  SkewY(Double)
} derive(Debug)

///|
fn Op::tr(self : Op) -> @geometry.Transform {
  match self {
    Rot(a) => @geometry.make_rotate(a)
    Scale(sx, sy) => @geometry.make_scale(sx, sy)
    Trans(dx, dy) => @geometry.make_translate(dx, dy)
    SkewX(a) => @geometry.skew_x(a)
    SkewY(a) => @geometry.skew_y(a)
  }
}

///|
impl @quickcheck.Shrink for Op with fn shrink(_) {
  Iter::empty()
}

///|
fn gen_small(rs : @quickcheck.RandomState) -> Double {
  (rs.next_double() - 0.5) * 8.0
}

///|
fn gen_op(rs : @quickcheck.RandomState) -> Op {
  match rs.next_uint(limit=5) {
    0 => Rot(gen_small(rs))
    1 => {
      let sx = gen_small(rs)
      Scale(sx, gen_small(rs))
    }
    2 => {
      let dx = gen_double(rs)
      Trans(dx, gen_double(rs))
    }
    3 => SkewX(gen_small(rs) / 5.0)
    _ => SkewY(gen_small(rs) / 5.0)
  }
}

///|
/// A generated affine transform: a chain of one to four primitive
/// constructors folded with `compose_transforms` (the only public way to build
/// a general matrix, since `Transform` is read-only outside the package).
/// Chains mixing rotations/skews with translations give asymmetric linear
/// parts with non-zero translation.
priv struct T(Array[Op]) derive(Debug)

///|
fn T::tr(self : T) -> @geometry.Transform {
  let mut acc = @geometry.identity()
  for op in self.0 {
    acc = @geometry.compose_transforms(acc, op.tr())
  }
  acc
}

///|
impl @quickcheck.Arbitrary for T with fn arbitrary(_, rs) {
  let n = 1 + rs.next_uint(limit=4).reinterpret_as_int()
  T(Array::makei(n, _ => gen_op(rs)))
}

///|
impl @quickcheck.Shrink for T with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0)
  .filter(ops => ops.length() > 0)
  .map(ops => T(ops))
}

///|
/// A path built from arbitrary segments (all kinds, including arcs and
/// `Close`), optionally with very large coordinates.
priv struct Seg(@geometry.PathSegment) derive(Debug)

///|
impl @quickcheck.Shrink for Seg with fn shrink(_) {
  Iter::empty()
}

///|
priv struct PathW(Array[Seg]) derive(Debug)

///|
fn PathW::path(self : PathW) -> @geometry.Path {
  Path(self.0.map(s => s.0))
}

///|
/// `off == 0` gives ordinary coordinates; otherwise all coordinates of the
/// path cluster far from the origin on one side (|coord| > 1e6).
fn gen_coord(rs : @quickcheck.RandomState, off : Double) -> Double {
  if off == 0.0 {
    gen_double(rs)
  } else {
    off + rs.next_double() * off
  }
}

///|
fn gen_seg(rs : @quickcheck.RandomState, big : Double) -> @geometry.PathSegment {
  fn p() {
    let x = gen_coord(rs, big)
    @geometry.Point::Point(x, gen_coord(rs, big))
  }

  match rs.next_uint(limit=6) {
    0 => MoveTo(p())
    1 => LineTo(p())
    2 => {
      let a = p()
      let b = p()
      CurveTo(a, b, p())
    }
    3 => {
      let a = p()
      QCurveTo(a, p())
    }
    4 => {
      let rx = (rs.next_double() * 50.0).abs()
      let ry = (rs.next_double() * 50.0).abs()
      let rot = rs.next_double() * 360.0
      let la = rs.next_uint(limit=2) == 0
      let sw = rs.next_uint(limit=2) == 0
      EArcTo(rx, ry, rot, la, sw, p())
    }
    _ => Close
  }
}

///|
impl @quickcheck.Arbitrary for PathW with fn arbitrary(size, rs) {
  let big = match rs.next_uint(limit=6) {
    0 => 5.0e6
    1 => -3.0e7
    _ => 0.0
  }
  let n = rs
    .next_uint(limit=(size + 1).reinterpret_as_uint())
    .reinterpret_as_int()
  let segs : Array[Seg] = []
  for _ in 0..<n {
    segs.push(Seg(gen_seg(rs, big)))
  }
  PathW(segs)
}

///|
impl @quickcheck.Shrink for PathW with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).map(x => PathW(x))
}

// ----- helpers -----

///|
fn close(a : Double, b : Double, scale : Double) -> Bool {
  (a - b).abs() <= 1.0e-9 * (1.0 + scale.abs() + a.abs() + b.abs())
}

///|
fn pclose(
  p : @geometry.Point,
  q : @geometry.Point,
  scale? : Double = 0.0,
) -> Bool {
  close(p.x, q.x, scale) && close(p.y, q.y, scale)
}

///|
fn mag(t : @geometry.Transform) -> Double {
  t.m11.abs() +
  t.m12.abs() +
  t.m21.abs() +
  t.m22.abs() +
  t.m31.abs() +
  t.m32.abs()
}

///|
fn tclose(
  a : @geometry.Transform,
  b : @geometry.Transform,
  scale : Double,
) -> Bool {
  close(a.m11, b.m11, scale) &&
  close(a.m12, b.m12, scale) &&
  close(a.m21, b.m21, scale) &&
  close(a.m22, b.m22, scale) &&
  close(a.m31, b.m31, scale) &&
  close(a.m32, b.m32, scale)
}

///|
fn seg_points(seg : @geometry.PathSegment) -> Array[@geometry.Point] {
  match seg {
    MoveTo(p) | LineTo(p) => [p]
    CurveTo(a, b, c) => [a, b, c]
    QCurveTo(a, b) => [a, b]
    EArcTo(_, _, _, _, _, p) => [p]
    Close => []
  }
}

///|
fn path_points(path : @geometry.Path) -> Array[@geometry.Point] {
  let out = []
  for seg in path.0 {
    for p in seg_points(seg) {
      out.push(p)
    }
  }
  out
}

// ----- points / vectors -----

///|
test "qc: point add is commutative and associative, sub undoes add" {
  @quickcheck.check(
    (input : (P, P, P)) => {
      let (a, b, c) = input
      let (p, q, r) = (a.pt(), b.pt(), c.pt())
      let s = p.length() + q.length() + r.length()
      p.add(q) == q.add(p) &&
      pclose(p.add(q).add(r), p.add(q.add(r)), scale=s) &&
      pclose(p.add(q).sub(q), p, scale=s) &&
      p.add(@geometry.Point::origin()) == p
    },
    seed=1,
  )
}

///|
test "qc: point scale distributes over add and composes" {
  @quickcheck.check(
    (input : (P, P, D, D)) => {
      let (a, b, k, l) = input
      let (p, q) = (a.pt(), b.pt())
      let s = (p.length() + q.length()) * (1.0 + k.0.abs()) * (1.0 + l.0.abs())
      pclose(p.add(q).scale(k.0), p.scale(k.0).add(q.scale(k.0)), scale=s) &&
      pclose(p.scale(k.0).scale(l.0), p.scale(k.0 * l.0), scale=s) &&
      p.scale(1.0) == p
    },
    seed=2,
  )
}

///|
test "qc: dot / length / distance identities" {
  @quickcheck.check(
    (input : (P, P, P)) => {
      let (a, b, c) = input
      let (p, q, r) = (a.pt(), b.pt(), c.pt())
      let s = (p.length() + q.length() + r.length()) *
        (1.0 + p.length() + q.length() + r.length())
      p.dot(q) == q.dot(p) &&
      close(p.dot(p), p.length() * p.length(), s) &&
      close(p.distance(q), p.sub(q).length(), s) &&
      p.distance(q) == q.distance(p) &&
      p.distance(r) <= p.distance(q) + q.distance(r) + 1.0e-9 * (1.0 + s) &&
      // bilinearity of dot
      close(p.add(q).dot(r), p.dot(r) + q.dot(r), s)
    },
    seed=3,
  )
}

///|
test "qc: normalize yields a unit vector in the same direction" {
  @quickcheck.check(
    (a : P) => {
      let p = a.pt()
      let n = p.normalize()
      if p.length() == 0.0 {
        n == @geometry.Point::origin()
      } else {
        close(n.length(), 1.0, 0.0) && close(n.dot(p), p.length(), p.length())
      }
    },
    observe=a => [@quickcheck.classify(a.pt().length() == 0.0, "zero vector")],
    seed=4,
  )
}

///|
test "qc: lerp hits its endpoints and is symmetric" {
  @quickcheck.check(
    (input : (P, P, D)) => {
      let (a, b, t) = input
      let (p, q) = (a.pt(), b.pt())
      let s = (p.length() + q.length()) * (1.0 + t.0.abs())
      p.lerp(q, 0.0) == p &&
      pclose(p.lerp(q, 1.0), q, scale=s) &&
      pclose(p.lerp(q, t.0), q.lerp(p, 1.0 - t.0), scale=s)
    },
    seed=5,
  )
}

///|
test "qc: rotate preserves length and agrees with make_rotate" {
  @quickcheck.check(
    (input : (P, D)) => {
      let (a, ang) = input
      let p = a.pt()
      let r = p.rotate(ang.0)
      let s = p.length()
      close(r.length(), p.length(), s) &&
      pclose(r.rotate(-ang.0), p, scale=s) &&
      pclose(@geometry.apply(@geometry.make_rotate(ang.0), p), r, scale=s)
    },
    seed=6,
  )
}

// ----- affine transforms -----

///|
test "qc: identity is neutral for apply and compose" {
  @quickcheck.check(
    (input : (T, P)) => {
      let (ta, a) = input
      let t = ta.tr()
      let id = @geometry.identity()
      @geometry.apply(id, a.pt()) == a.pt() &&
      @geometry.compose_transforms(id, t) == t &&
      @geometry.compose_transforms(t, id) == t
    },
    seed=7,
  )
}

///|
test "qc: compose_transforms(t1, t2) applies t1 first, then t2" {
  @quickcheck.check(
    (input : (T, T, P)) => {
      let (a, b, c) = input
      let (t1, t2, p) = (a.tr(), b.tr(), c.pt())
      let s = (1.0 + mag(t1)) * (1.0 + mag(t2)) * (1.0 + p.length())
      pclose(
        @geometry.apply(@geometry.compose_transforms(t1, t2), p),
        @geometry.apply(t2, @geometry.apply(t1, p)),
        scale=s,
      )
    },
    seed=8,
  )
}

///|
test "qc: compose_transforms is associative" {
  @quickcheck.check(
    (input : (T, T, T)) => {
      let (a, b, c) = input
      let (t1, t2, t3) = (a.tr(), b.tr(), c.tr())
      let s = (1.0 + mag(t1)) * (1.0 + mag(t2)) * (1.0 + mag(t3))
      tclose(
        @geometry.compose_transforms(@geometry.compose_transforms(t1, t2), t3),
        @geometry.compose_transforms(t1, @geometry.compose_transforms(t2, t3)),
        s,
      )
    },
    seed=9,
  )
}

///|
test "qc: determinant is multiplicative; orientation follows its sign" {
  @quickcheck.check(
    (input : (T, T)) => {
      let (a, b) = input
      let (t1, t2) = (a.tr(), b.tr())
      let s = (1.0 + mag(t1)) * (1.0 + mag(t2))
      close(
        @geometry.determinant(@geometry.compose_transforms(t1, t2)),
        @geometry.determinant(t1) * @geometry.determinant(t2),
        s * s,
      ) &&
      @geometry.preserves_orientation(t1) == (@geometry.determinant(t1) > 0.0)
    },
    seed=10,
  )
}

///|
/// Transforms whose linear part is reasonably conditioned, so that inversion
/// error stays within a fixed tolerance.
fn well_conditioned(t : @geometry.Transform) -> Bool {
  let lin = t.m11.abs() + t.m12.abs() + t.m21.abs() + t.m22.abs()
  @geometry.determinant(t).abs() >= 1.0e-2 * lin * lin
}

///|
test "qc: invert is a two-sided inverse for invertible transforms" {
  @quickcheck.check(
    (input : (T, P)) => {
      let (a, c) = input
      let t = a.tr()
      let p = c.pt()
      guard @geometry.invert(t) is Some(inv) else { false }
      let s = 1.0e3 * (1.0 + mag(t)) * (1.0 + mag(inv)) * (1.0 + p.length())
      pclose(@geometry.apply(inv, @geometry.apply(t, p)), p, scale=s) &&
      pclose(@geometry.apply(t, @geometry.apply(inv, p)), p, scale=s) &&
      tclose(@geometry.compose_transforms(t, inv), @geometry.identity(), s)
    },
    filter=(input : (T, P)) => {
      let (a, _) = input
      well_conditioned(a.tr())
    },
    observe=(input : (T, P)) => {
      let (a, _) = input
      let t = a.tr()
      [
        @quickcheck.classify(t.m12 != t.m21, "asymmetric linear part"),
        @quickcheck.classify(
          t.m31 != 0.0 || t.m32 != 0.0,
          "non-zero translation",
        ),
      ]
    },
    seed=11,
  )
}

///|
test "qc: invert returns None exactly for singular matrices" {
  @quickcheck.check(
    (input : (T, D, Bool)) => {
      let (a, k, degenerate) = input
      // optionally collapse the image onto a line: determinant 0
      let t = if degenerate {
        @geometry.compose_transforms(a.tr(), @geometry.make_scale(0.0, k.0))
      } else {
        a.tr()
      }
      (@geometry.invert(t) is None) == (@geometry.determinant(t) == 0.0)
    },
    observe=(input : (T, D, Bool)) => {
      [@quickcheck.classify(input.2, "degenerate")]
    },
    seed=12,
  )
}

// ----- paths -----

///|
test "qc: Path::transform maps every point through apply and keeps structure" {
  @quickcheck.check(
    (input : (PathW, T)) => {
      let (pw, ta) = input
      let path = pw.path()
      let t = ta.tr()
      let out = path.transform(t)
      guard out.0.length() == path.0.length() else { false }
      let src = path_points(path).map(p => @geometry.apply(t, p))
      let dst = path_points(out)
      src == dst && path.transform(@geometry.identity()) == path
    },
    seed=13,
  )
}

///|
test "qc: Path::transform respects compose_transforms (non-arc paths)" {
  @quickcheck.check(
    (input : (PathW, T, T)) => {
      let (pw, a, b) = input
      let path = pw.path()
      let (t1, t2) = (a.tr(), b.tr())
      let lhs = path_points(
        path.transform(@geometry.compose_transforms(t1, t2)),
      )
      let rhs = path_points(path.transform(t1).transform(t2))
      let s = (1.0 + mag(t1)) * (1.0 + mag(t2))
      for i, p in lhs {
        if !pclose(p, rhs[i], scale=s * (1.0 + p.length())) {
          return false
        }
      }
      true
    },
    seed=14,
  )
}

///|
test "qc: Path::bounds is the tight box of the path's points" {
  @quickcheck.check(
    (pw : PathW) => {
      let path = pw.path()
      let pts = path_points(path)
      match path.bounds() {
        None => pts.length() == 0
        Some(b) => {
          guard pts.length() > 0 else { false }
          let mut ok = true
          for p in pts {
            ok = ok &&
              b.min_x <= p.x &&
              p.x <= b.max_x &&
              b.min_y <= p.y &&
              p.y <= b.max_y
          }
          // tight: every side is attained by some point
          ok &&
          pts.iter().any(p => p.x == b.min_x) &&
          pts.iter().any(p => p.x == b.max_x) &&
          pts.iter().any(p => p.y == b.min_y) &&
          pts.iter().any(p => p.y == b.max_y)
        }
      }
    },
    observe=pw => {
      let pts = path_points(pw.path())
      [
        @quickcheck.classify(pts.length() == 0, "no points"),
        @quickcheck.classify(
          pts.iter().any(p => p.x.abs() > 1.0e6 || p.y.abs() > 1.0e6),
          "coordinates beyond 1e6",
        ),
      ]
    },
    seed=15,
  )
}

///|
test "regression: Path::bounds for a path entirely beyond 1e6" {
  let path = @geometry.Path::rect(2.0e6, 3.0e6, 10.0, 20.0)
  debug_inspect(
    path.bounds(),
    content="Some({ min_x: 2000000, min_y: 3000000, max_x: 2000010, max_y: 3000020 })",
  )
  let neg = @geometry.Path::rect(-5.0e6, -4.0e6, 1.0, 1.0)
  debug_inspect(
    neg.bounds(),
    content="Some({ min_x: -5000000, min_y: -4000000, max_x: -4999999, max_y: -3999999 })",
  )
}

///|
test "qc: bounds of a translated path is the translated bounds" {
  @quickcheck.check(
    (input : (PathW, P)) => {
      let (pw, d) = input
      let path = pw.path()
      let moved = path.transform(@geometry.make_translate(d.0, d.1))
      match (path.bounds(), moved.bounds()) {
        (None, None) => true
        (Some(b), Some(m)) => {
          let s = b.min_x.abs() + b.max_x.abs() + b.min_y.abs() + b.max_y.abs()
          close(m.min_x, b.min_x + d.0, s) &&
          close(m.max_x, b.max_x + d.0, s) &&
          close(m.min_y, b.min_y + d.1, s) &&
          close(m.max_y, b.max_y + d.1, s)
        }
        _ => false
      }
    },
    seed=16,
  )
}

///|
test "qc: rect / circle / ellipse bounds match their parameters" {
  @quickcheck.check(
    (input : (P, D, D)) => {
      let (c, w, h) = input
      let (x, y) = (c.0, c.1)
      let (w, h) = (w.0.abs(), h.0.abs())
      let s = x.abs() + y.abs() + w + h
      let rect_ok = match @geometry.Path::rect(x, y, w, h).bounds() {
        Some(b) =>
          close(b.min_x, x, s) &&
          close(b.min_y, y, s) &&
          close(b.max_x, x + w, s) &&
          close(b.max_y, y + h, s)
        None => false
      }
      let ell_ok = match @geometry.Path::ellipse(c.pt(), w, h).bounds() {
        Some(b) =>
          close(b.min_x, x - w, s) &&
          close(b.max_x, x + w, s) &&
          close(b.min_y, y - h, s) &&
          close(b.max_y, y + h, s)
        None => false
      }
      let circ_ok = @geometry.Path::circle(c.pt(), w) ==
        @geometry.Path::ellipse(c.pt(), w, w)
      rect_ok && ell_ok && circ_ok
    },
    seed=17,
  )
}

///|
test "qc: smooth curves reflect the previous control point" {
  @quickcheck.check(
    (input : (P, P, P, P, P)) => {
      let (a, b, c, d, e) = input
      let base = @geometry.Path::empty().move_to(a.pt())
      let s = a.pt().length() +
        b.pt().length() +
        c.pt().length() +
        d.pt().length()
      let cubic = base
        .curve_to(b.pt(), c.pt(), d.pt())
        .smooth_ccurve_to(e.pt(), a.pt())
      let quad = base.qcurve_to(b.pt(), c.pt()).smooth_qcurve_to(d.pt())
      let cubic_ok = match cubic.0 {
        [.., CurveTo(_, _, end), CurveTo(cp1, cp2, end2)] =>
          // the new first control point mirrors the old second one about `end`
          pclose(cp1.add(c.pt()), end.scale(2.0), scale=s) &&
          cp2 == e.pt() &&
          end2 == a.pt()
        _ => false
      }
      let quad_ok = match quad.0 {
        [.., QCurveTo(_, end), QCurveTo(cp, end2)] =>
          pclose(cp.add(b.pt()), end.scale(2.0), scale=s) && end2 == d.pt()
        _ => false
      }
      cubic_ok && quad_ok
    },
    seed=18,
  )
}

///|
test "regression: compose_transforms(translate, skew_x) applies translate first" {
  // shrunk counterexample: translate by (0, -43.7) then skew_x(-0.0108)
  let t1 = @geometry.make_translate(0.0, -43.71943333224373)
  let t2 = @geometry.skew_x(-0.01077709275996952)
  let p = @geometry.Point::origin()
  let composed = @geometry.apply(@geometry.compose_transforms(t1, t2), p)
  let sequential = @geometry.apply(t2, @geometry.apply(t1, p))
  // previously composed.x == 0 (translation not pushed through the skew)
  assert_true((composed.x - sequential.x).abs() < 1.0e-12)
  assert_true((composed.y - sequential.y).abs() < 1.0e-12)
}

///|
test "regression: invert of a rotation followed by a translation" {
  let t = @geometry.compose_transforms(
    @geometry.make_rotate(1.7396646067557748),
    @geometry.make_translate(0.0, 7166.261030856056),
  )
  guard @geometry.invert(t) is Some(inv) else { fail("should be invertible") }
  let p = @geometry.Point::origin()
  let back = @geometry.apply(inv, @geometry.apply(t, p))
  // previously the inverse's translation used the transposed linear part
  assert_true(back.x.abs() < 1.0e-9 && back.y.abs() < 1.0e-9)
}

///|
test "regression: Path::transform scales, rotates and reflects arc radii" {
  let arc = @geometry.Path::empty()
    .move_to(Point(0.0, 0.0))
    .earc_to(10.0, 5.0, 0.0, false, true, Point(20.0, 0.0))
  // previously the radii stayed (10, 5) while the end point moved to (40, 0)
  debug_inspect(
    arc.transform(@geometry.make_scale(2.0, 2.0)).0[1],
    content="EArcTo(20, 10, 0, false, true, { x: 40, y: 0 })",
  )
  // a reflection reverses the sweep direction
  guard arc.transform(@geometry.make_scale(-1.0, 1.0)).0[1]
    is EArcTo(rx, ry, _, false, sweep, end) else {
    fail("expected an arc")
  }
  assert_eq(rx, 10.0)
  assert_eq(ry, 5.0)
  assert_false(sweep)
  assert_eq(end, Point(-20.0, 0.0))
  // a quarter turn turns the major axis vertical
  guard arc.transform(@geometry.make_rotate(3.141592653589793 / 2.0)).0[1]
    is EArcTo(rx, ry, rot, _, _, _) else {
    fail("expected an arc")
  }
  assert_true((rx - 10.0).abs() < 1.0e-9 && (ry - 5.0).abs() < 1.0e-9)
  assert_true(((rot % 180.0 + 180.0) % 180.0 - 90.0).abs() < 1.0e-9)
}
