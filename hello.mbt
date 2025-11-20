// Main library interface

///|
/// Create a simple example image (functional style)
pub fn example() -> Image {
  let red_circle = circle(red(), 30.0)
  let blue_rect = rectangle(blue(), 40.0, 40.0)
  let translated_rect = translate_img(50.0, 0.0, blue_rect)
  compose_imgs(red_circle, translated_rect)
}

///|
/// Create a simple example image (OO-style)
pub fn example_oo() -> Image {
  let red_circle = circle(red(), 30.0)
  let blue_rect = rectangle(blue(), 40.0, 40.0)
  let translated_rect = blue_rect.translate(50.0, 0.0)
  compose_imgs(red_circle, translated_rect)
}
