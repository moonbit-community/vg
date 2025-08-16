// Main library interface - re-exports from all modules

// Re-export types
pub use types.{Point, Color, Vec2, Transform, Box, Image, PathSegment, Path, Primitive, ImageOp}
pub use svg.{SvgDocument}

// Color utilities
pub fn rgba(r : Double, g : Double, b : Double, a : Double) -> Color { color.rgba(r, g, b, a) }
pub fn rgb(r : Double, g : Double, b : Double) -> Color { color.rgb(r, g, b) }
pub fn gray(value : Double) -> Color { color.gray(value) }
pub fn transparent() -> Color { color.transparent() }
pub fn black() -> Color { color.black() }
pub fn white() -> Color { color.white() }
pub fn red() -> Color { color.red() }
pub fn green() -> Color { color.green() }
pub fn blue() -> Color { color.blue() }
pub fn yellow() -> Color { color.yellow() }
pub fn cyan() -> Color { color.cyan() }
pub fn magenta() -> Color { color.magenta() }
pub fn gold() -> Color { color.gold() }
pub fn orange() -> Color { color.orange() }
pub fn purple() -> Color { color.purple() }
pub fn blend(c1 : Color, c2 : Color) -> Color { color.blend(c1, c2) }
pub fn scale_color(c : Color, factor : Double) -> Color { color.scale(c, factor) }
pub fn to_hex(c : Color) -> String { color.to_hex(c) }
pub fn clamp_color(c : Color) -> Color { color.clamp(c) }

// Point utilities
pub fn point(x : Double, y : Double) -> Point { point.point(x, y) }
pub fn origin() -> Point { point.origin() }
pub fn add_points(p1 : Point, p2 : Point) -> Point { point.add(p1, p2) }
pub fn sub_points(p1 : Point, p2 : Point) -> Point { point.sub(p1, p2) }
pub fn scale_point(p : Point, factor : Double) -> Point { point.scale(p, factor) }
pub fn distance(p1 : Point, p2 : Point) -> Double { point.distance(p1, p2) }
pub fn dot(p1 : Point, p2 : Point) -> Double { point.dot(p1, p2) }
pub fn length(p : Point) -> Double { point.length(p) }
pub fn normalize(p : Point) -> Point { point.normalize(p) }
pub fn lerp(p1 : Point, p2 : Point, t : Double) -> Point { point.lerp(p1, p2, t) }
pub fn rotate_point(p : Point, angle : Double) -> Point { point.rotate(p, angle) }

// Transform utilities
pub fn identity() -> Transform { transform.identity() }
pub fn make_translate(dx : Double, dy : Double) -> Transform { transform.translate(dx, dy) }
pub fn make_scale(sx : Double, sy : Double) -> Transform { transform.scale(sx, sy) }
pub fn scale_uniform(s : Double) -> Transform { transform.scale_uniform(s) }
pub fn make_rotate(angle : Double) -> Transform { transform.rotate(angle) }
pub fn skew_x(angle : Double) -> Transform { transform.skew_x(angle) }
pub fn skew_y(angle : Double) -> Transform { transform.skew_y(angle) }
pub fn compose_transforms(t1 : Transform, t2 : Transform) -> Transform { transform.compose(t1, t2) }
pub fn apply_transform(t : Transform, p : Point) -> Point { transform.apply(t, p) }
pub fn invert(t : Transform) -> Transform? { transform.invert(t) }
pub fn determinant(t : Transform) -> Double { transform.determinant(t) }
pub fn preserves_orientation(t : Transform) -> Bool { transform.preserves_orientation(t) }

