// Tests for transformation utilities

///|
test "identity transform" {
  let id = @geometry.identity()
  let p = @vg.Point::new(5.0, 7.0)
  let transformed = @geometry.apply(id, p)
  if transformed.x != p.x || transformed.y != p.y {
    fail("Identity transform should not change points")
  }
}

///|
test "translation transform" {
  let t = @geometry.make_translate(3.0, 4.0)
  let p = @vg.Point::new(1.0, 2.0)
  let transformed = @geometry.apply(t, p)
  if transformed.x != 4.0 || transformed.y != 6.0 {
    fail("Translation transform incorrect")
  }
}

///|
test "scale transform" {
  let t = @geometry.make_scale(2.0, 3.0)
  let p = @vg.Point::new(4.0, 5.0)
  let transformed = @geometry.apply(t, p)
  if transformed.x != 8.0 || transformed.y != 15.0 {
    fail("Scale transform incorrect")
  }
}

///|
test "uniform scale transform" {
  let t = @geometry.scale_uniform(2.5)
  let p = @vg.Point::new(2.0, 4.0)
  let transformed = @geometry.apply(t, p)
  if transformed.x != 5.0 || transformed.y != 10.0 {
    fail("Uniform scale transform incorrect")
  }
}

///|
test "rotation transform" {
  let t = @geometry.make_rotate(3.14159265359 / 2.0) // 90 degrees
  let p = @vg.Point::new(1.0, 0.0)
  let transformed = @geometry.apply(t, p)

  // Should be approximately (0, 1)
  if transformed.x.abs() > 0.0001 || (transformed.y - 1.0).abs() > 0.0001 {
    fail("90 degree rotation transform incorrect")
  }
}

///|
test "transform composition" {
  let t1 = @geometry.make_translate(1.0, 2.0)
  let t2 = @geometry.make_scale(2.0, 3.0)
  let composed = @geometry.compose_transforms(t1, t2)
  let p = @vg.Point::new(1.0, 1.0)
  let result1 = @geometry.apply(composed, p)
  let result2 = @geometry.apply(t2, @geometry.apply(t1, p))
  if (result1.x - result2.x).abs() > 0.0001 ||
    (result1.y - result2.y).abs() > 0.0001 {
    fail("Transform composition should be equivalent to sequential application")
  }
}

///|
test "transform inversion" {
  let t = @geometry.make_translate(3.0, 4.0)
  match @geometry.invert(t) {
    Some(inv_t) => {
      let p = @vg.Point::new(5.0, 7.0)
      let transformed = @geometry.apply(t, p)
      let back = @geometry.apply(inv_t, transformed)
      if (back.x - p.x).abs() > 0.0001 || (back.y - p.y).abs() > 0.0001 {
        fail("Transform inversion should restore original point")
      }
    }
    None => fail("Translation transform should be invertible")
  }
}

///|
test "non-invertible transform" {
  // Zero determinant transform (degenerate)
  let t = @geometry.compose_transforms(
    @geometry.make_scale(1.0, 0.0),
    @geometry.make_translate(1.0, 1.0),
  )
  match @geometry.invert(t) {
    Some(_) => fail("Degenerate transform should not be invertible")
    None => ()
  }
}

///|
test "determinant calculation" {
  let t = @geometry.make_scale(2.0, 3.0)
  let det = @geometry.determinant(t)
  if det != 6.0 {
    fail("Determinant of scale transform should be product of scale factors")
  }
}

///|
test "orientation preservation" {
  let t1 = @geometry.make_scale(2.0, 3.0) // Positive determinant
  let t2 = @geometry.make_scale(-2.0, 3.0) // Negative determinant
  if not(@geometry.preserves_orientation(t1)) {
    fail("Positive scale should preserve orientation")
  }
  if @geometry.preserves_orientation(t2) {
    fail("Negative scale should not preserve orientation")
  }
}

///|
test "skew transforms" {
  let skew_x_t = @geometry.skew_x(0.5)
  let skew_y_t = @geometry.skew_y(0.5)
  let p = @vg.Point::new(1.0, 1.0)
  let skewed_x = @geometry.apply(skew_x_t, p)
  let skewed_y = @geometry.apply(skew_y_t, p)
  let skew_results = [
    ("original_point", p),
    ("skewed_x_result", skewed_x),
    ("skewed_y_result", skewed_y),
  ]
  inspect(
    skew_results,
    content=(
      #|[("original_point", {x: 1, y: 1}), ("skewed_x_result", {x: 1.5463024898437905, y: 1}), ("skewed_y_result", {x: 1, y: 1.5463024898437905})]
    ),
  )
}

