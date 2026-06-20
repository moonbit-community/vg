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
/// Clip `self` to the inside of `path` (default non-zero winding). Outside the
/// path the result is transparent.
pub fn Image::cut(self : Image, path : Path, area? : Area = Anz) -> Image {
  Cut(area, path, self)
}

///|
#deprecated("Use `image.cut(path)` instead")
pub fn cut(path : Path, img : Image, area? : Area = Anz) -> Image {
  img.cut(path, area~)
}

///|
/// `self` composited over `bottom`.
pub fn Image::over(self : Image, bottom : Image) -> Image {
  Blend(Over, None, self, bottom)
}

///|
/// Blend `self` (the top layer) with `bottom` using an explicit operator and an
/// optional top alpha.
#as_free_fn(blend, deprecated="Use `top.blend(bottom)` instead")
pub fn Image::blend(
  self : Image,
  bottom : Image,
  op? : Blender = Over,
  alpha? : Double,
) -> Image {
  Blend(op, alpha, self, bottom)
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
/// A straight line segment stroked with the given thickness (round caps). A
/// zero-length segment renders as a dot.
pub fn Image::line(
  color : Color,
  start : Point,
  end : Point,
  thickness : Double,
) -> Image {
  let path = Path::empty().move_to(start).line_to(end)
  Cut(Outline(thickness), path, Primitive(Const(color)))
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

// ----- procedural images (a Raster colour field sampled by eval) -----

///|
/// An image from an arbitrary point -> colour function.
pub fn Image::of_fn(f : (Point) -> Color) -> Image {
  Primitive(Raster(f))
}

///|
/// A checkerboard of two colours with the given cell `size`.
pub fn Image::checkerboard(
  color1 : Color,
  color2 : Color,
  size : Double,
) -> Image {
  Image::of_fn(fn(p) {
    let x_cell = (p.x / size).floor().to_int()
    let y_cell = (p.y / size).floor().to_int()
    if (x_cell + y_cell) % 2 == 0 {
      color1
    } else {
      color2
    }
  })
}

///|
/// Tile `self` into `tile_width` x `tile_height` cells.
pub fn Image::tile(
  self : Image,
  tile_width : Double,
  tile_height : Double,
) -> Image {
  Image::of_fn(fn(p) {
    let tx = p.x % tile_width
    let ty = p.y % tile_height
    let nx = if tx < 0.0 { tx + tile_width } else { tx }
    let ny = if ty < 0.0 { ty + tile_height } else { ty }
    self.eval(Point(nx - tile_width / 2.0, ny - tile_height / 2.0))
  })
}

///|
/// An angular (conic) gradient around `center`, starting at `start_angle`.
pub fn Image::conic_gradient(
  color1 : Color,
  color2 : Color,
  center : Point,
  start_angle : Double,
) -> Image {
  Image::of_fn(fn(p) {
    let two_pi = 2.0 * 3.14159265358979
    let angle = @math.atan2(p.y - center.y, p.x - center.x)
    let normalized = ((angle - start_angle) % two_pi + two_pi) % two_pi
    @color.lerp_color(color1, color2, normalized / two_pi)
  })
}

// ----- text (draw-only) -----

///|
/// A text label anchored at the origin (centre-aligned). Position it with
/// transforms. Text is draw-only: `eval` is transparent for it, but the
/// SVG/PDF/canvas backends render it.
pub fn Image::text(content : String, size : Double, color : Color) -> Image {
  Text(content, size, color)
}
