// Tests for the PDF vector fold (`Image::to_pdf`).

///|
test "pdf fold: a circle produces fill-path ops" {
  let pdf = @vg.Image::circle(@color.red(), 20.0).to_pdf(100.0, 100.0)
  assert_true(pdf.contains("%PDF-1.4"))
  assert_true(pdf.contains("1 0 0 rg")) // red fill colour
  assert_true(pdf.contains(" m\n")) // moveto
  assert_true(pdf.contains(" c\n")) // curveto (circle béziers)
  assert_true(pdf.contains("f\n")) // fill
}

///|
test "pdf fold: rectangle path is y-flipped" {
  // centred 100x60 rect -> canvas (50,70)..(150,130); PDF flips y (h=200)
  let pdf = @vg.Image::rectangle(@color.red(), 100.0, 60.0).to_pdf(200.0, 200.0)
  assert_true(pdf.contains("50 130 m")) // first corner, y flipped 70 -> 130
  assert_true(pdf.contains("f\nQ")) // fill then restore
}

///|
test "pdf fold: even-odd fill uses f*" {
  let img = @vg.Image::const_color(@color.blue()).cut(
    @vg.Path::rect(-10.0, -10.0, 20.0, 20.0),
    area=Aeo,
  )
  assert_true(img.to_pdf(50.0, 50.0).contains("f*"))
}

///|
test "pdf fold: clip emits W n" {
  let img = @vg.Image::circle(@color.red(), 5.0).cut(
    @vg.Path::circle(Point(0.0, 0.0), 10.0),
  )
  assert_true(img.to_pdf(50.0, 50.0).contains("W n"))
}

///|
test "pdf fold: a fully transparent image paints nothing" {
  // Image::empty() is a transparent colour field; it must not fill the page
  let pdf = @vg.Image::empty().to_pdf(100.0, 100.0)
  assert_true(!pdf.contains("re\nf")) // no viewport fill emitted
  assert_true(!pdf.contains(" rg\n")) // no fill colour set
}
