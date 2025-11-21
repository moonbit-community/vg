// Main library interface

///|
/// Create a simple example image
pub fn example() -> Image {
  let red_circle = Image::circle(red(), 30.0)
  let blue_rect = Image::rectangle(blue(), 40.0, 40.0)
  let translated_rect = blue_rect.translate_img(50.0, 0.0)
  red_circle.compose(translated_rect)
}
