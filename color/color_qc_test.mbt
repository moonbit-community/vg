// Property-based tests (moonbitlang/core/quickcheck) for colours: clamping,
// hex encoding, HSV conversion, interpolation and blend modes.

// ----- generators -----

///|
/// A channel value in [0, 1]: endpoints, exact byte values k/255, halves and
/// uniform noise.
fn gen_unit(rs : @quickcheck.RandomState) -> Double {
  match rs.next_uint(limit=6) {
    0 => 0.0
    1 => 1.0
    2 => rs.next_uint(limit=256).reinterpret_as_int().to_double() / 255.0
    3 => 0.5
    _ => rs.next_double()
  }
}

///|
/// An in-range colour.
priv struct C(Double, Double, Double, Double) derive(Debug)

///|
fn C::c(self : C) -> @color.Color {
  @color.rgba(self.0, self.1, self.2, self.3)
}

///|
impl @quickcheck.Arbitrary for C with fn arbitrary(_, rs) {
  let r = gen_unit(rs)
  let g = gen_unit(rs)
  let b = gen_unit(rs)
  C(r, g, b, gen_unit(rs))
}

///|
impl @quickcheck.Shrink for C with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.0, self.1, self.2, self.3))
  .filter(t => in_unit(t.0) && in_unit(t.1) && in_unit(t.2) && in_unit(t.3))
  .map(t => C(t.0, t.1, t.2, t.3))
}

///|
/// A possibly out-of-range colour (channels in [-1, 2]), e.g. the result of
/// `scale` or of arithmetic on colours.
priv struct CX(Double, Double, Double, Double) derive(Debug)

///|
fn CX::c(self : CX) -> @color.Color {
  @color.rgba(self.0, self.1, self.2, self.3)
}

///|
fn gen_wide(rs : @quickcheck.RandomState) -> Double {
  match rs.next_uint(limit=3) {
    0 => gen_unit(rs)
    _ => rs.next_double() * 3.0 - 1.0
  }
}

///|
impl @quickcheck.Arbitrary for CX with fn arbitrary(_, rs) {
  let r = gen_wide(rs)
  let g = gen_wide(rs)
  let b = gen_wide(rs)
  CX(r, g, b, gen_wide(rs))
}

///|
impl @quickcheck.Shrink for CX with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.0, self.1, self.2, self.3)).map(t => {
    CX(t.0, t.1, t.2, t.3)
  })
}

///|
/// A unit-interval scalar.
priv struct U(Double) derive(Debug)

///|
impl @quickcheck.Arbitrary for U with fn arbitrary(_, rs) {
  U(gen_unit(rs))
}

///|
impl @quickcheck.Shrink for U with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).filter(in_unit).map(x => U(x))
}

///|
/// A hue in degrees, including negative and > 360 values and exact sector
/// boundaries.
priv struct H(Double) derive(Debug)

///|
impl @quickcheck.Arbitrary for H with fn arbitrary(_, rs) {
  match rs.next_uint(limit=4) {
    0 => H((rs.next_uint(limit=13).reinterpret_as_int() - 6).to_double() * 60.0)
    1 => H((rs.next_double() - 0.5) * 2000.0)
    _ => H(rs.next_double() * 360.0)
  }
}

///|
impl @quickcheck.Shrink for H with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).map(x => H(x))
}

// ----- helpers -----

