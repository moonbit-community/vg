// Tests for text (draw-only Text nodes).

///|
test "text: draw-only, escaped, rendered by every backend" {
  let t = @vg.Image::text("Hi <&>", 16.0, @color.black())
  // eval is transparent: text has no point->colour denotation
  debug_inspect(
    t.eval(Point(0.0, 0.0)),
    content=(
      #|{ r: 0, g: 0, b: 0, a: 0 }
    ),
  )
  // SVG renders an escaped <text> element
  let svg = t.to_svg(100.0, 100.0)
  assert_true(svg.contains("<text"))
  assert_true(svg.contains("Hi &lt;&amp;&gt;"))
  // canvas + PDF also render the text
  assert_true(t.to_js(100.0, 100.0).contains("ctx.fillText('Hi <&>'"))
  assert_true(t.to_pdf(100.0, 100.0).contains(") Tj"))
}

///|
test "text: newlines are escaped in canvas JS output" {
  let t = @vg.Image::text("a\nb", 12.0, @color.black())
  let js = t.to_js(100.0, 100.0)
  // the literal must contain an escaped \n, not a raw line break
  assert_true(js.contains("'a\\nb'"))
  assert_true(!js.contains("'a\nb'"))
}
