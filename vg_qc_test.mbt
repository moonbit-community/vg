// Property-based tests (moonbitlang/core/quickcheck) for the image algebra and
// its renderers: `eval` semantics under transforms, consistency of the baked
// draw list with the image tree, and well-formedness of SVG / PDF / canvas
// output.

// ----- generators -----

///|
fn gen_double(rs : @quickcheck.RandomState) -> Double {
  match rs.next_uint(limit=9) {
    // the half-extents of the 320 x 240 canvases used below: such points
    // land exactly on the canvas edge, where rounding leaves tiny residues
    8 =>
      [160.0, -160.0, 120.0, -120.0][rs.next_uint(limit=4).reinterpret_as_int()]
    0 => (rs.next_uint(limit=21).reinterpret_as_int() - 10).to_double()
    1 => 0.0
    2 => (rs.next_uint(limit=33).reinterpret_as_int() - 16).to_double() / 8.0
    3 => (rs.next_double() - 0.5) * 1.0e-6
    _ => (rs.next_double() - 0.5) * 200.0
  }
}

///|
fn gen_small(rs : @quickcheck.RandomState) -> Double {
  (rs.next_double() - 0.5) * 8.0
}

///|
fn gen_pos(rs : @quickcheck.RandomState) -> Double {
  match rs.next_uint(limit=5) {
    0 => 0.0
    // full-canvas extents (e.g. a background rectangle)
    4 => [320.0, 240.0][rs.next_uint(limit=2).reinterpret_as_int()]
    1 => (rs.next_uint(limit=10).reinterpret_as_int() + 1).to_double() * 5.0
    _ => rs.next_double() * 100.0
  }
}

///|
fn gen_unit(rs : @quickcheck.RandomState) -> Double {
  match rs.next_uint(limit=5) {
    0 => 0.0
    1 => 1.0
    2 => rs.next_uint(limit=256).reinterpret_as_int().to_double() / 255.0
    _ => rs.next_double()
  }
}

///|
fn gen_color(rs : @quickcheck.RandomState) -> @color.Color {
  let r = gen_unit(rs)
  let g = gen_unit(rs)
  let b = gen_unit(rs)
  @color.rgba(r, g, b, gen_unit(rs))
}

///|
fn gen_point(rs : @quickcheck.RandomState) -> @geometry.Point {
  let x = gen_double(rs)
  Point(x, gen_double(rs))
}

