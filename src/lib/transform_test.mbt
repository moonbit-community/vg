// Tests for transformation utilities

test "identity transform" {
  let id = identity()
  let p = point(5.0, 7.0)
  let transformed = apply_transform(id, p)
  
  if transformed.x != p.x || transformed.y != p.y {
    fail("Identity transform should not change points")
  }
}

test "translation transform" {
  let t = make_translate(3.0, 4.0)
  let p = point(1.0, 2.0)
  let transformed = apply_transform(t, p)
  
  if transformed.x != 4.0 || transformed.y != 6.0 {
    fail("Translation transform incorrect")
  }
}

test "scale transform" {
  let t = make_scale(2.0, 3.0)
  let p = point(4.0, 5.0)
  let transformed = apply_transform(t, p)
  
  if transformed.x != 8.0 || transformed.y != 15.0 {
    fail("Scale transform incorrect")
  }
}

test "uniform scale transform" {
  let t = scale_uniform(2.5)
  let p = point(2.0, 4.0)
  let transformed = apply_transform(t, p)
  
  if transformed.x != 5.0 || transformed.y != 10.0 {
    fail("Uniform scale transform incorrect")
  }
}

test "rotation transform" {
  let t = make_rotate(3.14159265359 / 2.0)  // 90 degrees
  let p = point(1.0, 0.0)
  let transformed = apply_transform(t, p)
  
  // Should be approximately (0, 1)
  if transformed.x.abs() > 0.0001 || (transformed.y - 1.0).abs() > 0.0001 {
    fail("90 degree rotation transform incorrect")
  }
}

test "transform composition" {
  let t1 = make_translate(1.0, 2.0)
  let t2 = make_scale(2.0, 3.0)
  let composed = compose_transforms(t1, t2)
  
  let p = point(1.0, 1.0)
  let result1 = apply_transform(composed, p)
  let result2 = apply_transform(t2, apply_transform(t1, p))
  
  if (result1.x - result2.x).abs() > 0.0001 || (result1.y - result2.y).abs() > 0.0001 {
    fail("Transform composition should be equivalent to sequential application")
  }
}

test "transform inversion" {
  let t = make_translate(3.0, 4.0)
  match invert(t) {
    Some(inv_t) => {
      let p = point(5.0, 7.0)
      let transformed = apply_transform(t, p)
      let back = apply_transform(inv_t, transformed)
      
      if (back.x - p.x).abs() > 0.0001 || (back.y - p.y).abs() > 0.0001 {
        fail("Transform inversion should restore original point")
      }
    }
    None => fail("Translation transform should be invertible")
  }
}

test "non-invertible transform" {
  // Zero determinant transform (degenerate)
  let t = { m11: 1.0, m12: 0.0, m21: 1.0, m22: 0.0, m31: 0.0, m32: 0.0 }
  match invert(t) {
    Some(_) => fail("Degenerate transform should not be invertible")
    None => ()
  }
}

test "determinant calculation" {
  let t = make_scale(2.0, 3.0)
  let det = determinant(t)
  
  if det != 6.0 {
    fail("Determinant of scale transform should be product of scale factors")
  }
}

test "orientation preservation" {
  let t1 = make_scale(2.0, 3.0)  // Positive determinant
  let t2 = make_scale(-2.0, 3.0)  // Negative determinant
  
  if not(preserves_orientation(t1)) {
    fail("Positive scale should preserve orientation")
  }
  
  if preserves_orientation(t2) {
    fail("Negative scale should not preserve orientation")
  }
}

test "skew transforms" {
  let skew_x_t = skew_x(0.5)
  let skew_y_t = skew_y(0.5)
  
  let p = point(1.0, 1.0)
  let skewed_x = apply_transform(skew_x_t, p)
  let skewed_y = apply_transform(skew_y_t, p)
  
  // Skew X should affect x coordinate based on y
  if skewed_x.y != 1.0 {
    fail("Skew X should not affect Y coordinate")
  }
  
  // Skew Y should affect y coordinate based on x  
  if skewed_y.x != 1.0 {
    fail("Skew Y should not affect X coordinate")
  }
}
