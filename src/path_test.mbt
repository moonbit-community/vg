// Tests for path utilities

test "empty path creation" {
  let path = @vg.Path::empty()
  if path.0.length() != 0 {
    fail("Empty path should have zero segments")
  }
}

test "path building with move_to and line_to" {
  let path = @vg.Path::empty()
    .move_to(@vg.point(0.0, 0.0))
    .line_to(@vg.point(10.0, 0.0))
    .line_to(@vg.point(10.0, 10.0))
    .close_path()
  
  inspect(path, content="Path([MoveTo({x: 0, y: 0}), LineTo({x: 10, y: 0}), LineTo({x: 10, y: 10}), Close])")
}

test "curve_to segment" {
  let path = @vg.Path::empty()
    .move_to(@vg.point(0.0, 0.0))
    .curve_to(@vg.point(5.0, 0.0), @vg.point(10.0, 5.0), @vg.point(10.0, 10.0))
  
  inspect(path, content="Path([MoveTo({x: 0, y: 0}), CurveTo({x: 5, y: 0}, {x: 10, y: 5}, {x: 10, y: 10})])")
}

test "rectangle path" {
  let path = @vg.Path::rect(0.0, 0.0, 10.0, 5.0)
  
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
  let path = @vg.Path::circle(@vg.point(5.0, 5.0), 3.0)
  
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
  let path = @vg.Path::ellipse(@vg.point(0.0, 0.0), 5.0, 3.0)
  
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
  let original_path = @vg.Path::rect(0.0, 0.0, 2.0, 2.0)
  let transform = @vg.make_translate(5.0, 3.0)
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
  let path = @vg.Path::empty()
    .move_to(@vg.point(-5.0, -3.0))
    .line_to(@vg.point(10.0, 7.0))
    .line_to(@vg.point(2.0, -8.0))
  
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
  inspect(path.bounds(), content="None")
}

test "path with only close segment" {
  let path = Path::empty().close_path()
  inspect((path, path.bounds()), content="(Path([Close]), None)")
}

test "comprehensive path shapes" {
  let shapes = [
    ("rectangle", @vg.Path::rect(0.0, 0.0, 10.0, 5.0)),
    ("circle", @vg.Path::circle(@vg.point(5.0, 5.0), 3.0)),
    ("ellipse", @vg.Path::ellipse(@vg.point(0.0, 0.0), 5.0, 3.0)),
    ("complex_path", @vg.Path::empty()
      .move_to(@vg.point(0.0, 0.0))
      .line_to(@vg.point(10.0, 0.0))
      .curve_to(@vg.point(15.0, 0.0), @vg.point(15.0, 5.0), @vg.point(10.0, 5.0))
      .line_to(@vg.point(0.0, 5.0))
      .close_path())
  ]
  inspect(shapes, content=(
    #|[("rectangle", Path([MoveTo({x: 0, y: 0}), LineTo({x: 10, y: 0}), LineTo({x: 10, y: 5}), LineTo({x: 0, y: 5}), Close])), ("circle", Path([MoveTo({x: 5, y: 2}), CurveTo({x: 6.6568542494, y: 2}, {x: 8, y: 3.3431457506}, {x: 8, y: 5}), CurveTo({x: 8, y: 6.6568542494}, {x: 6.6568542494, y: 8}, {x: 5, y: 8}), CurveTo({x: 3.3431457506, y: 8}, {x: 2, y: 6.6568542494}, {x: 2, y: 5}), CurveTo({x: 2, y: 3.3431457506}, {x: 3.3431457506, y: 2}, {x: 5, y: 2}), Close])), ("ellipse", Path([MoveTo({x: 0, y: -3}), CurveTo({x: 2.761423749, y: -3}, {x: 5, y: -1.6568542493999998}, {x: 5, y: 0}), CurveTo({x: 5, y: 1.6568542493999998}, {x: 2.761423749, y: 3}, {x: 0, y: 3}), CurveTo({x: -2.761423749, y: 3}, {x: -5, y: 1.6568542493999998}, {x: -5, y: 0}), CurveTo({x: -5, y: -1.6568542493999998}, {x: -2.761423749, y: -3}, {x: 0, y: -3}), Close])), ("complex_path", Path([MoveTo({x: 0, y: 0}), LineTo({x: 10, y: 0}), CurveTo({x: 15, y: 0}, {x: 15, y: 5}, {x: 10, y: 5}), LineTo({x: 0, y: 5}), Close]))]
  ))
}

test "path bounds calculation" {
  let paths_with_bounds = [
    ("simple_line", @vg.Path::empty()
      .move_to(@vg.point(-5.0, -3.0))
      .line_to(@vg.point(10.0, 7.0)),
     @vg.Path::empty()
      .move_to(@vg.point(-5.0, -3.0))
      .line_to(@vg.point(10.0, 7.0))
      .bounds()),
    ("rectangle_bounds", @vg.Path::rect(2.0, 3.0, 8.0, 6.0),
     @vg.Path::rect(2.0, 3.0, 8.0, 6.0).bounds()),
    ("circle_bounds", @vg.Path::circle(@vg.point(0.0, 0.0), 5.0),
     @vg.Path::circle(@vg.point(0.0, 0.0), 5.0).bounds())
  ]
  inspect(paths_with_bounds, content=(
    #|[("simple_line", Path([MoveTo({x: -5, y: -3}), LineTo({x: 10, y: 7})]), Some({min_x: -5, min_y: -3, max_x: 10, max_y: 7})), ("rectangle_bounds", Path([MoveTo({x: 2, y: 3}), LineTo({x: 10, y: 3}), LineTo({x: 10, y: 9}), LineTo({x: 2, y: 9}), Close]), Some({min_x: 2, min_y: 3, max_x: 10, max_y: 9})), ("circle_bounds", Path([MoveTo({x: 0, y: -5}), CurveTo({x: 2.761423749, y: -5}, {x: 5, y: -2.761423749}, {x: 5, y: 0}), CurveTo({x: 5, y: 2.761423749}, {x: 2.761423749, y: 5}, {x: 0, y: 5}), CurveTo({x: -2.761423749, y: 5}, {x: -5, y: 2.761423749}, {x: -5, y: 0}), CurveTo({x: -5, y: -2.761423749}, {x: -2.761423749, y: -5}, {x: 0, y: -5}), Close]), Some({min_x: -5, min_y: -5, max_x: 5, max_y: 5}))]
  ))
}