///|
/// Text with markup-significant characters, quotes, backslashes, control
/// characters and non-BMP code points mixed into arbitrary strings.
fn gen_text(rs : @quickcheck.RandomState) -> String {
  let specials = [
    "<", ">", "&", "\"", "'", "\\", "(", ")", "\n", "\r", "\t", "]]>", "&amp;", "😀",
    "é", "\u{2028}", "</text>", "--",
  ]
  let sb = StringBuilder()
  let n = rs.next_uint(limit=6).reinterpret_as_int()
  for _ in 0..<n {
    match rs.next_uint(limit=3) {
      0 =>
        sb.write_string(
          specials[rs
          .next_uint(limit=specials.length().reinterpret_as_uint())
          .reinterpret_as_int()],
        )
      1 =>
        sb.write_char(
          Int::unsafe_to_char(
            0x20 + rs.next_uint(limit=95).reinterpret_as_int(),
          ),
        )
      _ => {
        let s : String = @quickcheck.Arbitrary::arbitrary(4, rs)
        sb.write_string(s)
      }
    }
  }
  sb.to_string()
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
fn gen_op(rs : @quickcheck.RandomState) -> Op {
  match rs.next_uint(limit=5) {
    0 =>
      if rs.next_uint(limit=2) == 0 {
        // quarter turns: cos/sin leave ~1e-16 residues
        Rot(
          (rs.next_uint(limit=8).reinterpret_as_int() - 4).to_double() *
          3.141592653589793 /
          2.0,
        )
      } else {
        Rot(gen_small(rs))
      }
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
fn gen_ops(rs : @quickcheck.RandomState) -> Array[Op] {
  let n = 1 + rs.next_uint(limit=3).reinterpret_as_int()
  Array::makei(n, _ => gen_op(rs))
}

///|
/// A chain of primitive transforms applied innermost-first, as the image
/// combinators do (`img.transform(a).transform(b)` = `Tr(b, Tr(a, img))`).
priv struct Ops(Array[Op]) derive(Debug)

///|
impl @quickcheck.Arbitrary for Ops with fn arbitrary(_, rs) {
  Ops(gen_ops(rs))
}

///|
impl @quickcheck.Shrink for Ops with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0)
  .filter(a => a.length() > 0)
  .map(a => Ops(a))
}

///|
/// Apply the chain to a point (reference semantics, no composition).
fn Ops::apply(self : Ops, p : @geometry.Point) -> @geometry.Point {
  let mut q = p
  for op in self.0 {
    q = @geometry.apply(op.tr(), q)
  }
  q
}

///|
fn Ops::wrap(self : Ops, img : @vg.Image) -> @vg.Image {
  let mut out = img
  for op in self.0 {
    out = out.transform(op.tr())
  }
  out
}

///|
fn gen_path(rs : @quickcheck.RandomState, arcs : Bool) -> @geometry.Path {
  let n = 1 + rs.next_uint(limit=6).reinterpret_as_int()
  let mut p = @geometry.Path::empty().move_to(gen_point(rs))
  for _ in 0..<n {
    p = match rs.next_uint(limit=if arcs { 6 } else { 5 }) {
      0 | 1 => p.line_to(gen_point(rs))
      2 => {
        let a = gen_point(rs)
        let b = gen_point(rs)
        p.curve_to(a, b, gen_point(rs))
      }
      3 => {
        let a = gen_point(rs)
        p.qcurve_to(a, gen_point(rs))
      }
      4 =>
        if rs.next_uint(limit=3) == 0 {
          p.close_path().move_to(gen_point(rs))
        } else {
          p.line_to(gen_point(rs))
        }
      _ => {
        let rx = gen_pos(rs)
        let ry = gen_pos(rs)
        let rot = rs.next_double() * 360.0
        let la = rs.next_uint(limit=2) == 0
        let sw = rs.next_uint(limit=2) == 0
        p.earc_to(rx, ry, rot, la, sw, gen_point(rs))
      }
    }
  }
  if rs.next_uint(limit=2) == 0 {
    p.close_path()
  } else {
    p
  }
}

///|
/// A printable description of an image tree (Image itself holds closures and
/// has no Debug).
priv enum ImgD {
  Const(@color.Color)
  Circle(@color.Color, Double)
  Rect(@color.Color, Double, Double)
  Poly(@color.Color, Array[@geometry.Point])
  Line(@color.Color, @geometry.Point, @geometry.Point, Double)
  LinGrad(@color.Color, @color.Color, @geometry.Point, @geometry.Point)
  RadGrad(@color.Color, @color.Color, @geometry.Point, Double)
  Txt(String, Double, @color.Color)
  Checker(@color.Color, @color.Color, Double)
  CutD(@vg.Area, @geometry.Path, ImgD)
  BlendD(@vg.Blender, Double?, ImgD, ImgD)
  TrD(Array[Op], ImgD)
  Opacity(Double, ImgD)
} derive(Debug)

///|
fn ImgD::image(self : ImgD) -> @vg.Image {
  match self {
    Const(c) => @vg.Image::const_color(c)
    Circle(c, r) => @vg.Image::circle(c, r)
    Rect(c, w, h) => @vg.Image::rectangle(c, w, h)
    Poly(c, pts) => @vg.Image::polygon(c, pts)
    Line(c, a, b, w) => @vg.Image::line(c, a, b, w)
    LinGrad(c1, c2, a, b) => @vg.Image::linear_gradient(c1, c2, a, b)
    RadGrad(c1, c2, a, r) => @vg.Image::radial_gradient(c1, c2, a, r)
    Txt(s, size, c) => @vg.Image::text(s, size, c)
    Checker(c1, c2, size) => @vg.Image::checkerboard(c1, c2, size)
    CutD(area, path, img) => img.image().cut(path, area~)
    BlendD(op, alpha, top, bottom) =>
      match alpha {
        Some(a) => top.image().blend(bottom.image(), op~, alpha=a)
        None => top.image().blend(bottom.image(), op~)
      }
    TrD(ops, img) => Ops(ops).wrap(img.image())
    Opacity(a, img) => img.image().with_opacity(a)
  }
}

///|
fn gen_img(rs : @quickcheck.RandomState, depth : Int, raster : Bool) -> ImgD {
  let leaf = depth <= 0 || rs.next_uint(limit=3) == 0
  if leaf {
    match rs.next_uint(limit=if raster { 10 } else { 9 }) {
      0 => Const(gen_color(rs))
      1 => Circle(gen_color(rs), gen_pos(rs))
      2 => {
        let c = gen_color(rs)
        let w = gen_pos(rs)
        Rect(c, w, gen_pos(rs))
      }
      3 => {
        let c = gen_color(rs)
        let n = rs.next_uint(limit=6).reinterpret_as_int()
        Poly(c, Array::makei(n, _ => gen_point(rs)))
      }
      4 => {
        let c = gen_color(rs)
        let a = gen_point(rs)
        let b = gen_point(rs)
        Line(c, a, b, gen_pos(rs))
      }
      5 => {
        let c1 = gen_color(rs)
        let c2 = gen_color(rs)
        let a = gen_point(rs)
        LinGrad(c1, c2, a, gen_point(rs))
      }
      6 => {
        let c1 = gen_color(rs)
        let c2 = gen_color(rs)
        let a = gen_point(rs)
        RadGrad(c1, c2, a, gen_pos(rs))
      }
      7 | 8 => {
        let s = gen_text(rs)
        let size = gen_pos(rs)
        Txt(s, size, gen_color(rs))
      }
      _ => {
        let c1 = gen_color(rs)
        let c2 = gen_color(rs)
        Checker(c1, c2, 1.0 + gen_pos(rs))
      }
    }
  } else {
    match rs.next_uint(limit=5) {
      0 => {
        let area = match rs.next_uint(limit=3) {
          0 => @vg.Area::Anz
          1 => Aeo
          _ => Outline(gen_pos(rs))
        }
        let path = gen_path(rs, true)
        // outline cuts of composite images are rasterised: keep them rare
        let inner = gen_img(rs, depth - 1, raster && area is (Anz | Aeo))
        CutD(area, path, inner)
      }
      1 => {
        // non-Over operators are rasterised: only when raster is allowed
        let op = if raster && rs.next_uint(limit=4) == 0 {
          [@vg.Blender::Plus, Copy, In, Out, Atop, Xor][rs
          .next_uint(limit=6)
          .reinterpret_as_int()]
        } else {
          Over
        }
        let alpha = if rs.next_uint(limit=2) == 0 {
          None
        } else {
          Some(gen_unit(rs))
        }
        let top = gen_img(rs, depth - 1, raster)
        BlendD(op, alpha, top, gen_img(rs, depth - 1, raster))
      }
      2 | 3 => {
        let ops = gen_ops(rs)
        TrD(ops, gen_img(rs, depth - 1, raster))
      }
      _ => {
        let a = gen_unit(rs)
        Opacity(a, gen_img(rs, depth - 1, raster))
      }
    }
  }
}

///|
fn ImgD::children(self : ImgD) -> Array[ImgD] {
  match self {
    CutD(_, _, i) | TrD(_, i) | Opacity(_, i) => [i]
    BlendD(_, _, a, b) => [a, b]
    _ => []
  }
}

///|
/// An image tree without raster fallbacks (cheap to render).
priv struct Img(ImgD) derive(Debug)

///|
impl @quickcheck.Arbitrary for Img with fn arbitrary(size, rs) {
  Img(gen_img(rs, imin(size / 10, 4), false))
}

///|
impl @quickcheck.Shrink for Img with fn shrink(self) {
  self.0.children().iter().map(c => Img(c))
}

///|
/// An image tree that may contain raster fallbacks (procedural primitives,
/// non-Over blends).
priv struct RImg(ImgD) derive(Debug)

///|
impl @quickcheck.Arbitrary for RImg with fn arbitrary(size, rs) {
  RImg(gen_img(rs, imin(size / 20, 2), true))
}

///|
impl @quickcheck.Shrink for RImg with fn shrink(self) {
  self.0.children().iter().map(c => RImg(c))
}

///|
priv struct Pt(Double, Double) derive(Debug)

///|
impl @quickcheck.Arbitrary for Pt with fn arbitrary(_, rs) {
  let x = gen_double(rs)
  Pt(x, gen_double(rs))
}

///|
impl @quickcheck.Shrink for Pt with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.0, self.1)).map(t => Pt(t.0, t.1))
}

