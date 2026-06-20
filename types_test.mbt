// Tests for core types

///|
test "Point creation and equality" {
  let p1 = @vg.Point::Point(1.0, 2.0)
  let p2 = @vg.Point::Point(1.0, 2.0)
  let p3 = @vg.Point::Point(2.0, 1.0)
  if p1 != p2 {
    fail("Points with same coordinates should be equal")
  }
  if p1 == p3 {
    fail("Points with different coordinates should not be equal")
  }
}

///|
test "Color creation and equality" {
  let c1 = @color.rgba(1.0, 0.5, 0.0, 1.0)
  let c2 = @color.rgba(1.0, 0.5, 0.0, 1.0)
  let c3 = @color.rgba(0.0, 0.5, 1.0, 1.0)
  if c1 != c2 {
    fail("Colors with same components should be equal")
  }
  if c1 == c3 {
    fail("Colors with different components should not be equal")
  }
}

///|
test "Transform creation and equality" {
  let t1 = @geometry.identity()
  let t2 = @geometry.identity()
  let t3 = @geometry.make_scale(2.0, 2.0)
  if t1 != t2 {
    fail("Transforms with same components should be equal")
  }
  if t1 == t3 {
    fail("Transforms with different components should not be equal")
  }
}

///|
test "Path construction" {
  let path = @vg.Path::empty()
    .move_to(Point(1.0, 2.0))
    .line_to(Point(3.0, 4.0))
    .curve_to(Point(1.0, 1.0), Point(2.0, 2.0), Point(3.0, 3.0))
    .close_path()
  if path.0.length() != 4 {
    fail("Path should have 4 segments")
  }
}

///|
test "PathSegment variants" {
  let path = @vg.Path::empty()
    .move_to(Point(1.0, 2.0))
    .line_to(Point(3.0, 4.0))
    .curve_to(Point(1.0, 1.0), Point(2.0, 2.0), Point(3.0, 3.0))
    .close_path()
  if path.0.length() != 4 {
    fail("Path should have 4 segments")
  }
  let segments = path.0
  match segments[0] {
    MoveTo(p) => if p.x != 1.0 || p.y != 2.0 { fail("MoveTo point incorrect") }
    _ => fail("Expected MoveTo segment")
  }
  match segments[1] {
    LineTo(p) => if p.x != 3.0 || p.y != 4.0 { fail("LineTo point incorrect") }
    _ => fail("Expected LineTo segment")
  }
  match segments[2] {
    CurveTo(cp1, cp2, end) =>
      if cp1.x != 1.0 || cp2.x != 2.0 || end.x != 3.0 {
        fail("CurveTo points incorrect")
      }
    _ => fail("Expected CurveTo segment")
  }
  match segments[3] {
    Close => ()
    _ => fail("Expected Close segment")
  }
}

///|
test "Image AST: const colour evaluates to the colour everywhere" {
  let red = @color.red()
  let img = @vg.Image::const_color(red)
  if img.eval(Point(0.0, 0.0)) != red || img.eval(Point(100.0, -50.0)) != red {
    fail("const_color should be the colour at every point")
  }
  match img {
    Primitive(Const(c)) => if c != red { fail("expected Const(red)") }
    _ => fail("expected Primitive(Const _)")
  }
}

///|
test "Image AST: a circle is a path cut from a colour field" {
  let red = @color.red()
  let c = @vg.Image::circle(red, 10.0)
  if c.eval(Point(0.0, 0.0)) != red {
    fail("centre of the circle should be red")
  }
  if c.eval(Point(100.0, 100.0)).a != 0.0 {
    fail("outside the circle should be transparent")
  }
  match c {
    Cut(Anz, _, Primitive(Const(col))) =>
      if col != red {
        fail("expected a red fill")
      }
    _ => fail("circle should be Cut(Anz, path, Const)")
  }
}

///|
test "Image AST: over compositing" {
  let red = @color.rgba(1.0, 0.0, 0.0, 1.0)
  let half_blue = @color.rgba(0.0, 0.0, 1.0, 0.5)
  let img = @vg.Image::const_color(half_blue).over(@vg.Image::const_color(red))
  let out = img.eval(Point(0.0, 0.0))
  if out.a != 1.0 {
    fail("opaque-over should be opaque")
  }
  // half-blue (alpha 0.5) over opaque red is an even 50/50 mix
  if (out.r - 0.5).abs() > 0.01 || (out.b - 0.5).abs() > 0.01 {
    fail("half-blue over opaque red should blend to 50/50 red/blue")
  }
}

///|
test "Image AST: a linear gradient evaluates along its axis" {
  let black = @color.black()
  let white = @color.white()
  let g = @vg.Image::linear_gradient(
    black,
    white,
    Point(0.0, 0.0),
    Point(10.0, 0.0),
  )
  let mid = g.eval(Point(5.0, 0.0))
  if (mid.r - 0.5).abs() > 0.05 {
    fail("midpoint of a black->white gradient should be ~0.5 grey")
  }
  if g.eval(Point(0.0, 0.0)) != black {
    fail("start of the gradient should be black")
  }
}

///|
test "Image AST: transform relocates the image" {
  let red = @color.red()
  let moved = @vg.Image::circle(red, 10.0).translate_img(100.0, 0.0)
  if moved.eval(Point(100.0, 0.0)) != red {
    fail("translated circle centre should be red")
  }
  if moved.eval(Point(0.0, 0.0)).a != 0.0 {
    fail("the original centre should now be transparent")
  }
}
