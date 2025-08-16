// Tests for core types

test "Point creation and equality" {
  let p1 = { x: 1.0, y: 2.0 }
  let p2 = { x: 1.0, y: 2.0 }
  let p3 = { x: 2.0, y: 1.0 }
  
  if p1 != p2 {
    fail("Points with same coordinates should be equal")
  }
  
  if p1 == p3 {
    fail("Points with different coordinates should not be equal")
  }
}

test "Color creation and equality" {
  let c1 = { r: 1.0, g: 0.5, b: 0.0, a: 1.0 }
  let c2 = { r: 1.0, g: 0.5, b: 0.0, a: 1.0 }
  let c3 = { r: 0.0, g: 0.5, b: 1.0, a: 1.0 }
  
  if c1 != c2 {
    fail("Colors with same components should be equal")
  }
  
  if c1 == c3 {
    fail("Colors with different components should not be equal")
  }
}

test "Transform creation and equality" {
  let t1 = { m11: 1.0, m12: 0.0, m21: 0.0, m22: 1.0, m31: 0.0, m32: 0.0 }
  let t2 = { m11: 1.0, m12: 0.0, m21: 0.0, m22: 1.0, m31: 0.0, m32: 0.0 }
  let t3 = { m11: 2.0, m12: 0.0, m21: 0.0, m22: 2.0, m31: 0.0, m32: 0.0 }
  
  if t1 != t2 {
    fail("Transforms with same components should be equal")
  }
  
  if t1 == t3 {
    fail("Transforms with different components should not be equal")
  }
}

test "Box creation and equality" {
  let b1 = { min_x: 0.0, min_y: 0.0, max_x: 10.0, max_y: 10.0 }
  let b2 = { min_x: 0.0, min_y: 0.0, max_x: 10.0, max_y: 10.0 }
  let b3 = { min_x: 0.0, min_y: 0.0, max_x: 20.0, max_y: 20.0 }
  
  if b1 != b2 {
    fail("Boxes with same bounds should be equal")
  }
  
  if b1 == b3 {
    fail("Boxes with different bounds should not be equal")
  }
}

test "PathSegment variants" {
  let move_seg = MoveTo({ x: 1.0, y: 2.0 })
  let line_seg = LineTo({ x: 3.0, y: 4.0 })
  let curve_seg = CurveTo({ x: 1.0, y: 1.0 }, { x: 2.0, y: 2.0 }, { x: 3.0, y: 3.0 })
  let close_seg = Close
  
  match move_seg {
    MoveTo(p) => if p.x != 1.0 || p.y != 2.0 { fail("MoveTo point incorrect") }
    _ => fail("Expected MoveTo segment")
  }
  
  match line_seg {
    LineTo(p) => if p.x != 3.0 || p.y != 4.0 { fail("LineTo point incorrect") }
    _ => fail("Expected LineTo segment")
  }
  
  match curve_seg {
    CurveTo(cp1, cp2, end) => {
      if cp1.x != 1.0 || end.x != 3.0 { fail("CurveTo points incorrect") }
    }
    _ => fail("Expected CurveTo segment")
  }
  
  match close_seg {
    Close => ()
    _ => fail("Expected Close segment")
  }
}