///|
test "comprehensive transform matrix operations" {
  let test_point = @vg.Point::new(2.0, 3.0)
  let identity_t = @geometry.identity()
  let translate_t = @geometry.make_translate(5.0, 3.0)
  let scale_t = @geometry.make_scale(2.0, 3.0)
  let rotate_t = @geometry.make_rotate(3.14159265359 / 2.0)
  let uniform_scale_t = @geometry.scale_uniform(2.0)
  let skew_x_t = @geometry.skew_x(0.5)
  let skew_y_t = @geometry.skew_y(0.25)
  let transform_results = [
    (
      "identity",
      identity_t,
      @geometry.apply(identity_t, test_point),
      @geometry.determinant(identity_t),
    ),
    (
      "translate_5_3",
      translate_t,
      @geometry.apply(translate_t, test_point),
      @geometry.determinant(translate_t),
    ),
    (
      "scale_2_3",
      scale_t,
      @geometry.apply(scale_t, test_point),
      @geometry.determinant(scale_t),
    ),
    (
      "rotate_90deg",
      rotate_t,
      @geometry.apply(rotate_t, test_point),
      @geometry.determinant(rotate_t),
    ),
    (
      "uniform_scale_2",
      uniform_scale_t,
      @geometry.apply(uniform_scale_t, test_point),
      @geometry.determinant(uniform_scale_t),
    ),
    (
      "skew_x_half",
      skew_x_t,
      @geometry.apply(skew_x_t, test_point),
      @geometry.determinant(skew_x_t),
    ),
    (
      "skew_y_quarter",
      skew_y_t,
      @geometry.apply(skew_y_t, test_point),
      @geometry.determinant(skew_y_t),
    ),
  ]
  inspect(
    transform_results,
    content=(
      #|[("identity", {m11: 1, m12: 0, m21: 0, m22: 1, m31: 0, m32: 0}, {x: 2, y: 3}, 1), ("translate_5_3", {m11: 1, m12: 0, m21: 0, m22: 1, m31: 5, m32: 3}, {x: 7, y: 6}, 1), ("scale_2_3", {m11: 2, m12: 0, m21: 0, m22: 3, m31: 0, m32: 0}, {x: 4, y: 9}, 6), ("rotate_90deg", {m11: -1.0341155355510722e-13, m12: -1, m21: 1, m22: -1.0341155355510722e-13, m31: 0, m32: 0}, {x: -3.000000000000207, y: 1.9999999999996898}, 1), ("uniform_scale_2", {m11: 2, m12: 0, m21: 0, m22: 2, m31: 0, m32: 0}, {x: 4, y: 6}, 4), ("skew_x_half", {m11: 1, m12: 0.5463024898437905, m21: 0, m22: 1, m31: 0, m32: 0}, {x: 3.6389074695313717, y: 3}, 1), ("skew_y_quarter", {m11: 1, m12: 0, m21: 0.25534192122103627, m22: 1, m31: 0, m32: 0}, {x: 2, y: 3.5106838424420728}, 1)]
    ),
  )
}

///|
test "transform composition and inversion" {
  let t1 = @geometry.make_translate(10.0, 5.0)
  let t2 = @geometry.make_scale(2.0, 3.0)
  let t3 = @geometry.make_rotate(3.14159 / 4.0) // 45 degrees
  let composed = @geometry.compose_transforms(
    @geometry.compose_transforms(t1, t2),
    t3,
  )
  let test_point = @vg.Point::new(1.0, 1.0)
  let composition_results = [
    ("original_point", test_point),
    ("after_translate", @geometry.apply(t1, test_point)),
    ("after_scale", @geometry.apply(t2, @geometry.apply(t1, test_point))),
    (
      "after_rotate",
      @geometry.apply(t3, @geometry.apply(t2, @geometry.apply(t1, test_point))),
    ),
    ("composed_result", @geometry.apply(composed, test_point)),
  ]

  // Test inversion
  let inversion_results = match @geometry.invert(t1) {
    Some(inv_t1) => {
      let round_trip = @geometry.apply(inv_t1, @geometry.apply(t1, test_point))
      ("has_inverse", true, round_trip)
    }
    None => ("has_inverse", false, @vg.Point::origin())
  }
  inspect(
    (composition_results, inversion_results),
    content=(
      #|([("original_point", {x: 1, y: 1}), ("after_translate", {x: 11, y: 6}), ("after_scale", {x: 22, y: 18}), ("after_rotate", {x: 2.8284458884589423, y: 28.284269371084342}), ("composed_result", {x: 24.748741563359225, y: 0.7071231994355944})], ("has_inverse", true, {x: 1, y: 1}))
    ),
  )
}
