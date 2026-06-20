// Image combinators: build the declarative AST.
//
// Convenience shape constructors are sugar for cutting a path out of a constant
// colour field, mirroring Vg's "primitives are colour fields, paths cut them".

// ----- smart constructors (the faithful core) -----

///|
/// A constant colour filling the whole plane.
pub fn Image::const_color(color : Color) -> Image {
  Primitive(Const(color))
}

///|
/// The empty (fully transparent) image.
pub fn Image::empty() -> Image {
  Primitive(Const(@color.transparent()))
}

///|
/// Cut image `img` to the inside of `path` (default non-zero winding). Outside
/// the path the result is transparent.
pub fn cut(path : Path, img : Image, area? : Area = Anz) -> Image {
  Cut(area, path, img)
}

///|
/// `self` composited over `bottom`.
pub fn Image::over(self : Image, bottom : Image) -> Image {
  Blend(Over, None, self, bottom)
}

///|
/// Blend `top` with `bottom` using an explicit operator and optional top alpha.
pub fn blend(
  top : Image,
  bottom : Image,
  op? : Blender = Over,
  alpha? : Double,
) -> Image {
  Blend(op, alpha, top, bottom)
}

// ----- transforms -----

///|
pub fn Image::transform(self : Image, t : Transform) -> Image {
  Tr(t, self)
}

///|
pub fn Image::translate_img(self : Image, dx : Double, dy : Double) -> Image {
  Tr(@geometry.make_translate(dx, dy), self)
}

///|
pub fn Image::scale(self : Image, sx : Double, sy : Double) -> Image {
  Tr(@geometry.make_scale(sx, sy), self)
}

///|
pub fn Image::rotate(self : Image, angle : Double) -> Image {
  Tr(@geometry.make_rotate(angle), self)
}

// ----- compositing -----

///|
/// Compose `other` over `self` (the receiver is the base layer), so
/// `base.compose(overlay)` paints the overlay on top.
pub fn Image::compose(self : Image, other : Image) -> Image {
  Blend(Over, None, other, self)
}

///|
/// Scale an image's opacity by `opacity`.
pub fn Image::with_opacity(self : Image, opacity : Double) -> Image {
  Blend(Over, Some(opacity), self, Image::empty())
}

// ----- convenience shapes (cut a path from a const colour field) -----

///|
pub fn Image::circle(color : Color, radius : Double) -> Image {
  Cut(Anz, Path::circle(Point(0.0, 0.0), radius), Primitive(Const(color)))
}

///|
pub fn Image::rectangle(
  color : Color,
  width : Double,
  height : Double,
) -> Image {
  Cut(
    Anz,
    Path::rect(-width / 2.0, -height / 2.0, width, height),
    Primitive(Const(color)),
  )
}

///|
pub fn Image::ellipse(color : Color, rx : Double, ry : Double) -> Image {
  Cut(Anz, Path::ellipse(Point(0.0, 0.0), rx, ry), Primitive(Const(color)))
}

///|
pub fn Image::polygon(color : Color, points : Array[Point]) -> Image {
  Cut(Anz, polygon_path(points), Primitive(Const(color)))
}

///|
/// A straight line segment of the given thickness, as a filled quad.
pub fn Image::line(
  color : Color,
  start : Point,
  end : Point,
  thickness : Double,
) -> Image {
  let dx = end.x - start.x
  let dy = end.y - start.y
  let len = (dx * dx + dy * dy).sqrt()
  // a zero-length thick segment still renders as a dot
  guard len > 0.0 else {
    Cut(Anz, Path::circle(start, thickness / 2.0), Primitive(Const(color)))
  }
  let nx = -dy / len * thickness / 2.0
  let ny = dx / len * thickness / 2.0
  let pts = [
    Point(start.x + nx, start.y + ny),
    Point(end.x + nx, end.y + ny),
    Point(end.x - nx, end.y - ny),
    Point(start.x - nx, start.y - ny),
  ]
  Cut(Anz, polygon_path(pts), Primitive(Const(color)))
}

///|
fn polygon_path(points : Array[Point]) -> Path {
  guard points.length() > 0 else { Path::empty() }
  let mut p = Path::empty().move_to(points[0])
  for i in 1..<points.length() {
    p = p.line_to(points[i])
  }
  p.close_path()
}

// ----- gradients (infinite colour-field primitives) -----

///|
pub fn Image::linear_gradient(
  color1 : Color,
  color2 : Color,
  start : Point,
  end : Point,
) -> Image {
  Primitive(
    Axial(
      [{ offset: 0.0, color: color1 }, { offset: 1.0, color: color2 }],
      start,
      end,
    ),
  )
}

///|
pub fn Image::axial_gradient(
  color1 : Color,
  color2 : Color,
  start : Point,
  end : Point,
) -> Image {
  Image::linear_gradient(color1, color2, start, end)
}

///|
pub fn Image::radial_gradient(
  color1 : Color,
  color2 : Color,
  center : Point,
  radius : Double,
) -> Image {
  Primitive(
    Radial(
      [{ offset: 0.0, color: color1 }, { offset: 1.0, color: color2 }],
      center,
      center,
      radius,
    ),
  )
}

// ----- raster sampling (fallback; superseded by vector folds for backends) -----

///|
/// Sample the image on a grid and emit one SVG rect per opaque cell. This is the
/// raster fallback (`eval`-based); vector backends render the AST directly and
/// produce far smaller output.
pub fn Image::render_image_to_svg(
  self : Image,
  width : Double,
  height : Double,
  samples : Int,
) -> String {
  let mut doc = @svg.new_svg(width, height)
  let step_x = width / samples.to_double()
  let step_y = height / samples.to_double()
  for i in 0..<samples {
    for j in 0..<samples {
      let x = i.to_double() * step_x
      let y = j.to_double() * step_y
      let p = Point(x - width / 2.0, y - height / 2.0)
      let color = self.eval(p)
      if color.a > 0.0 {
        doc = doc.render_rectangle(x, y, step_x, step_y, color)
      }
    }
  }
  doc.to_string()
}
