// Tests for core types

test "Point creation and equality" {
  let p1 = Point::{ x: 1.0, y: 2.0 }
  let p2 = Point::{ x: 1.0, y: 2.0 }
  let p3 = Point::{ x: 2.0, y: 1.0 }
  
  if p1 != p2 {
    fail("Points with same coordinates should be equal")
  }
  
  if p1 == p3 {
    fail("Points with different coordinates should not be equal")
  }
}

test "Color creation and equality" {
  let c1 = Color::{ r: 1.0, g: 0.5, b: 0.0, a: 1.0 }
  let c2 = Color::{ r: 1.0, g: 0.5, b: 0.0, a: 1.0 }
  let c3 = Color::{ r: 0.0, g: 0.5, b: 1.0, a: 1.0 }
  
  if c1 != c2 {
    fail("Colors with same components should be equal")
  }
  
  if c1 == c3 {
    fail("Colors with different components should not be equal")
  }
}

test "Transform creation and equality" {
  let t1 = Transform::{ m11: 1.0, m12: 0.0, m21: 0.0, m22: 1.0, m31: 0.0, m32: 0.0 }
  let t2 = Transform::{ m11: 1.0, m12: 0.0, m21: 0.0, m22: 1.0, m31: 0.0, m32: 0.0 }
  let t3 = Transform::{ m11: 2.0, m12: 0.0, m21: 0.0, m22: 2.0, m31: 0.0, m32: 0.0 }
  
  if t1 != t2 {
    fail("Transforms with same components should be equal")
  }
  
  if t1 == t3 {
    fail("Transforms with different components should not be equal")
  }
}

test "Box creation and equality" {
  let b1 = Box::{ min_x: 0.0, min_y: 0.0, max_x: 10.0, max_y: 10.0 }
  let b2 = Box::{ min_x: 0.0, min_y: 0.0, max_x: 10.0, max_y: 10.0 }
  let b3 = Box::{ min_x: 0.0, min_y: 0.0, max_x: 20.0, max_y: 20.0 }
  
  if b1 != b2 {
    fail("Boxes with same bounds should be equal")
  }
  
  if b1 == b3 {
    fail("Boxes with different bounds should not be equal")
  }
}

test "PathSegment variants" {
  // Test using path construction functions instead of direct enum construction
  let path = empty_path()
    |> move_to(point(1.0, 2.0))
    |> line_to(point(3.0, 4.0))
    |> curve_to(point(1.0, 1.0), point(2.0, 2.0), point(3.0, 3.0))
    |> close_path()
  
  if path.length() != 4 {
    fail("Path should have 4 segments")
  }
  
  // Test that we can match on the segments
  match path[0] {
    MoveTo(p) => if p.x != 1.0 || p.y != 2.0 { fail("MoveTo point incorrect") }
    _ => fail("Expected MoveTo segment")
  }
  
  match path[1] {
    LineTo(p) => if p.x != 3.0 || p.y != 4.0 { fail("LineTo point incorrect") }
    _ => fail("Expected LineTo segment")
  }
  
  match path[2] {
    CurveTo(cp1, cp2, end) => {
      if cp1.x != 1.0 || cp2.x != 2.0 || end.x != 3.0 { fail("CurveTo points incorrect") }
    }
    _ => fail("Expected CurveTo segment")
  }
  
  match path[3] {
    Close => ()
    _ => fail("Expected Close segment")
  }
}