///|
fn dmax(a : Double, b : Double) -> Double {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn dmin(a : Double, b : Double) -> Double {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn in_unit(x : Double) -> Bool {
  x >= 0.0 && x <= 1.0
}

///|
fn color_in_unit(c : @color.Color) -> Bool {
  in_unit(c.r) && in_unit(c.g) && in_unit(c.b) && in_unit(c.a)
}

///|
fn near(a : Double, b : Double) -> Bool {
  (a - b).abs() <= 1.0e-9
}

///|
fn cnear(a : @color.Color, b : @color.Color) -> Bool {
  near(a.r, b.r) && near(a.g, b.g) && near(a.b, b.b) && near(a.a, b.a)
}

///|
fn hex_digit(c : Char) -> Int {
  match c {
    '0'..='9' => c.to_int() - '0'.to_int()
    'A'..='F' => c.to_int() - 'A'.to_int() + 10
    'a'..='f' => c.to_int() - 'a'.to_int() + 10
    _ => -1000
  }
}

///|
/// Parse "#RRGGBB" into byte values, or None if malformed.
fn parse_hex(s : String) -> (Int, Int, Int)? {
  let cs = s.to_array()
  guard cs.length() == 7 && cs[0] == '#' else { None }
  let d = Array::makei(6, i => hex_digit(cs[i + 1]))
  guard d.iter().all(x => x >= 0) else { None }
  Some((d[0] * 16 + d[1], d[2] * 16 + d[3], d[4] * 16 + d[5]))
}

///|
/// Reference RGB -> HSV (h in [0, 360), s, v in [0, 1]).
fn ref_to_hsv(c : @color.Color) -> (Double, Double, Double) {
  let mx = dmax(c.r, dmax(c.g, c.b))
  let mn = dmin(c.r, dmin(c.g, c.b))
  let d = mx - mn
  let h = if d == 0.0 {
    0.0
  } else if mx == c.r {
    60.0 * ((c.g - c.b) / d)
  } else if mx == c.g {
    60.0 * ((c.b - c.r) / d + 2.0)
  } else {
    60.0 * ((c.r - c.g) / d + 4.0)
  }
  let h = if h < 0.0 { h + 360.0 } else { h }
  let s = if mx == 0.0 { 0.0 } else { d / mx }
  (h, s, mx)
}

// ----- clamp -----

///|
test "qc: clamp lands in [0,1], is idempotent, and fixes in-range colours" {
  @quickcheck.check(
    (x : CX) => {
      let c = x.c()
      let k = @color.clamp(c)
      color_in_unit(k) && @color.clamp(k) == k && (!color_in_unit(c) || k == c)
    },
    observe=x => {
      [@quickcheck.classify(color_in_unit(x.c()), "already in range")]
    },
    seed=21,
  )
}

// ----- to_hex -----

///|
test "qc: to_hex is #RRGGBB and decodes to within one byte step" {
  @quickcheck.check(
    (x : C) => {
      let c = x.c()
      guard parse_hex(@color.to_hex(c)) is Some((r, g, b)) else { false }
      let step = 1.0 / 255.0
      (r.to_double() / 255.0 - c.r).abs() <= step &&
      (g.to_double() / 255.0 - c.g).abs() <= step &&
      (b.to_double() / 255.0 - c.b).abs() <= step
    },
    seed=22,
  )
}

///|
test "qc: to_hex encodes byte-exact colours exactly" {
  @quickcheck.check(
    (bytes : (Byte, Byte, Byte)) => {
      let (r, g, b) = bytes
      let c = @color.rgb(
        r.to_int().to_double() / 255.0,
        g.to_int().to_double() / 255.0,
        b.to_int().to_double() / 255.0,
      )
      parse_hex(@color.to_hex(c)) == Some((r.to_int(), g.to_int(), b.to_int()))
    },
    seed=23,
  )
}

///|
test "qc: to_hex of an out-of-range colour is the hex of the clamped colour" {
  @quickcheck.check(
    (x : CX) => {
      let c = x.c()
      @color.to_hex(c) == @color.to_hex(@color.clamp(c))
    },
    seed=24,
  )
}

// ----- hsv -----

///|
test "qc: hsv stays in range with max = v and min = v(1-s)" {
  @quickcheck.check(
    (input : (H, U, U)) => {
      let (h, s, v) = input
      let c = @color.hsv(h.0, s.0, v.0)
      let mx = dmax(c.r, dmax(c.g, c.b))
      let mn = dmin(c.r, dmin(c.g, c.b))
      color_in_unit(c) &&
      c.a == 1.0 &&
      near(mx, v.0) &&
      near(mn, v.0 * (1.0 - s.0))
    },
    observe=input => {
      [
        @quickcheck.classify(
          input.0.0 < 0.0 || input.0.0 >= 360.0,
          "hue outside [0,360)",
        ),
        @quickcheck.classify(input.0.0 % 60.0 == 0.0, "sector boundary"),
      ]
    },
    seed=25,
  )
}

///|
test "qc: hsv is 360-periodic in hue" {
  @quickcheck.check(
    (input : (H, U, U)) => {
      let (h, s, v) = input
      let a = @color.hsv(h.0, s.0, v.0)
      let b = @color.hsv(h.0 + 360.0, s.0, v.0)
      let c = @color.hsv(h.0 - 720.0, s.0, v.0)
      (a.r - b.r).abs() <= 1.0e-6 &&
      (a.g - b.g).abs() <= 1.0e-6 &&
      (a.b - b.b).abs() <= 1.0e-6 &&
      (a.r - c.r).abs() <= 1.0e-6 &&
      (a.g - c.g).abs() <= 1.0e-6 &&
      (a.b - c.b).abs() <= 1.0e-6
    },
    seed=26,
  )
}

///|
test "qc: hsv -> rgb -> hsv -> rgb round-trips" {
  @quickcheck.check(
    (input : (H, U, U)) => {
      let (h, s, v) = input
      let c = @color.hsv(h.0, s.0, v.0)
      let (h2, s2, v2) = ref_to_hsv(c)
      let c2 = @color.hsv(h2, s2, v2)
      (c.r - c2.r).abs() <= 1.0e-9 &&
      (c.g - c2.g).abs() <= 1.0e-9 &&
      (c.b - c2.b).abs() <= 1.0e-9 &&
      near(v2, v.0)
    },
    seed=27,
  )
}

// ----- interpolation and scaling -----

///|
test "qc: lerp_color hits endpoints, clamps t, and stays between them" {
  @quickcheck.check(
    (input : (C, C, Double)) => {
      let (a, b, t) = input
      let (c1, c2) = (a.c(), b.c())
      let t = if t.is_nan() || t.is_inf() { 0.5 } else { t }
      let m = @color.lerp_color(c1, c2, t)
      fn between(x : Double, lo : Double, hi : Double) -> Bool {
        x >= dmin(lo, hi) - 1.0e-12 && x <= dmax(lo, hi) + 1.0e-12
      }

      @color.lerp_color(c1, c2, 0.0) == c1 &&
      cnear(@color.lerp_color(c1, c2, 1.0), c2) &&
      @color.lerp_color(c1, c2, -5.0) == c1 &&
      @color.lerp_color(c1, c2, 7.0) == @color.lerp_color(c1, c2, 1.0) &&
      between(m.r, c1.r, c2.r) &&
      between(m.g, c1.g, c2.g) &&
      between(m.b, c1.b, c2.b) &&
      between(m.a, c1.a, c2.a)
    },
    seed=28,
  )
}

///|
test "qc: scale by 1 is identity, keeps alpha, and composes" {
  @quickcheck.check(
    (input : (C, U, U)) => {
      let (a, k, l) = input
      let c = a.c()
      let s = @color.scale(@color.scale(c, k.0), l.0)
      let t = @color.scale(c, k.0 * l.0)
      @color.scale(c, 1.0) == c && s.a == c.a && cnear(s, t)
    },
    seed=29,
  )
}

// ----- compositing -----

///|
test "qc: blend (source-over) identities and alpha law" {
  @quickcheck.check(
    (input : (C, C)) => {
      let (x, y) = input
      let (top, bottom) = (x.c(), y.c())
      let out = @color.blend(top, bottom)
      let opaque_top = @color.rgba(top.r, top.g, top.b, 1.0)
      color_in_unit(out) &&
      near(out.a, top.a + bottom.a * (1.0 - top.a)) &&
      // opaque top hides the bottom
      cnear(@color.blend(opaque_top, bottom), opaque_top) &&
      // a fully transparent top leaves an (non-transparent) bottom unchanged
      (
        bottom.a == 0.0 ||
        cnear(@color.blend(@color.transparent(), bottom), bottom)
      ) &&
      // over a fully transparent bottom, a visible top is unchanged
      (top.a == 0.0 || cnear(@color.blend(top, @color.transparent()), top))
    },
    observe=input => {
      [
        @quickcheck.classify(input.0.3 == 0.0, "transparent top"),
        @quickcheck.classify(input.0.3 == 1.0, "opaque top"),
      ]
    },
    seed=30,
  )
}

///|
test "qc: blend (source-over) is associative" {
  @quickcheck.check(
    (input : (C, C, C)) => {
      let (x, y, z) = input
      let (a, b, c) = (x.c(), y.c(), z.c())
      let l = @color.blend(@color.blend(a, b), c)
      let r = @color.blend(a, @color.blend(b, c))
      // colour channels are irrelevant when the result is fully transparent
      near(l.a, r.a) &&
      (
        l.a < 1.0e-6 ||
        (
          (l.r - r.r).abs() <= 1.0e-6 &&
          (l.g - r.g).abs() <= 1.0e-6 &&
          (l.b - r.b).abs() <= 1.0e-6
        )
      )
    },
    seed=31,
  )
}

///|
test "qc: multiply / screen blends are commutative, dual, with identities" {
  @quickcheck.check(
    (input : (C, C)) => {
      let (x, y) = input
      let (a, b) = (x.c(), y.c())
      fn inv(c : @color.Color) -> @color.Color {
        @color.rgba(1.0 - c.r, 1.0 - c.g, 1.0 - c.b, c.a)
      }

      let m = @color.multiply_blend(a, b)
      let s = @color.screen_blend(a, b)
      let dual = inv(@color.multiply_blend(inv(a), inv(b)))
      color_in_unit(m) &&
      color_in_unit(s) &&
      cnear(m, @color.multiply_blend(b, a)) &&
      cnear(s, @color.screen_blend(b, a)) &&
      near(s.r, dual.r) &&
      near(s.g, dual.g) &&
      near(s.b, dual.b) &&
      near(@color.multiply_blend(a, @color.white()).r, a.r) &&
      near(@color.screen_blend(a, @color.black()).g, a.g)
    },
    seed=32,
  )
}

///|
test "qc: overlay / hard-light / soft-light stay in range" {
  @quickcheck.check(
    (input : (C, C)) => {
      let (x, y) = input
      let (a, b) = (x.c(), y.c())
      color_in_unit(@color.overlay_blend(a, b)) &&
      color_in_unit(@color.hard_light_blend(a, b)) &&
      color_in_unit(@color.soft_light_blend(a, b))
    },
    seed=33,
  )
}

///|
test "regression: to_hex of an out-of-range colour does not abort" {
  // previously indexed past the 16-entry digit table (1.5 * 255 = 382)
  inspect(@color.to_hex(@color.rgb(1.5, -0.25, 0.5)), content="#FF007F")
  inspect(@color.to_hex(@color.scale(@color.orange(), 2.0)), content="#FFFF00")
}