///|
/// A point biased towards the corners / edges of a 320 x 240 canvas.
priv struct EPt(Double, Double) derive(Debug)

///|
fn gen_edge(rs : @quickcheck.RandomState, half : Double) -> Double {
  match rs.next_uint(limit=4) {
    0 => half
    1 => -half
    _ => gen_double(rs)
  }
}

///|
impl @quickcheck.Arbitrary for EPt with fn arbitrary(_, rs) {
  let x = gen_edge(rs, 160.0)
  EPt(x, gen_edge(rs, 120.0))
}

///|
impl @quickcheck.Shrink for EPt with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.0, self.1)).map(t => EPt(t.0, t.1))
}

///|
fn EPt::pt(self : EPt) -> @geometry.Point {
  Point(self.0, self.1)
}

///|
fn Pt::pt(self : Pt) -> @geometry.Point {
  Point(self.0, self.1)
}

// ----- helpers -----

///|
fn imin(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn is_name_char(c : Char) -> Bool {
  c is ('a'..='z' | 'A'..='Z' | '0'..='9' | '-' | ':')
}

///|
fn close(a : Double, b : Double, scale : Double) -> Bool {
  (a - b).abs() <= 1.0e-7 * (1.0 + scale.abs() + a.abs() + b.abs())
}

///|
fn pclose(p : @geometry.Point, q : @geometry.Point, scale : Double) -> Bool {
  close(p.x, q.x, scale) && close(p.y, q.y, scale)
}

///|
fn has_prefix_at(s : String, i : Int, pre : String) -> Bool {
  let cs = s.to_array()
  let ps = pre.to_array()
  guard i + ps.length() <= cs.length() else { false }
  for k in 0..<ps.length() {
    if cs[i + k] != ps[k] {
      return false
    }
  }
  true
}

///|
/// A small XML well-formedness checker for the SVG we emit: balanced,
/// properly nested tags with a single `svg` root; attributes of the form
/// name="value" whose values contain no raw `<` or `"` and only valid entity
/// references; no stray character data outside `<text>` (whitespace aside);
/// no `NaN` / `Infinity` anywhere. Returns an error description or None.
fn xml_problem(doc : String) -> String? {
  let cs = doc.to_array()
  let n = cs.length()
  let mut i = 0
  let stack : Array[String] = []
  let mut roots = 0
  fn valid_entity(at : Int) -> Bool {
    for e in ["&amp;", "&lt;", "&gt;", "&quot;", "&apos;"] {
      if has_prefix_at(doc, at, e) {
        return true
      }
    }
    false
  }

  if has_prefix_at(doc, 0, "<?xml") {
    while i < n && !(cs[i] == '?' && i + 1 < n && cs[i + 1] == '>') {
      i += 1
    }
    i += 2
  }
  while i < n {
    let c = cs[i]
    if c == '<' {
      let closing = i + 1 < n && cs[i + 1] == '/'
      let mut j = if closing { i + 2 } else { i + 1 }
      let name_start = j
      while j < n && (is_name_char(cs[j]) || false) {
        j += 1
      }
      let name = String::from_array(cs[name_start:j].iter().collect())
      if name.length() == 0 {
        return Some("empty tag name at \{i}")
      }
      // attributes
      let mut self_closing = false
      while true {
        while j < n && cs[j] == ' ' {
          j += 1
        }
        guard j < n else { return Some("unterminated tag <\{name}") }
        if cs[j] == '>' {
          j += 1
          break
        }
        if cs[j] == '/' && j + 1 < n && cs[j + 1] == '>' && !closing {
          self_closing = true
          j += 2
          break
        }
        if closing {
          return Some("junk in closing tag </\{name}")
        }
        let an = j
        while j < n && (is_name_char(cs[j]) || false) {
          j += 1
        }
        if j == an {
          return Some("bad attribute in <\{name}> at \{j}: '\{cs[j]}'")
        }
        guard j + 1 < n && cs[j] == '=' && cs[j + 1] == '"' else {
          return Some("attribute without =\"...\" in <\{name}>")
        }
        j += 2
        while j < n && cs[j] != '"' {
          if cs[j] == '<' {
            return Some("raw '<' in attribute of <\{name}>")
          }
          if cs[j] == '&' && !valid_entity(j) {
            return Some("bad entity in attribute of <\{name}>")
          }
          j += 1
        }
        guard j < n else { return Some("unterminated attribute in <\{name}>") }
        j += 1 // closing quote
        guard j < n && (cs[j] == ' ' || cs[j] == '>' || cs[j] == '/') else {
          return Some("attributes not separated in <\{name}>")
        }
      }
      if closing {
        guard stack.pop() is Some(top) && top == name else {
          return Some("mismatched </\{name}>")
        }
      } else {
        if stack.length() == 0 {
          roots += 1
          if name != "svg" {
            return Some("root element is <\{name}>")
          }
        }
        if !self_closing {
          stack.push(name)
        }
      }
      i = j
    } else {
      // character data
      let in_text = stack.length() > 0 && stack[stack.length() - 1] == "text"
      if c == '&' && !valid_entity(i) {
        return Some("bad entity in character data at \{i}")
      }
      if !in_text && !(c == ' ' || c == '\n' || c == '\t' || c == '\r') {
        return Some("stray character data '\{c}' at \{i}")
      }
      if c == '>' && !in_text {
        return Some("stray '>' at \{i}")
      }
      i += 1
    }
  }
  if stack.length() != 0 {
    return Some("unclosed <\{stack[stack.length() - 1]}>")
  }
  if roots != 1 {
    return Some("\{roots} root elements")
  }
  None
}

///|
/// Keep a failure context readable (and parseable by the test driver): only
/// printable ASCII and newlines pass through, anything else is shown as
/// `<U+XXXX>`.
fn printable(s : String) -> String {
  let sb = StringBuilder()
  for c in s {
    if c == '\n' || (c >= ' ' && c <= '~' && c != '\\') {
      sb.write_char(c)
    } else {
      sb.write_string("<U+\{c.to_int().to_string(radix=16)}>")
    }
  }
  sb.to_string()
}

///|
fn non_finite_literal(s : String) -> Bool {
  s.contains("NaN") || s.contains("Infinity")
}

///|
/// Whether `s` contains a number in exponent notation (`1e-7`, `2.5e+21`),
/// which PDF content streams do not accept.
fn has_exponent_number(s : String) -> Bool {
  let cs = s.to_array()
  for i in 1..<(cs.length() - 1) {
    if cs[i] == 'e' &&
      cs[i - 1].is_ascii_digit() &&
      (cs[i + 1] == '-' || cs[i + 1] == '+' || cs[i + 1].is_ascii_digit()) {
      return true
    }
  }
  false
}

///|
fn draw_list_balanced(cmds : Array[@vg.DrawCmd]) -> Bool {
  let stack : Array[Int] = []
  for cmd in cmds {
    match cmd {
      PushClip(_, _) => stack.push(0)
      PushOpacity(_) => stack.push(1)
      PopClip => if !(stack.pop() is Some(0)) { return false }
      PopOpacity => if !(stack.pop() is Some(1)) { return false }
      _ => ()
    }
  }
  stack.length() == 0
}

///|
fn fill_paths(cmds : Array[@vg.DrawCmd]) -> Array[@geometry.Path] {
  let out = []
  for cmd in cmds {
    if cmd is FillPath(p, _, _) {
      out.push(p)
    }
  }
  out
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

// ----- eval semantics -----

///|
test "qc: eval of a transformed image at t(p) equals eval at p" {
  // a colour field that encodes the sample point, so eval exposes exactly
  // where the transform chain pulls the point back to
  let probe = @vg.Image::of_fn(q => @color.rgba(q.x, q.y, 0.0, 1.0))
  @quickcheck.check(
    (input : (Ops, Pt)) => {
      let (ops, p) = input
      let q = ops.apply(p.pt())
      let c = ops.wrap(probe).eval(q)
      let scale = 1.0e4 * (1.0 + q.x.abs() + q.y.abs() + p.0.abs() + p.1.abs())
      close(c.r, p.0, scale) && close(c.g, p.1, scale)
    },
    // only well-conditioned chains, so the pull-back is numerically stable
    filter=input => {
      let mut t = @geometry.identity()
      for op in input.0.0 {
        t = @geometry.compose_transforms(t, op.tr())
      }
      let lin = t.m11.abs() + t.m12.abs() + t.m21.abs() + t.m22.abs()
      @geometry.determinant(t).abs() >= 1.0e-2 * lin * lin
    },
    observe=input => {
      [
        @quickcheck.classify(input.0.0.length() > 1, "chain of 2+ transforms"),
        @quickcheck.classify(
          input.0.0.iter().any(o => o is Rot(_)) &&
          input.0.0.iter().any(o => o is Trans(_, _)),
          "rotation and translation",
        ),
      ]
    },
    seed=41,
  )
}

///|
test "qc: a cut is transparent outside its path's bounds and opaque at vertices" {
  @quickcheck.check(
    (input : (Pt, Pt, Pt, Pt)) => {
      let (a, b, c, d) = input
      let pts = [a.pt(), b.pt(), c.pt()]
      let img = @vg.Image::polygon(@color.red(), pts)
      guard @geometry.Path::empty()
        .move_to(pts[0])
        .line_to(pts[1])
        .line_to(pts[2])
        .bounds()
        is Some(bx) else {
        false
      }
      let q = d.pt()
      let outside = q.x < bx.min_x ||
        q.x > bx.max_x ||
        q.y < bx.min_y ||
        q.y > bx.max_y
      // boundary points count as inside (documented in eval.mbt)
      pts.iter().all(p => img.eval(p) == @color.red()) &&
      (!outside || img.eval(q) == @color.transparent())
    },
    seed=42,
  )
}

///|
test "qc: over / compose / with_opacity agree with colour blending" {
  @quickcheck.check(
    (input : (Img, Img, Pt)) => {
      let (a, b, p) = input
      let (top, bottom) = (a.0.image(), b.0.image())
      let q = p.pt()
      top.over(bottom).eval(q) == @color.blend(top.eval(q), bottom.eval(q)) &&
      bottom.compose(top).eval(q) == top.over(bottom).eval(q) &&
      top.with_opacity(1.0).eval(q) ==
      @color.blend(top.eval(q), @color.transparent())
    },
    seed=43,
  )
}

// ----- draw list -----

///|
test "qc: the draw list bakes nested transforms like eval does" {
  let (w, h) = (300.0, 200.0)
  @quickcheck.check(
    (input : (Ops, Pt, Pt, Pt)) => {
      let (ops, a, b, c) = input
      let pts = [a.pt(), b.pt(), c.pt()]
      let img = ops.wrap(@vg.Image::polygon(@color.blue(), pts))
      guard fill_paths(img.to_draw_list(w, h)) is [path] else { false }
      let got = path_points(path)
      guard got.length() == 3 else { false }
      let mut ok = true
      for i, p in pts {
        let q = ops.apply(p)
        let expected = @geometry.Point::Point(q.x + w / 2.0, q.y + h / 2.0)
        ok = ok && pclose(got[i], expected, expected.x.abs() + expected.y.abs())
      }
      ok
    },
    observe=input => {
      [@quickcheck.classify(input.0.0.length() > 1, "chain of 2+ transforms")]
    },
    seed=44,
  )
}

///|
test "regression: rotating a translated image bakes the right translation" {
  // Tr(rotate(pi/2), Tr(translate(10, 0), polygon)): the vertex (0,0) moves to
  // (10,0) then rotates to (0,10); the canvas centre adds (50, 50).
  let img = @vg.Image::polygon(@color.red(), [
      Point(0.0, 0.0),
      Point(1.0, 0.0),
      Point(0.0, 1.0),
    ])
    .translate_img(10.0, 0.0)
    .rotate(3.141592653589793 / 2.0)
  guard img.to_draw_list(100.0, 100.0) is [FillPath(path, _, _)] else {
    fail("expected a single FillPath")
  }
  guard path.0 is [MoveTo(p), ..] else { fail("expected a MoveTo") }
  // previously baked to (60, 50): the translation was rotated the wrong way
  assert_true((p.x - 50.0).abs() < 1.0e-9)
  assert_true((p.y - 60.0).abs() < 1.0e-9)
}

///|
test "qc: draw lists keep clip / opacity brackets balanced" {
  @quickcheck.check(
    (x : RImg) => draw_list_balanced(x.0.image().to_draw_list(64.0, 48.0)),
    observe=x => {
      let cmds = x.0.image().to_draw_list(64.0, 48.0)
      [
        @quickcheck.classify(
          cmds.iter().any(c => c is PushClip(_, _)),
          "has clip",
        ),
        @quickcheck.classify(
          cmds.iter().any(c => c is PushOpacity(_)),
          "has opacity group",
        ),
        @quickcheck.classify(
          cmds.iter().any(c => c is RasterCell(_, _, _, _, _)),
          "has raster cells",
        ),
      ]
    },
    count=40,
    seed=45,
  )
}

// ----- renderer output well-formedness -----

///|
test "qc: Image::to_svg is well-formed XML with only finite numbers" {
  @quickcheck.check(
    (x : Img) => {
      let svg = x.0.image().to_svg(320.0, 240.0)
      xml_problem(svg) is None && !non_finite_literal(svg)
    },
    counterexample_context=x => {
      let svg = x.0.image().to_svg(320.0, 240.0)
      let problem = match xml_problem(svg) {
        Some(p) => p
        None => "no XML problem"
      }
      printable("\{problem}\n\{svg}")
    },
    observe=x => {
      let svg = x.0.image().to_svg(320.0, 240.0)
      [
        @quickcheck.classify(svg.contains("<text"), "has text"),
        @quickcheck.classify(svg.contains("<clipPath"), "has clip"),
        @quickcheck.classify(svg.contains("Gradient"), "has gradient"),
        @quickcheck.classify(svg.contains(" A "), "has arc"),
      ]
    },
    seed=46,
  )
}

///|
/// Whether a PDF document has balanced `q`/`Q` operators and only finite,
/// plain-decimal numbers (PDF has no exponent notation) outside text strings.
fn pdf_well_formed(pdf : String) -> Bool {
  let mut depth = 0
  let mut ok = true
  for line in pdf.split("\n") {
    if line == "q" {
      depth += 1
    } else if line == "Q" {
      depth -= 1
      ok = ok && depth >= 0
    }
    // text-showing lines carry user text: exempt from number checks
    if !line.has_suffix(" Tj") {
      let l = line.to_owned()
      ok = ok && !non_finite_literal(l) && !has_exponent_number(l)
    }
  }
  ok && depth == 0
}

///|
test "qc: Image::to_pdf has balanced q/Q, finite plain-decimal numbers" {
  @quickcheck.check(
    (x : Img) => pdf_well_formed(x.0.image().to_pdf(320.0, 240.0)),
    counterexample_context=x => printable(x.0.image().to_pdf(320.0, 240.0)),
    seed=47,
  )
}

///|
test "qc: to_pdf of transformed canvas-aligned shapes uses plain decimals" {
  // points on the canvas edges plus quarter turns / flips: rounding residues
  // such as 2.8e-14 must not be printed in exponent notation
  @quickcheck.check(
    (input : (Ops, EPt, EPt, EPt)) => {
      let (ops, a, b, c) = input
      let img = ops.wrap(
        @vg.Image::polygon(@color.red(), [a.pt(), b.pt(), c.pt()]),
      )
      pdf_well_formed(img.to_pdf(320.0, 240.0))
    },
    observe=input => {
      [
        @quickcheck.classify(
          input.0.0.iter().any(o => o is Rot(_)),
          "has rotation",
        ),
      ]
    },
    counterexample_context=input => {
      let (ops, a, b, c) = input
      ops
      .wrap(@vg.Image::polygon(@color.red(), [a.pt(), b.pt(), c.pt()]))
      .to_pdf(320.0, 240.0)
    },
    count=300,
    seed=50,
  )
}

///|
test "regression: to_pdf prints rounding residues as plain decimals" {
  let img = @vg.Image::rectangle(@color.red(), 320.0, 240.0).rotate(
    3.141592653589793,
  )
  let pdf = img.to_pdf(320.0, 240.0)
  // previously emitted `2.842170943040401e-14 0 l`
  assert_true(pdf_well_formed(pdf))
  assert_false(pdf.contains("e-14"))
}

///|
test "qc: Image::to_js has balanced save/restore and finite numbers" {
  @quickcheck.check(
    (x : Img) => {
      let js = x.0.image().to_js(320.0, 240.0)
      let mut depth = 0
      let mut ok = true
      for line in js.split("\n") {
        let l = line.trim_start(chars=" ").to_owned()
        if l == "ctx.save();" {
          depth += 1
        } else if l == "ctx.restore();" {
          depth -= 1
          ok = ok && depth >= 0
        }
        if !l.has_prefix("ctx.fillText(") {
          ok = ok && !non_finite_literal(l)
        } else {
          // the text literal must be closed: `ctx.fillText('...', x, y);`
          ok = ok && l.has_suffix(");") && !l.contains("\n")
        }
      }
      ok && depth == 0
    },
    seed=48,
  )
}

///|
/// Build an `SvgDocument` from a list of operation codes, drawing the
/// operations' arguments from a generator seeded with `seed`.
fn build_svg_doc(ops : Array[UInt], seed : UInt64) -> String {
  let rs = @splitmix.new(seed~)
  let mut doc = @svg.new_svg(gen_pos(rs), gen_pos(rs))
  for op in ops {
    doc = match op % 8 {
      0 => doc.render_circle(gen_point(rs), gen_pos(rs), gen_color(rs))
      1 => {
        let x = gen_double(rs)
        let y = gen_double(rs)
        let w = gen_pos(rs)
        doc.render_rectangle(x, y, w, gen_pos(rs), gen_color(rs))
      }
      2 => doc.render_path(gen_path(rs, true), gen_color(rs))
      3 => {
        let a = gen_point(rs)
        let b = gen_point(rs)
        let c = gen_color(rs)
        doc.render_line(a, b, c, gen_pos(rs))
      }
      4 => {
        let t = gen_text(rs)
        let p = gen_point(rs)
        let s = gen_pos(rs)
        doc.render_text(t, p, s, gen_color(rs))
      }
      5 => {
        let p = gen_point(rs)
        let rx = gen_pos(rs)
        let ry = gen_pos(rs)
        doc.render_ellipse(p, rx, ry, gen_color(rs))
      }
      6 => {
        let n = rs.next_uint(limit=6).reinterpret_as_int()
        doc.render_polygon(Array::makei(n, _ => gen_point(rs)), gen_color(rs))
      }
      _ => {
        let id = gen_text(rs)
        let a = gen_point(rs)
        let b = gen_point(rs)
        let c1 = gen_color(rs)
        doc.render_linear_gradient(id, a, b, c1, gen_color(rs))
      }
    }
  }
  doc.to_string()
}

///|
test "qc: SvgDocument output is well-formed for arbitrary text and ids" {
  @quickcheck.check(
    (input : (Array[UInt], UInt64)) => {
      let s = build_svg_doc(input.0, input.1)
      xml_problem(s) is None && !non_finite_literal(s)
    },
    counterexample_context=input => {
      let s = build_svg_doc(input.0, input.1)
      let problem = match xml_problem(s) {
        Some(p) => p
        None => "no XML problem"
      }
      printable("\{problem}\n\{s}")
    },
    seed=49,
  )
}

///|
test "regression: SvgDocument gradients emit no stray quote and escape ids" {
  let svg = @svg.new_svg(10.0, 10.0)
    .render_linear_gradient(
      "g\"1<",
      Point(0.0, 0.0),
      Point(100.0, 0.0),
      @color.red(),
      @color.blue(),
    )
    .to_string()
  // previously `...</defs>"` (a stray quote) and `id="g"1<"` (broken attribute)
  assert_true(xml_problem(svg) is None)
  assert_true(svg.contains("id=\"g&quot;1&lt;\""))
  assert_true(svg.contains("</defs>\n</svg>"))
}
