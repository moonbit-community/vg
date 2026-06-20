// Tests for stroke outlines (Area::Outline).

///|
test "stroke: a line is a band around the segment" {
  let line = @vg.Image::line(
    @color.red(),
    Point(-10.0, 0.0),
    Point(10.0, 0.0),
    4.0,
  )
  // on the line, within half-width (2), and outside it
  debug_inspect(
    (
      line.eval(Point(0.0, 0.0)),
      line.eval(Point(0.0, 1.5)),
      line.eval(Point(0.0, 5.0)),
    ),
    content=(
      #|(
      #|  { r: 1, g: 0, b: 0, a: 1 },
      #|  { r: 1, g: 0, b: 0, a: 1 },
      #|  { r: 0, g: 0, b: 0, a: 0 },
      #|)
    ),
  )
}

///|
test "stroke: an outline cut renders as a stroke in SVG" {
  let line = @vg.Image::line(
    @color.red(),
    Point(-10.0, 0.0),
    Point(10.0, 0.0),
    4.0,
  )
  let svg = line.to_svg(40.0, 40.0)
  assert_true(svg.contains("stroke-width=\"4\""))
  assert_true(svg.contains("fill=\"none\""))
}

///|
test "stroke: canvas strokes with lineWidth" {
  let line = @vg.Image::line(
    @color.blue(),
    Point(-5.0, 0.0),
    Point(5.0, 0.0),
    3.0,
  )
  let js = line.to_js(40.0, 40.0)
  assert_true(js.contains("ctx.lineWidth = 3;"))
  assert_true(js.contains("ctx.stroke();"))
}

///|
test "stroke: outline width scales with the transform" {
  let line = @vg.Image::line(
    @color.red(),
    Point(-5.0, 0.0),
    Point(5.0, 0.0),
    4.0,
  ).scale(2.0, 2.0)
  // width 4 under a 2x scale -> native stroke-width 8 (matches eval)
  assert_true(line.to_svg(40.0, 40.0).contains("stroke-width=\"8\""))
}
