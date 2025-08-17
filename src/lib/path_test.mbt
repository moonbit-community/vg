// Tests for path utilities

test "empty path creation" {
  let path = @lib.Path::empty()
  if path.0.length() != 0 {
    fail("Empty path should have zero segments")
  }
}

test "path building with move_to and line_to" {
  let path = @lib.Path::empty()
    .move_to(@lib.point(0.0, 0.0))
    .line_to(@lib.point(10.0, 0.0))
    .line_to(@lib.point(10.0, 10.0))
    .close_path()
  
  if path.0.length() != 4 {
    fail("Path should have 4 segments")
  }
  
  match path.0[0] {
    MoveTo(p) => if p.x != 0.0 || p.y != 0.0 { fail("First segment should be MoveTo(0,0)") }
    _ => fail("First segment should be MoveTo")
  }
  
  match path.0[3] {
    Close => ()
    _ => fail("Last segment should be Close")
  }
}

test "curve_to segment" {
  let path = @lib.Path::empty()
    .move_to(@lib.point(0.0, 0.0))
    .curve_to(@lib.point(5.0, 0.0), @lib.point(10.0, 5.0), @lib.point(10.0, 10.0))
  
  if path.0.length() != 2 {
    fail("Path should have 2 segments")
  }
  
  match path.0[1] {
    CurveTo(cp1, cp2, end) => {
      if cp1.x != 5.0 || cp2.x != 10.0 || end.y != 10.0 {
        fail("CurveTo segment points incorrect")
      }
    }
    _ => fail("Second segment should be CurveTo")
  }
}

test "rectangle path" {
  let path = @lib.Path::rect(0.0, 0.0, 10.0, 5.0)
  
  if path.0.length() != 5 {  // MoveTo + 4 LineTo + Close
    fail("Rectangle path should have 5 segments")
  }
  
  match path.0[0] {
    MoveTo(p) => if p.x != 0.0 || p.y != 0.0 { fail("Rectangle should start at origin") }
    _ => fail("Rectangle should start with MoveTo")
  }
  
  match path.0[4] {
    Close => ()
    _ => fail("Rectangle should end with Close")
  }
}

test "circle path approximation" {
  let path = @lib.Path::circle(@lib.point(5.0, 5.0), 3.0)
  
  // Circle approximation uses 4 cubic bezier curves + MoveTo + Close
  if path.0.length() != 6 {
    fail("Circle path should have 6 segments (MoveTo + 4 CurveTo + Close)")
  }
  
  match path.0[0] {
    MoveTo(p) => {
      // Should start at top of circle
      if (p.x - 5.0).abs() > 0.0001 || (p.y - 2.0).abs() > 0.0001 {
        fail("Circle should start at top point")
      }
    }
    _ => fail("Circle should start with MoveTo")
  }
  
  // Check that we have 4 curve segments
  let mut curve_count = 0
  for segment in path.0 {
    match segment {
      CurveTo(_, _, _) => curve_count = curve_count + 1
      _ => ()
    }
  }
  
  if curve_count != 4 {
    fail("Circle should have 4 curve segments")
  }
}

test "ellipse path" {
  let path = @lib.Path::ellipse(@lib.point(0.0, 0.0), 5.0, 3.0)
  
  if path.0.length() != 6 {
    fail("Ellipse path should have 6 segments")
  }
  
  match path.0[0] {
    MoveTo(p) => {
      // Should start at top of ellipse
      if p.x != 0.0 || (p.y - (-3.0)).abs() > 0.0001 {
        fail("Ellipse should start at top point")
      }
    }
    _ => fail("Ellipse should start with MoveTo")
  }
}

test "path transformation" {
  let original_path = @lib.Path::rect(0.0, 0.0, 2.0, 2.0)
  let transform = @lib.make_translate(5.0, 3.0)
  let transformed_path = original_path.transform(transform)
  
  if transformed_path.0.length() != original_path.0.length() {
    fail("Transformed path should have same number of segments")
  }
  
  match transformed_path.0[0] {
    MoveTo(p) => {
      if p.x != 5.0 || p.y != 3.0 {
        fail("Transformed path should start at translated position")
      }
    }
    _ => fail("Transformed path should start with MoveTo")
  }
}

test "path bounds calculation" {
  let path = @lib.Path::empty()
    .move_to(@lib.point(-5.0, -3.0))
    .line_to(@lib.point(10.0, 7.0))
    .line_to(@lib.point(2.0, -8.0))
  
  match path.bounds() {
    Some(bounds) => {
      if bounds.min_x != -5.0 || bounds.max_x != 10.0 ||
         bounds.min_y != -8.0 || bounds.max_y != 7.0 {
        fail("Path bounds calculation incorrect")
      }
    }
    None => fail("Path with points should have bounds")
  }
}

test "empty path bounds" {
  let path = Path::empty()
  match path.bounds() {
    Some(_) => fail("Empty path should not have bounds")
    None => ()
  }
}

test "path with only close segment" {
  let path = Path::empty().close_path()
  
  if path.0.length() != 1 {
    fail("Path with only close should have 1 segment")
  }
  
  match path.bounds() {
    Some(_) => fail("Path with only Close should not have bounds")
    None => ()
  }
}
