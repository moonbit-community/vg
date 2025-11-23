// SVG rendering backend - Image method only

///|
/// Sample an image at regular intervals and render to SVG (OO-style)
pub fn Image::render_image_to_svg(
  self : Image,
  width : Double,
  height : Double,
  samples : Int,
) -> String {
  let mut doc = @svg.new_svg(width, height)
  let step = width / samples.to_double()
  for i in 0..<samples {
    for j in 0..<samples {
      let x = i.to_double() * step
      let y = j.to_double() * step
      let p = Point::new(x - width / 2.0, y - height / 2.0) // Center coordinate system
      let color = self(p)
      if color.a > 0.0 { // Only render non-transparent pixels
        doc = doc.render_rectangle(x, y, step, step, color)
      }
    }
  }
  doc.to_string()
}
