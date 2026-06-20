// Turtle graphics: interpret a turtle / L-system command string into vector
// strokes, producing a single stroked `@vg.Image` path.

///|
/// Interpret a turtle command string into an image of strokes. Other characters
/// are ignored, so rewrite-only symbols (e.g. `X`) are fine.
///
/// Commands:
/// - `F` — step forward, drawing a line
/// - `f` — step forward without drawing
/// - `+` — turn left by `angle` radians
/// - `-` — turn right by `angle` radians
/// - `[` — push the current position and heading
/// - `]` — pop them (for branching)
pub fn render(
  commands : String,
  angle~ : Double,
  step? : Double = 10.0,
  start? : @geometry.Point = Point(0.0, 0.0),
  heading? : Double = -1.5707963267948966, // -pi/2: pointing up
  color? : @color.Color = @color.black(),
  thickness? : Double = 1.0,
) -> @vg.Image {
  let mut x = start.x
  let mut y = start.y
  let mut h = heading
  let stack : Array[(Double, Double, Double)] = []
  // build the segment array in one pass (O(n)); the copying path builders would
  // make `render` quadratic in the number of drawn commands
  let segments : Array[@geometry.PathSegment] = [MoveTo(start)]
  for ch in commands {
    match ch {
      'F' => {
        x += step * @math.cos(h)
        y += step * @math.sin(h)
        segments.push(LineTo(Point(x, y)))
      }
      'f' => {
        x += step * @math.cos(h)
        y += step * @math.sin(h)
        segments.push(MoveTo(Point(x, y)))
      }
      // screen y is down, so a left (counter-clockwise) turn decreases the angle
      '+' => h -= angle
      '-' => h += angle
      '[' => stack.push((x, y, h))
      ']' =>
        match stack.pop() {
          Some((px, py, ph)) => {
            x = px
            y = py
            h = ph
            segments.push(MoveTo(Point(x, y)))
          }
          None => ()
        }
      _ => ()
    }
  }
  @vg.Image::const_color(color).cut(Path(segments), area=Outline(thickness))
}
