// Tests for the canvas vector fold (`Image::to_js`).

///|
test "canvas fold: a circle produces a path and fill" {
  let js = @vg.Image::circle(@color.red(), 20.0).to_js(100.0, 100.0)
  assert_true(js.contains("ctx.beginPath();"))
  assert_true(js.contains("ctx.bezierCurveTo(")) // circle béziers
  assert_true(js.contains("ctx.fill('nonzero');"))
  assert_true(js.contains("#FF0000")) // red fillStyle
}

///|
test "canvas fold: gradients are native (createLinearGradient)" {
  let img = @vg.Image::linear_gradient(
    @color.red(),
    @color.blue(),
    Point(-10.0, 0.0),
    Point(10.0, 0.0),
  ).cut(@vg.Path::rect(-10.0, -10.0, 20.0, 20.0))
  let js = img.to_js(50.0, 50.0)
  assert_true(js.contains("ctx.createLinearGradient("))
  assert_true(js.contains(".addColorStop("))
}

///|
test "canvas fold: clip uses save/clip/restore" {
  let img = @vg.Image::circle(@color.red(), 5.0).cut(
    @vg.Path::circle(Point(0.0, 0.0), 10.0),
  )
  let js = img.to_js(50.0, 50.0)
  assert_true(js.contains("ctx.save();"))
  assert_true(js.contains("ctx.clip('nonzero');"))
  assert_true(js.contains("ctx.restore();"))
}

///|
test "canvas fold: even-odd fill rule" {
  let img = @vg.Image::const_color(@color.blue()).cut(
    @vg.Path::rect(-10.0, -10.0, 20.0, 20.0),
    area=Aeo,
  )
  assert_true(img.to_js(50.0, 50.0).contains("ctx.fill('evenodd');"))
}

///|
test "elliptical arc renders consistently across backends" {
  let arc = @vg.Path::empty()
    .move_to(Point(-20.0, 0.0))
    .earc_to(20.0, 20.0, 0.0, false, true, Point(20.0, 0.0))
    .close_path()
  let img = @vg.Image::const_color(@color.red()).cut(arc)
  // SVG keeps the native arc; canvas/eval flatten it (not a chord)
  assert_true(img.to_svg(60.0, 60.0).contains("A 20 20"))
  assert_true(img.to_js(60.0, 60.0).contains("ctx.lineTo"))
  // the two sides of the chord differ now that the arc bulge is traced
  debug_inspect(
    (img.eval(Point(0.0, 10.0)), img.eval(Point(0.0, -10.0))),
    content=(
      #|({ r: 0, g: 0, b: 0, a: 0 }, { r: 1, g: 0, b: 0, a: 1 })
    ),
  )
}
