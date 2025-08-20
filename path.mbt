// Path construction and manipulation utilities

///| Create an empty path
pub fn Path::empty() -> Path {
  Path([])
}

///| Move to a point
pub fn Path::move_to(self : Path, p : Point) -> Path {
  let new_path = Array::new()
  for segment in self.0 {
    new_path.push(segment)
  }
  new_path.push(MoveTo(p))
  Path(new_path)
}

///| Line to a point
pub fn Path::line_to(self : Path, p : Point) -> Path {
  let new_path = Array::new()
  for segment in self.0 {
    new_path.push(segment)
  }
  new_path.push(LineTo(p))
  Path(new_path)
}

///| Cubic bezier curve to a point
pub fn Path::curve_to(
  self : Path,
  cp1 : Point,
  cp2 : Point,
  end : Point,
) -> Path {
  let new_path = Array::new()
  for segment in self.0 {
    new_path.push(segment)
  }
  new_path.push(CurveTo(cp1, cp2, end))
  Path(new_path)
}

///| Quadratic bezier curve to a point
pub fn Path::qcurve_to(self : Path, cp : Point, end : Point) -> Path {
  let new_path = Array::new()
  for segment in self.0 {
    new_path.push(segment)
  }
  new_path.push(QCurveTo(cp, end))
  Path(new_path)
}

///| Elliptical arc to a point
pub fn Path::earc_to(
  self : Path,
  rx : Double,
  ry : Double,
  rotation : Double,
  large_arc : Bool,
  sweep : Bool,
  end : Point,
) -> Path {
  let new_path = Array::new()
  for segment in self.0 {
    new_path.push(segment)
  }
  new_path.push(EArcTo(rx, ry, rotation, large_arc, sweep, end))
  Path(new_path)
}

///| Close the path
pub fn Path::close_path(self : Path) -> Path {
  let new_path = Array::new()
  for segment in self.0 {
    new_path.push(segment)
  }
  new_path.push(Close)
  Path(new_path)
}

///| Create a rectangle path
pub fn Path::rect(
  x : Double,
  y : Double,
  width : Double,
  height : Double,
) -> Path {
  let top_left = point(x, y)
  let top_right = point(x + width, y)
  let bottom_right = point(x + width, y + height)
  let bottom_left = point(x, y + height)
  Path::empty()
  .move_to(top_left)
  .line_to(top_right)
  .line_to(bottom_right)
  .line_to(bottom_left)
  .close_path()
}

///| Create a circle path (approximated with bezier curves)
pub fn Path::circle(center : Point, radius : Double) -> Path {
  let kappa = 0.5522847498 // Magic number for circle approximation
  let offset = radius * kappa
  let top = point(center.x, center.y - radius)
  let right = point(center.x + radius, center.y)
  let bottom = point(center.x, center.y + radius)
  let left = point(center.x - radius, center.y)
  Path::empty()
  .move_to(top)
  .curve_to(
    point(center.x + offset, center.y - radius),
    point(center.x + radius, center.y - offset),
    right,
  )
  .curve_to(
    point(center.x + radius, center.y + offset),
    point(center.x + offset, center.y + radius),
    bottom,
  )
  .curve_to(
    point(center.x - offset, center.y + radius),
    point(center.x - radius, center.y + offset),
    left,
  )
  .curve_to(
    point(center.x - radius, center.y - offset),
    point(center.x - offset, center.y - radius),
    top,
  )
  .close_path()
}

///| Create an ellipse path
pub fn Path::ellipse(center : Point, rx : Double, ry : Double) -> Path {
  let kappa = 0.5522847498
  let offset_x = rx * kappa
  let offset_y = ry * kappa
  let top = point(center.x, center.y - ry)
  let right = point(center.x + rx, center.y)
  let bottom = point(center.x, center.y + ry)
  let left = point(center.x - rx, center.y)
  Path::empty()
  .move_to(top)
  .curve_to(
    point(center.x + offset_x, center.y - ry),
    point(center.x + rx, center.y - offset_y),
    right,
  )
  .curve_to(
    point(center.x + rx, center.y + offset_y),
    point(center.x + offset_x, center.y + ry),
    bottom,
  )
  .curve_to(
    point(center.x - offset_x, center.y + ry),
    point(center.x - rx, center.y + offset_y),
    left,
  )
  .curve_to(
    point(center.x - rx, center.y - offset_y),
    point(center.x - offset_x, center.y - ry),
    top,
  )
  .close_path()
}

///| Transform a path
pub fn Path::transform(self : Path, t : Transform) -> Path {
  let new_path = Array::new()
  for segment in self.0 {
    let transformed_segment = match segment {
      MoveTo(p) => MoveTo(apply(t, p))
      LineTo(p) => LineTo(apply(t, p))
      CurveTo(cp1, cp2, end) =>
        CurveTo(apply(t, cp1), apply(t, cp2), apply(t, end))
      QCurveTo(cp, end) => QCurveTo(apply(t, cp), apply(t, end))
      EArcTo(rx, ry, rotation, large_arc, sweep, end) =>
        EArcTo(rx, ry, rotation, large_arc, sweep, apply(t, end))
      Close => Close
    }
    new_path.push(transformed_segment)
  }
  Path(new_path)
}

///| Get the bounding box of a path (approximate)
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

///| Create a smooth cubic curve that connects smoothly to the previous segment
pub fn Path::smooth_ccurve_to(self : Path, cp2 : Point, end : Point) -> Path {
  let new_path = Array::new()
  for segment in self.0 {
    new_path.push(segment)
  }

  // Calculate smooth control point based on previous segment
  let cp1 = match self.0.length() {
    0 => cp2 // No previous segment, use cp2
    _ =>
      match self.0[self.0.length() - 1] {
        CurveTo(_, prev_cp2, prev_end) => {
          // Reflect the previous control point
          let reflected_x = 2.0 * prev_end.x - prev_cp2.x
          let reflected_y = 2.0 * prev_end.y - prev_cp2.y
          point(reflected_x, reflected_y)
        }
        _ => cp2 // Not a curve, use cp2
      }
  }
  new_path.push(CurveTo(cp1, cp2, end))
  Path(new_path)
}

///| Create a smooth quadratic curve that connects smoothly to the previous segment
pub fn Path::smooth_qcurve_to(self : Path, end : Point) -> Path {
  let new_path = Array::new()
  for segment in self.0 {
    new_path.push(segment)
  }

  // Calculate smooth control point based on previous segment
  let cp = match self.0.length() {
    0 => end // No previous segment, use end point
    _ =>
      match self.0[self.0.length() - 1] {
        QCurveTo(prev_cp, prev_end) => {
          // Reflect the previous control point
          let reflected_x = 2.0 * prev_end.x - prev_cp.x
          let reflected_y = 2.0 * prev_end.y - prev_cp.y
          point(reflected_x, reflected_y)
        }
        _ => end // Not a quadratic curve, use end point
      }
  }
  new_path.push(QCurveTo(cp, end))
  Path(new_path)
}
