// Tests for color utilities

///|
test "rgba color creation" {
  let c = rgba(0.5, 0.7, 0.9, 0.8)
  inspect(c, content="{r: 0.5, g: 0.7, b: 0.9, a: 0.8}")
}

///|
test "rgb color creation" {
  let c = rgb(0.2, 0.4, 0.6)
  inspect(c, content="{r: 0.2, g: 0.4, b: 0.6, a: 1}")
}

///|
test "gray color creation" {
  let c = gray(0.5)
  inspect(c, content="{r: 0.5, g: 0.5, b: 0.5, a: 1}")
}

///|
test "transparent color" {
  let c = transparent()
  inspect(c, content="{r: 0, g: 0, b: 0, a: 0}")
}

///|
test "predefined colors" {
  let colors = [
    ("red", red()),
    ("green", green()),
    ("blue", blue()),
    ("white", white()),
    ("black", black()),
    ("cyan", cyan()),
    ("magenta", magenta()),
    ("yellow", yellow()),
    ("orange", orange()),
    ("purple", purple()),
    ("gold", gold()),
  ]
  inspect(
    colors,
    content=(
      #|[("red", {r: 1, g: 0, b: 0, a: 1}), ("green", {r: 0, g: 1, b: 0, a: 1}), ("blue", {r: 0, g: 0, b: 1, a: 1}), ("white", {r: 1, g: 1, b: 1, a: 1}), ("black", {r: 0, g: 0, b: 0, a: 1}), ("cyan", {r: 0, g: 1, b: 1, a: 1}), ("magenta", {r: 1, g: 0, b: 1, a: 1}), ("yellow", {r: 1, g: 1, b: 0, a: 1}), ("orange", {r: 1, g: 0.647, b: 0, a: 1}), ("purple", {r: 0.5, g: 0, b: 0.5, a: 1}), ("gold", {r: 1, g: 0.843, b: 0, a: 1})]
    ),
  )
}

///|
test "color blending" {
  let c1 = rgba(1.0, 0.0, 0.0, 0.5) // Semi-transparent red
  let c2 = rgba(0.0, 1.0, 0.0, 0.5) // Semi-transparent green
  let blended = blend(c1, c2)
  inspect(
    blended,
    content="{r: 0.6666666666666666, g: 0.3333333333333333, b: 0, a: 0.75}",
  )
}

///|
test "color scaling" {
  let c = @vg.rgb(0.8, 0.6, 0.4)
  let scaled = scale(c, 0.5)
  inspect(scaled, content="{r: 0.4, g: 0.3, b: 0.2, a: 1}")
}

///|
test "color clamping" {
  let c = rgba(1.5, -0.5, 0.5, 2.0)
  let clamped = clamp(c)
  if clamped.r != 1.0 ||
    clamped.g != 0.0 ||
    clamped.b != 0.5 ||
    clamped.a != 1.0 {
    fail("Color clamping incorrect")
  }
}

///|
test "color to hex conversion" {
  let colors_and_hex = [
    ("red", red(), to_hex(red())),
    ("green", green(), to_hex(green())),
    ("blue", blue(), to_hex(blue())),
    ("orange", rgb(1.0, 0.5, 0.0), to_hex(rgb(1.0, 0.5, 0.0))),
    ("gray", gray(0.5), to_hex(gray(0.5))),
  ]
  inspect(
    colors_and_hex,
    content=(
      #|[("red", {r: 1, g: 0, b: 0, a: 1}, "#FF0000"), ("green", {r: 0, g: 1, b: 0, a: 1}, "#00FF00"), ("blue", {r: 0, g: 0, b: 1, a: 1}, "#0000FF"), ("orange", {r: 1, g: 0.5, b: 0, a: 1}, "#FF7F00"), ("gray", {r: 0.5, g: 0.5, b: 0.5, a: 1}, "#7F7F7F")]
    ),
  )
}

///|
test "hsv color space" {
  let hsv_colors = [
    ("red_hsv", hsv(0.0, 1.0, 1.0)), // Pure red
    ("green_hsv", hsv(120.0, 1.0, 1.0)), // Pure green  
    ("blue_hsv", hsv(240.0, 1.0, 1.0)), // Pure blue
    ("yellow_hsv", hsv(60.0, 1.0, 1.0)), // Pure yellow
    ("orange_hsv", hsv(30.0, 1.0, 1.0)), // Orange
    ("purple_hsv", hsv(300.0, 1.0, 1.0)), // Purple
    ("gray_hsv", hsv(0.0, 0.0, 0.5)), // Gray (no saturation)
    ("dark_red", hsv(0.0, 1.0, 0.5)), // Dark red (low value)
  ]
  inspect(
    hsv_colors,
    content=(
      #|[("red_hsv", {r: 1, g: 0, b: 0, a: 1}), ("green_hsv", {r: 0, g: 1, b: 0, a: 1}), ("blue_hsv", {r: 0, g: 0, b: 1, a: 1}), ("yellow_hsv", {r: 1, g: 1, b: 0, a: 1}), ("orange_hsv", {r: 1, g: 0.5, b: 0, a: 1}), ("purple_hsv", {r: 1, g: 0, b: 1, a: 1}), ("gray_hsv", {r: 0.5, g: 0.5, b: 0.5, a: 1}), ("dark_red", {r: 0.5, g: 0, b: 0, a: 1})]
    ),
  )
}

///|
test "color interpolation" {
  let interpolations = [
    ("red_to_blue_0", lerp_color(red(), blue(), 0.0)),
    ("red_to_blue_25", lerp_color(red(), blue(), 0.25)),
    ("red_to_blue_50", lerp_color(red(), blue(), 0.5)),
    ("red_to_blue_75", lerp_color(red(), blue(), 0.75)),
    ("red_to_blue_100", lerp_color(red(), blue(), 1.0)),
    ("white_to_black_50", lerp_color(white(), black(), 0.5)),
    ("transparent_to_opaque", lerp_color(transparent(), red(), 0.5)),
  ]
  inspect(
    interpolations,
    content=(
      #|[("red_to_blue_0", {r: 1, g: 0, b: 0, a: 1}), ("red_to_blue_25", {r: 0.75, g: 0, b: 0.25, a: 1}), ("red_to_blue_50", {r: 0.5, g: 0, b: 0.5, a: 1}), ("red_to_blue_75", {r: 0.25, g: 0, b: 0.75, a: 1}), ("red_to_blue_100", {r: 0, g: 0, b: 1, a: 1}), ("white_to_black_50", {r: 0.5, g: 0.5, b: 0.5, a: 1}), ("transparent_to_opaque", {r: 0.5, g: 0, b: 0, a: 0.5})]
    ),
  )
}