// Image combinators
pub fn const_image(color : Color) -> Image { image.const(color) }
pub fn empty() -> Image { image.empty() }
pub fn circle(color : Color, radius : Double) -> Image { image.circle(color, radius) }
pub fn rectangle(color : Color, width : Double, height : Double) -> Image { image.rectangle(color, width, height) }
pub fn line(color : Color, start : Point, end : Point, thickness : Double) -> Image { image.line(color, start, end, thickness) }
pub fn transform_image(t : Transform, img : Image) -> Image { image.transform(t, img) }
pub fn translate_image(dx : Double, dy : Double, img : Image) -> Image { image.translate(dx, dy, img) }
pub fn scale_image(sx : Double, sy : Double, img : Image) -> Image { image.scale_image(sx, sy, img) }
pub fn rotate_image(angle : Double, img : Image) -> Image { image.rotate_image(angle, img) }
pub fn compose_images(img1 : Image, img2 : Image) -> Image { image.compose(img1, img2) }
pub fn cut(img : Image, mask : Image) -> Image { image.cut(img, mask) }
pub fn linear_gradient(color1 : Color, color2 : Color, start : Point, end : Point) -> Image { image.linear_gradient(color1, color2, start, end) }
pub fn radial_gradient(color1 : Color, color2 : Color, center : Point, radius : Double) -> Image { image.radial_gradient(color1, color2, center, radius) }

// Path utilities
pub fn empty_path() -> Path { path.empty_path() }
pub fn move_to(path : Path, p : Point) -> Path { path.move_to(path, p) }
pub fn line_to(path : Path, p : Point) -> Path { path.line_to(path, p) }
pub fn curve_to(path : Path, cp1 : Point, cp2 : Point, end : Point) -> Path { path.curve_to(path, cp1, cp2, end) }
pub fn close_path(path : Path) -> Path { path.close_path(path) }
pub fn rect_path(x : Double, y : Double, width : Double, height : Double) -> Path { path.rect_path(x, y, width, height) }
pub fn circle_path(center : Point, radius : Double) -> Path { path.circle_path(center, radius) }
pub fn ellipse_path(center : Point, rx : Double, ry : Double) -> Path { path.ellipse_path(center, rx, ry) }
pub fn transform_path(t : Transform, path : Path) -> Path { path.transform_path(t, path) }
pub fn path_bounds(path : Path) -> Box? { path.path_bounds(path) }

// SVG rendering
pub fn new_svg(width : Double, height : Double) -> SvgDocument { svg.new_svg(width, height) }
pub fn add_element(doc : SvgDocument, element : String) -> SvgDocument { svg.add_element(doc, element) }
pub fn render_circle(doc : SvgDocument, center : Point, radius : Double, color : Color) -> SvgDocument { svg.render_circle(doc, center, radius, color) }
pub fn render_rectangle(doc : SvgDocument, x : Double, y : Double, width : Double, height : Double, color : Color) -> SvgDocument { svg.render_rectangle(doc, x, y, width, height, color) }
pub fn render_path(doc : SvgDocument, path : Path, color : Color) -> SvgDocument { svg.render_path(doc, path, color) }
pub fn render_line(doc : SvgDocument, start : Point, end : Point, color : Color, thickness : Double) -> SvgDocument { svg.render_line(doc, start, end, color, thickness) }
pub fn render_text(doc : SvgDocument, text : String, pos : Point, size : Double, color : Color) -> SvgDocument { svg.render_text(doc, text, pos, size, color) }
pub fn render_linear_gradient(doc : SvgDocument, id : String, start : Point, end : Point, color1 : Color, color2 : Color) -> SvgDocument { svg.render_linear_gradient(doc, id, start, end, color1, color2) }
pub fn to_svg_string(doc : SvgDocument) -> String { svg.to_svg_string(doc) }
pub fn render_image_to_svg(img : Image, width : Double, height : Double, samples : Int) -> String { svg.render_image_to_svg(img, width, height, samples) }

/// Create a simple example image
pub fn example() -> Image {
  let red_circle = image.circle(color.red(), 30.0)
  let blue_rect = image.rectangle(color.blue(), 40.0, 40.0)
  let translated_rect = image.translate(50.0, 0.0, blue_rect)
  image.compose(red_circle, translated_rect)
}
