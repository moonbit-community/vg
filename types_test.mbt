// Tests for core types

///|
test "Point creation and equality" {
  let p1 = @vg.Point::new(1.0, 2.0)
  let p2 = @vg.Point::new(1.0, 2.0)
  let p3 = @vg.Point::new(2.0, 1.0)
  if p1 != p2 {
    fail("Points with same coordinates should be equal")
  }
  if p1 == p3 {
    fail("Points with different coordinates should not be equal")
  }
}

///|
test "Color creation and equality" {
  let c1 = @vg.rgba(1.0, 0.5, 0.0, 1.0)
  let c2 = @vg.rgba(1.0, 0.5, 0.0, 1.0)
  let c3 = @vg.rgba(0.0, 0.5, 1.0, 1.0)
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
    .move_to(@vg.Point::new(1.0, 2.0))
    .line_to(@vg.Point::new(3.0, 4.0))
    .curve_to(
      @vg.Point::new(1.0, 1.0),
      @vg.Point::new(2.0, 2.0),
      @vg.Point::new(3.0, 3.0),
    )
    .close_path()
  if path.0.length() != 4 {
    fail("Path should have 4 segments")
  }
}

///|
test "PathSegment variants" {
  // Test using path construction functions instead of direct enum construction
  let path = @vg.Path::empty()
    .move_to(@vg.Point::new(1.0, 2.0))
    .line_to(@vg.Point::new(3.0, 4.0))
    .curve_to(
      @vg.Point::new(1.0, 1.0),
      @vg.Point::new(2.0, 2.0),
      @vg.Point::new(3.0, 3.0),
    )
    .close_path()
  if path.0.length() != 4 {
    fail("Path should have 4 segments")
  }

  // Test that we can match on the segments
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
test "Primitive constructors and equality" {
  let center = @vg.Point::new(5.0, 5.0)
  let circle = @vg.primitive_circle(center, 10.0)

  // Test circle primitive
  match circle {
    Circle(c, r) => {
      if c.x != 5.0 || c.y != 5.0 {
        fail("Circle center should be (5.0, 5.0)")
      }
      if r != 10.0 {
        fail("Circle radius should be 10.0")
      }
    }
    _ => fail("Expected Circle primitive")
  }

  // Test rectangle primitive
  let top_left = @vg.Point::new(0.0, 0.0)
  let bottom_right = @vg.Point::new(10.0, 10.0)
  let rect = @vg.primitive_rectangle(top_left, bottom_right)
  match rect {
    Rectangle(tl, br) => {
      if tl.x != 0.0 || tl.y != 0.0 {
        fail("Rectangle top-left should be (0.0, 0.0)")
      }
      if br.x != 10.0 || br.y != 10.0 {
        fail("Rectangle bottom-right should be (10.0, 10.0)")
      }
    }
    _ => fail("Expected Rectangle primitive")
  }

  // Test path primitive
  let path = @vg.Path::empty()
    .move_to(@vg.Point::new(1.0, 1.0))
    .line_to(@vg.Point::new(2.0, 2.0))
  let path_prim = @vg.primitive_path(path)
  match path_prim {
    Path(p) => if p.0.length() != 2 { fail("Path should have 2 segments") }
    _ => fail("Expected Path primitive")
  }

  // Test text primitive
  let text_pos = @vg.Point::new(100.0, 200.0)
  let text_prim = @vg.primitive_text("Hello World", text_pos, 14.0)
  match text_prim {
    Text(text, pos, size) => {
      if text != "Hello World" {
        fail("Text content should be 'Hello World'")
      }
      if pos.x != 100.0 || pos.y != 200.0 {
        fail("Text position should be (100.0, 200.0)")
      }
      if size != 14.0 {
        fail("Text size should be 14.0")
      }
    }
    _ => fail("Expected Text primitive")
  }

  // Test equality
  let circle1 = @vg.primitive_circle(center, 10.0)
  let circle2 = @vg.primitive_circle(center, 10.0)
  let circle3 = @vg.primitive_circle(center, 20.0)
  if circle1 != circle2 {
    fail("Identical circles should be equal")
  }
  if circle1 == circle3 {
    fail("Different circles should not be equal")
  }
}

///|
test "ImageOp constructors and variants" {
  // Test constant color operation
  let red = @vg.red()
  let const_op = @vg.imageop_const(red)
  match const_op {
    Const(_color) => () // Successfully created const operation
    _ => fail("Expected Const operation")
  }

  // Test primitive operation
  let circle = @vg.primitive_circle(@vg.Point::origin(), 5.0)
  let blue = @vg.blue()
  let prim_op = @vg.imageop_primitive(circle, blue)
  match prim_op {
    Primitive(prim, _color) =>
      match prim {
        Circle(center, radius) => {
          if center.x != 0.0 || center.y != 0.0 {
            fail("Circle center should be origin")
          }
          if radius != 5.0 {
            fail("Circle radius should be 5.0")
          }
        }
        _ => fail("Expected Circle primitive")
      }
    _ => fail("Expected Primitive operation")
  }

  // Test transform operation
  let identity_transform = @geometry.identity()
  let dummy_image = fn(_p) { red }
  let transform_op = @vg.imageop_transform(identity_transform, dummy_image)
  match transform_op {
    Transform(_transform, _image) => () // Successfully created transform operation
    _ => fail("Expected Transform operation")
  }

  // Test compose operation
  let image1 = fn(_p) { red }
  let image2 = fn(_p) { blue }
  let compose_op = @vg.imageop_compose(image1, image2)
  match compose_op {
    Compose(_img1, _img2) => () // Successfully created compose operation
    _ => fail("Expected Compose operation")
  }

  // Test cut operation
  let mask_image = fn(_p) { @vg.gray(0.5) }
  let cut_op = @vg.imageop_cut(image1, mask_image)
  match cut_op {
    Cut(_img, _mask) => () // Successfully created cut operation
    _ => fail("Expected Cut operation")
  }
}

///|
test "Primitive and ImageOp integration" {
  // Test creating a complex scene using primitives and image operations
  let red_color = @vg.red()
  let green_color = @vg.green()
  let blue_color = @vg.blue()

  // Create primitives
  let circle = @vg.primitive_circle(@vg.Point::new(50.0, 50.0), 25.0)
  let rect = @vg.primitive_rectangle(
    @vg.Point::new(0.0, 0.0),
    @vg.Point::new(100.0, 20.0),
  )
  let text = @vg.primitive_text("Test", @vg.Point::new(10.0, 80.0), 12.0)

  // Create image operations
  let circle_op = @vg.imageop_primitive(circle, red_color)
  let rect_op = @vg.imageop_primitive(rect, green_color)
  let text_op = @vg.imageop_primitive(text, blue_color)

  // Verify the operations work correctly
  match circle_op {
    Primitive(Circle(center, radius), _color) =>
      if center.x != 50.0 || center.y != 50.0 || radius != 25.0 {
        fail("Circle primitive data incorrect")
      }
    _ => fail("Expected circle primitive operation")
  }
  match rect_op {
    Primitive(Rectangle(tl, br), _color) =>
      if tl.x != 0.0 || br.x != 100.0 {
        fail("Rectangle primitive data incorrect")
      }
    _ => fail("Expected rectangle primitive operation")
  }
  match text_op {
    Primitive(Text(content, pos, size), _color) => {
      if content != "Test" {
        fail("Text content incorrect")
      }
      if pos.x != 10.0 || pos.y != 80.0 {
        fail("Text position incorrect")
      }
      if size != 12.0 {
        fail("Text size incorrect")
      }
    }
    _ => fail("Expected text primitive operation")
  }
}
