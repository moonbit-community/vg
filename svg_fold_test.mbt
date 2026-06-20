// Tests for the native SVG vector fold (`Image::to_svg`).

///|
test "vector fold: a circle is one compact path, not a sampled grid" {
  let svg = @vg.Image::circle(@color.red(), 50.0).to_svg(200.0, 200.0)
  // exactly one path element, and no per-pixel <rect> grid
  assert_true(svg.contains("<path"))
  assert_true(!svg.contains("<rect"))
  // compact: the sampler produced ~300 KB for the same circle
  assert_true(svg.length() < 600)
}

///|
test "vector fold: rectangle SVG markup" {
  // a centred 100x60 red rectangle on a 200x200 canvas
  let svg = @vg.Image::rectangle(@color.red(), 100.0, 60.0).to_svg(200.0, 200.0)
  inspect(
    svg,
    content=(
      #|<?xml version="1.0" encoding="UTF-8"?>
      #|<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200"><g transform="translate(100,100)"><path d="M -50,-30 L 50,-30 L 50,30 L -50,30 Z" fill="#FF0000" fill-rule="nonzero"/></g></svg>
    ),
  )
}

///|
test "vector fold: gradient becomes a <defs> entry referenced by fill" {
  let g = @vg.cut(
    @vg.Path::rect(-50.0, -50.0, 100.0, 100.0),
    @vg.Image::linear_gradient(
      @color.red(),
      @color.blue(),
      Point(-50.0, 0.0),
      Point(50.0, 0.0),
    ),
  )
  let svg = g.to_svg(100.0, 100.0)
  assert_true(svg.contains("<linearGradient"))
  assert_true(svg.contains("fill=\"url(#grad0)\""))
}

///|
test "vector fold: transform becomes a <g matrix>" {
  let svg = @vg.Image::circle(@color.red(), 10.0)
    .translate_img(20.0, 0.0)
    .to_svg(100.0, 100.0)
  assert_true(svg.contains("<g transform=\"matrix(1,0,0,1,20,0)\">"))
}

///|
test "vector fold: composition stacks bottom then top" {
  let composed = @vg.Image::rectangle(@color.gray(0.9), 100.0, 100.0).compose(
    @vg.Image::circle(@color.red(), 20.0),
  )
  let svg = composed.to_svg(100.0, 100.0)
  // both layers are emitted: the gray background and the red circle on top
  assert_true(svg.contains("#E5E5E5"))
  assert_true(svg.contains("#FF0000"))
}
