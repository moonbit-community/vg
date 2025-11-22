// Tests for advanced VG features

///|
test "quadratic bezier curves" (it : @test.Test) {
  let qcurve_path = @vg.Path::empty()
    .move_to(@vg.Point::new(10.0, 50.0))
    .qcurve_to(@vg.Point::new(50.0, 10.0), @vg.Point::new(90.0, 50.0)) // Arch shape
    .qcurve_to(@vg.Point::new(50.0, 90.0), @vg.Point::new(10.0, 50.0)) // Return with opposite arch
    .close_path()
  inspect(
    qcurve_path,
    content="Path([MoveTo({x: 10, y: 50}), QCurveTo({x: 50, y: 10}, {x: 90, y: 50}), QCurveTo({x: 50, y: 90}, {x: 10, y: 50}), Close])",
  )
  let doc = @vg.new_svg(100.0, 100.0)
    .render_rectangle(0.0, 0.0, 100.0, 100.0, @color.gray(0.95))
    .render_path(qcurve_path, @color.blue())
  let svg_string = doc.to_string()
  it.write(svg_string)
  it.snapshot(filename="quadratic_curves.svg")
}

///|
test "elliptical arcs" (it : @test.Test) {
  let arc_path = @vg.Path::empty()
    .move_to(@vg.Point::new(20.0, 50.0))
    .earc_to(30.0, 20.0, 0.0, false, true, @vg.Point::new(80.0, 50.0)) // Elliptical arc
    .earc_to(30.0, 20.0, 0.0, false, true, @vg.Point::new(20.0, 50.0)) // Return arc
    .close_path()
  inspect(
    arc_path,
    content="Path([MoveTo({x: 20, y: 50}), EArcTo(30, 20, 0, false, true, {x: 80, y: 50}), EArcTo(30, 20, 0, false, true, {x: 20, y: 50}), Close])",
  )
  let doc = @vg.new_svg(100.0, 100.0)
    .render_rectangle(0.0, 0.0, 100.0, 100.0, @color.gray(0.95))
    .render_path(arc_path, @color.green())
  let svg_string = doc.to_string()
  it.write(svg_string)
  it.snapshot(filename="elliptical_arcs.svg")
}

///|
test "smooth curve stitching" (it : @test.Test) {
  let smooth_path = @vg.Path::empty()
    .move_to(@vg.Point::new(10.0, 50.0))
    .curve_to(
      @vg.Point::new(30.0, 10.0),
      @vg.Point::new(50.0, 10.0),
      @vg.Point::new(70.0, 50.0),
    )
    .smooth_ccurve_to(@vg.Point::new(110.0, 90.0), @vg.Point::new(130.0, 50.0)) // Smooth continuation
    .smooth_ccurve_to(@vg.Point::new(150.0, 10.0), @vg.Point::new(170.0, 50.0)) // Another smooth curve
  inspect(
    smooth_path,
    content="Path([MoveTo({x: 10, y: 50}), CurveTo({x: 30, y: 10}, {x: 50, y: 10}, {x: 70, y: 50}), CurveTo({x: 90, y: 90}, {x: 110, y: 90}, {x: 130, y: 50}), CurveTo({x: 150, y: 10}, {x: 150, y: 10}, {x: 170, y: 50})])",
  )
  let doc = @vg.new_svg(180.0, 100.0)
    .render_rectangle(0.0, 0.0, 180.0, 100.0, @color.gray(0.95))
    .render_path(smooth_path, @color.purple())
  let svg_string = doc.to_string()
  it.write(svg_string)
  it.snapshot(filename="smooth_curves.svg")
}

///|
test "axial gradients" (it : @test.Test) {
  let axial_img = @vg.Image::axial_gradient(
    @color.red(),
    @color.yellow(),
    @vg.Point::new(-50.0, 0.0),
    @vg.Point::new(50.0, 0.0),
  )
  let axial_svg = axial_img.render_image_to_svg(100.0, 60.0, 25)
  it.write(axial_svg)
  it.snapshot(filename="axial_gradient.svg")
}

///|
test "conic gradients" (it : @test.Test) {
  let conic_img = @vg.Image::conic_gradient(
    @color.red(),
    @color.blue(),
    @vg.Point::new(0.0, 0.0),
    0.0,
  )
  let conic_svg = conic_img.render_image_to_svg(100.0, 100.0, 30)
  it.write(conic_svg)
  it.snapshot(filename="conic_gradient.svg")
}

