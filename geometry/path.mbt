// Path construction and manipulation utilities

///|
/// Create an empty path
pub fn Path::empty() -> Path {
  Path([])
}

///|
/// Move to a point
pub fn Path::move_to(self : Path, p : Point) -> Path {
  Path([..self.0, MoveTo(p)])
}

///|
/// Line to a point
pub fn Path::line_to(self : Path, p : Point) -> Path {
  Path([..self.0, LineTo(p)])
}

///|
/// Cubic bezier curve to a point
pub fn Path::curve_to(
  self : Path,
  cp1 : Point,
  cp2 : Point,
  end : Point,
) -> Path {
  Path([..self.0, CurveTo(cp1, cp2, end)])
}

///|
/// Quadratic bezier curve to a point
pub fn Path::qcurve_to(self : Path, cp : Point, end : Point) -> Path {
  Path([..self.0, QCurveTo(cp, end)])
}

///|
/// Elliptical arc to a point
pub fn Path::earc_to(
  self : Path,
  rx : Double,
  ry : Double,
  rotation : Double,
  large_arc : Bool,
  sweep : Bool,
  end : Point,
) -> Path {
  Path([..self.0, EArcTo(rx, ry, rotation, large_arc, sweep, end)])
}

///|
/// Close the path
pub fn Path::close_path(self : Path) -> Path {
  Path([..self.0, Close])
}

///|
/// Create a rectangle path
pub fn Path::rect(
  x : Double,
  y : Double,
  width : Double,
  height : Double,
) -> Path {
  let top_left = Point::Point(x, y)
  let top_right = Point::Point(x + width, y)
  let bottom_right = Point::Point(x + width, y + height)
  let bottom_left = Point::Point(x, y + height)
  Path::empty()
  .move_to(top_left)
  .line_to(top_right)
  .line_to(bottom_right)
  .line_to(bottom_left)
  .close_path()
}

///|
/// Create a circle path (approximated with bezier curves)
pub fn Path::circle(center : Point, radius : Double) -> Path {
  let kappa = 0.5522847498 // Magic number for circle approximation
  let offset = radius * kappa
  let top = Point::Point(center.x, center.y - radius)
  let right = Point::Point(center.x + radius, center.y)
  let bottom = Point::Point(center.x, center.y + radius)
  let left = Point::Point(center.x - radius, center.y)
  Path::empty()
  .move_to(top)
  .curve_to(
    Point(center.x + offset, center.y - radius),
    Point(center.x + radius, center.y - offset),
    right,
  )
  .curve_to(
    Point(center.x + radius, center.y + offset),
    Point(center.x + offset, center.y + radius),
    bottom,
  )
  .curve_to(
    Point(center.x - offset, center.y + radius),
    Point(center.x - radius, center.y + offset),
    left,
  )
  .curve_to(
    Point(center.x - radius, center.y - offset),
    Point(center.x - offset, center.y - radius),
    top,
  )
  .close_path()
}

///|
/// Create an ellipse path
pub fn Path::ellipse(center : Point, rx : Double, ry : Double) -> Path {
  let kappa = 0.5522847498
  let offset_x = rx * kappa
  let offset_y = ry * kappa
  let top = Point::Point(center.x, center.y - ry)
  let right = Point::Point(center.x + rx, center.y)
  let bottom = Point::Point(center.x, center.y + ry)
  let left = Point::Point(center.x - rx, center.y)
  Path::empty()
  .move_to(top)
  .curve_to(
    Point(center.x + offset_x, center.y - ry),
    Point(center.x + rx, center.y - offset_y),
    right,
  )
  .curve_to(
    Point(center.x + rx, center.y + offset_y),
    Point(center.x + offset_x, center.y + ry),
    bottom,
  )
  .curve_to(
    Point(center.x - offset_x, center.y + ry),
    Point(center.x - rx, center.y + offset_y),
    left,
  )
  .curve_to(
    Point(center.x - rx, center.y - offset_y),
    Point(center.x - offset_x, center.y - ry),
    top,
  )
  .close_path()
}

///|
/// Get the bounding box of a path (approximate)
pub fn Path::bounds(self : Path) -> Box? {
  let mut min_x = 1000000.0
  let mut min_y = 1000000.0
  let mut max_x = -1000000.0
  let mut max_y = -1000000.0
  let mut has_points = false
  fn update_bounds(p : Point) {
    has_points = true
    if p.x < min_x {
      min_x = p.x
    }
    if p.x > max_x {
      max_x = p.x
    }
    if p.y < min_y {
      min_y = p.y
    }
    if p.y > max_y {
      max_y = p.y
    }
  }

  for segment in self.0 {
    match segment {
      MoveTo(p) | LineTo(p) => update_bounds(p)
      CurveTo(cp1, cp2, end) => {
        update_bounds(cp1)
        update_bounds(cp2)
        update_bounds(end)
      }
      QCurveTo(cp, end) => {
        update_bounds(cp)
        update_bounds(end)
      }
      EArcTo(_, _, _, _, _, end) => update_bounds(end) // Simplified bounds for arcs
      Close => ()
    }
  }
  if has_points {
    Some({ min_x, min_y, max_x, max_y })
  } else {
    None
  }
}

///|
/// Create a smooth cubic curve that connects smoothly to the previous segment
pub fn Path::smooth_ccurve_to(self : Path, cp2 : Point, end : Point) -> Path {
  // reflect the previous cubic control point for a smooth join
  let cp1 = match self.0 {
    [.., CurveTo(_, prev_cp2, prev_end)] =>
      Point(2.0 * prev_end.x - prev_cp2.x, 2.0 * prev_end.y - prev_cp2.y)
    _ => cp2
  }
  Path([..self.0, CurveTo(cp1, cp2, end)])
}

///|
/// Create a smooth quadratic curve that connects smoothly to the previous segment
pub fn Path::smooth_qcurve_to(self : Path, end : Point) -> Path {
  // reflect the previous quadratic control point for a smooth join
  let cp = match self.0 {
    [.., QCurveTo(prev_cp, prev_end)] =>
      Point(2.0 * prev_end.x - prev_cp.x, 2.0 * prev_end.y - prev_cp.y)
    _ => end
  }
  Path([..self.0, QCurveTo(cp, end)])
}

///|
/// Transform a path using a transformation matrix
pub fn Path::transform(self : Path, t : Transform) -> Path {
  Path(
    [
      for segment in self.0 => {
        match segment {
          MoveTo(p) => MoveTo(apply(t, p))
          LineTo(p) => LineTo(apply(t, p))
          CurveTo(cp1, cp2, end) =>
            CurveTo(apply(t, cp1), apply(t, cp2), apply(t, end))
          QCurveTo(cp, end) => QCurveTo(apply(t, cp), apply(t, end))
          EArcTo(rx, ry, rotation, large_arc, sweep, end) =>
            EArcTo(rx, ry, rotation, large_arc, sweep, apply(t, end))
          Close => Close
        }
      }
    ],
  )
}
