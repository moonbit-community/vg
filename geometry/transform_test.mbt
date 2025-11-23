// Tests for transformation utilities

///|
test "identity transformation" {
  let t = @geometry.identity()
  let p = @geometry.Point::new(3.0, 4.0)
  let result = @geometry.apply(t, p)
  if result.x != 3.0 || result.y != 4.0 {
    fail("Identity transform should not change point")
  }
}

///|
test "translation" {
  let t = @geometry.make_translate(5.0, 10.0)
  let p = @geometry.Point::new(2.0, 3.0)
  let result = @geometry.apply(t, p)
  if result.x != 7.0 || result.y != 13.0 {
    fail("Translation incorrect")
  }
}

///|
test "scaling" {
  let t = @geometry.make_scale(2.0, 3.0)
  let p = @geometry.Point::new(4.0, 5.0)
  let result = @geometry.apply(t, p)
  if result.x != 8.0 || result.y != 15.0 {
    fail("Scaling incorrect")
  }
}

///|
test "rotation 90 degrees" {
  let t = @geometry.make_rotate(3.14159265359 / 2.0) // 90 degrees
  let p = @geometry.Point::new(1.0, 0.0)
  let result = @geometry.apply(t, p)
  // Should be approximately (0, 1)
  if result.x.abs() > 0.0001 || (result.y - 1.0).abs() > 0.0001 {
    fail("90 degree rotation incorrect")
  }
}

///|
test "transform composition" {
  let t1 = @geometry.make_translate(5.0, 3.0)
  let t2 = @geometry.make_scale(2.0, 2.0)
  let composed = @geometry.compose_transforms(t1, t2)
  let p = @geometry.Point::new(1.0, 1.0)
  let result = @geometry.apply(composed, p)
  // First translate (1,1) -> (6,4), then scale -> (12, 8)
  if result.x != 12.0 || result.y != 8.0 {
    fail("Transform composition incorrect")
  }
}

///|
test "determinant" {
  let t = @geometry.make_scale(2.0, 3.0)
  let det = @geometry.determinant(t)
  if det != 6.0 {
    fail("Determinant should be 6.0")
  }
}

///|
test "preserves orientation" {
  let t1 = @geometry.make_scale(2.0, 3.0)
  if not(@geometry.preserves_orientation(t1)) {
    fail("Positive scale should preserve orientation")
  }
  let t2 = @geometry.make_scale(-1.0, 1.0) // Mirror
  if @geometry.preserves_orientation(t2) {
    fail("Mirror should not preserve orientation")
  }
}

///|
test "transform inversion" {
  let t = @geometry.make_translate(5.0, 10.0)
  match @geometry.invert(t) {
    Some(inv) => {
      let p = @geometry.Point::new(7.0, 13.0)
      let result = @geometry.apply(inv, p)
      if (result.x - 2.0).abs() > 0.0001 || (result.y - 3.0).abs() > 0.0001 {
        fail("Inverse transform incorrect")
      }
    }
    None => fail("Translation should be invertible")
  }
}

///|
test "path transformation" {
  let path = @geometry.Path::rect(0.0, 0.0, 10.0, 10.0)
  let t = @geometry.make_translate(5.0, 5.0)
  let transformed = path.transform(t)
  match transformed.0[0] {
    MoveTo(p) =>
      if p.x != 5.0 || p.y != 5.0 {
        fail("Path should be translated")
      }
    _ => fail("Expected MoveTo")
  }
}
