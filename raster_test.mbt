// Tests for the Raster (procedural) primitive.

///|
test "raster: checkerboard samples via eval" {
  let checker = @vg.Image::checkerboard(@color.black(), @color.white(), 10.0)
  // cell (0,0) is black; the next cell in x is white
  debug_inspect(
    (checker.eval(Point(5.0, 5.0)), checker.eval(Point(15.0, 5.0))),
    content=(
      #|({ r: 0, g: 0, b: 0, a: 1 }, { r: 1, g: 1, b: 1, a: 1 })
    ),
  )
}

///|
test "raster: of_fn builds a Raster primitive" {
  let img = @vg.Image::of_fn(fn(p) {
    if p.x > 0.0 {
      @color.red()
    } else {
      @color.blue()
    }
  })
  debug_inspect(
    (img.eval(Point(5.0, 0.0)), img.eval(Point(-5.0, 0.0))),
    content=(
      #|({ r: 1, g: 0, b: 0, a: 1 }, { r: 0, g: 0, b: 1, a: 1 })
    ),
  )
}

///|
test "raster: a procedural image rasterises in the vector fold" {
  let svg = @vg.Image::checkerboard(@color.black(), @color.white(), 10.0).to_svg(
    40.0, 40.0,
  )
  // no native path fill; sampled into <rect> cells
  assert_true(svg.contains("<rect"))
  assert_true(!svg.contains("<path"))
}