///|
test "advanced blend modes" {
  let red = @color.rgba(1.0, 0.0, 0.0, 0.8)
  let blue = @color.rgba(0.0, 0.0, 1.0, 0.8)
  let blend_results = [
    ("normal_blend", @color.blend(red, blue)),
    ("multiply_blend", @color.multiply_blend(red, blue)),
    ("screen_blend", @color.screen_blend(red, blue)),
    ("overlay_blend", @color.overlay_blend(red, blue)),
    ("hard_light_blend", @color.hard_light_blend(red, blue)),
    ("soft_light_blend", @color.soft_light_blend(red, blue)),
  ]
  inspect(
    blend_results,
    content=(
      #|[("normal_blend", {r: 0.8333333333333335, g: 0, b: 0.16666666666666666, a: 0.96}), ("multiply_blend", {r: 0, g: 0, b: 0, a: 0.96}), ("screen_blend", {r: 1, g: 0, b: 1, a: 0.96}), ("overlay_blend", {r: 1, g: 0, b: 0, a: 0.96}), ("hard_light_blend", {r: 0, g: 0, b: 1, a: 0.96}), ("soft_light_blend", {r: 1, g: 0, b: 0, a: 0.96})]
    ),
  )
}

///|
test "tiled images" (it : @test.Test) {
  let base_pattern = @vg.Image::circle(@color.red(), 8.0)
  let tiled = @vg.Image::tile(base_pattern, 20.0, 20.0)
  let tiled_svg = tiled.render_image_to_svg(100.0, 80.0, 25)
  it.write(tiled_svg)
  it.snapshot(filename="tiled_pattern.svg")
}

///|
test "checkerboard pattern" (it : @test.Test) {
  let checker = @vg.Image::checkerboard(@color.black(), @color.white(), 10.0)
  let checker_svg = checker.render_image_to_svg(80.0, 80.0, 20)
  it.write(checker_svg)
  it.snapshot(filename="checkerboard.svg")
}

///|
test "advanced path showcase" (it : @test.Test) {
  let doc = @vg.new_svg(400.0, 300.0)
    .render_rectangle(0.0, 0.0, 400.0, 300.0, @color.gray(0.98))
    .render_text(
      "Advanced Path Features",
      @vg.Point::new(200.0, 30.0),
      18.0,
      @color.black(),
    )

  // Quadratic curve example
  let q_path = @vg.Path::empty()
    .move_to(@vg.Point::new(50.0, 80.0))
    .qcurve_to(@vg.Point::new(100.0, 50.0), @vg.Point::new(150.0, 80.0))
    .qcurve_to(@vg.Point::new(100.0, 110.0), @vg.Point::new(50.0, 80.0))
    .close_path()

  // Elliptical arc example
  let arc_path = @vg.Path::empty()
    .move_to(@vg.Point::new(200.0, 80.0))
    .earc_to(40.0, 25.0, 0.0, false, true, @vg.Point::new(280.0, 80.0))
    .earc_to(40.0, 25.0, 0.0, false, true, @vg.Point::new(200.0, 80.0))
    .close_path()

  // Smooth curves example
  let smooth_path = @vg.Path::empty()
    .move_to(@vg.Point::new(50.0, 150.0))
    .curve_to(
      @vg.Point::new(75.0, 120.0),
      @vg.Point::new(100.0, 120.0),
      @vg.Point::new(125.0, 150.0),
    )
    .smooth_ccurve_to(
      @vg.Point::new(175.0, 180.0),
      @vg.Point::new(200.0, 150.0),
    )
    .smooth_ccurve_to(
      @vg.Point::new(225.0, 120.0),
      @vg.Point::new(250.0, 150.0),
    )
  let final_doc = doc
    .render_path(q_path, @color.blue())
    .render_path(arc_path, @color.green())
    .render_path(smooth_path, @color.red())
    .render_text("Quadratic", @vg.Point::new(100.0, 130.0), 12.0, @color.blue())
    .render_text(
      "Elliptical Arc",
      @vg.Point::new(240.0, 130.0),
      12.0,
      @color.green(),
    )
    .render_text(
      "Smooth Curves",
      @vg.Point::new(150.0, 200.0),
      12.0,
      @color.red(),
    )
  let svg_string = final_doc.to_string()
  it.write(svg_string)
  it.snapshot(filename="advanced_paths.svg")
}
