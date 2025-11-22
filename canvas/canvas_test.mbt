// Tests for canvas rendering

///|
test "canvas document creation" {
  let doc = @canvas.new_canvas(300.0, 200.0)
  inspect(doc, content="{width: 300, height: 200, commands: []}")
}

///|
test "canvas add command" {
  let doc = @canvas.new_canvas(100.0, 100.0)
    .add_command("ctx.fillStyle = 'red';")
    .add_command("ctx.fillRect(0, 0, 50, 50);")
  inspect(
    doc,
    content=(
      #|{width: 100, height: 100, commands: ["ctx.fillStyle = 'red';", "ctx.fillRect(0, 0, 50, 50);"]}
    ),
  )
}

///|
test "canvas render circle" {
  let doc = @canvas.new_canvas(200.0, 200.0)
    .render_circle(@geometry.Point::new(100.0, 100.0), 50.0, @color.red())
  inspect(
    doc,
    content=(
      #|{width: 200, height: 200, commands: ["ctx.beginPath();", "ctx.arc(100, 100, 50, 0, 2 * Math.PI);", "ctx.fillStyle = '#FF0000';", "ctx.fill();"]}
    ),
  )
}

///|
test "canvas render rectangle" {
  let doc = @canvas.new_canvas(200.0, 200.0)
    .render_rectangle(10.0, 20.0, 60.0, 40.0, @color.green())
  inspect(
    doc,
    content=(
      #|{width: 200, height: 200, commands: ["ctx.fillStyle = '#00FF00';", "ctx.fillRect(10, 20, 60, 40);"]}
    ),
  )
}

///|
test "canvas render line" {
  let doc = @canvas.new_canvas(200.0, 200.0)
    .render_line(
      @geometry.Point::new(10.0, 20.0),
      @geometry.Point::new(100.0, 80.0),
      @color.blue(),
      2.0,
    )
  inspect(
    doc,
    content=(
      #|{width: 200, height: 200, commands: ["ctx.beginPath();", "ctx.moveTo(10, 20);", "ctx.lineTo(100, 80);", "ctx.strokeStyle = '#0000FF';", "ctx.lineWidth = 2;", "ctx.lineCap = 'round';", "ctx.stroke();"]}
    ),
  )
}

///|
test "canvas render text" {
  let doc = @canvas.new_canvas(200.0, 200.0)
    .render_text("Hello", @geometry.Point::new(100.0, 100.0), 16.0, @color.black())
  inspect(
    doc,
    content=(
      #|{width: 200, height: 200, commands: ["ctx.font = '16px Arial, sans-serif';", "ctx.fillStyle = '#000000';", "ctx.textAlign = 'center';", "ctx.textBaseline = 'middle';", "ctx.fillText('Hello', 100, 100);"]}
    ),
  )
}

///|
test "canvas render path" {
  let path = @geometry.Path::empty()
    .move_to(@geometry.Point::new(10.0, 10.0))
    .line_to(@geometry.Point::new(50.0, 10.0))
    .line_to(@geometry.Point::new(50.0, 50.0))
    .close_path()
  let doc = @canvas.new_canvas(100.0, 100.0).render_path(path, @color.purple())
  inspect(
    doc,
    content=(
      #|{width: 100, height: 100, commands: ["ctx.beginPath();", "ctx.moveTo(10, 10);", "ctx.lineTo(50, 10);", "ctx.lineTo(50, 50);", "ctx.closePath();", "ctx.fillStyle = '#7F007F';", "ctx.fill();"]}
    ),
  )
}

///|
test "canvas to_js basic" {
  let doc = @canvas.new_canvas(100.0, 100.0)
    .render_rectangle(10.0, 10.0, 50.0, 50.0, @color.red())
  let js = doc.to_js()
  if !js.contains("function drawVgGraphics(canvas)") {
    fail("JS should contain function definition")
  }
  if !js.contains("canvas.width = 100") {
    fail("JS should set canvas width")
  }
  if !js.contains("canvas.height = 100") {
    fail("JS should set canvas height")
  }
  if !js.contains("ctx.fillRect(10, 10, 50, 50)") {
    fail("JS should contain fillRect command")
  }
}

///|
test "canvas to_html basic" {
  let doc = @canvas.new_canvas(100.0, 100.0)
    .render_circle(@geometry.Point::new(50.0, 50.0), 25.0, @color.blue())
  let html = doc.to_html("Test Canvas")
  if !html.contains("<!DOCTYPE html>") {
    fail("HTML should contain DOCTYPE")
  }
  if !html.contains("<title>Test Canvas</title>") {
    fail("HTML should contain title")
  }
  if !html.contains("<canvas id=\"vgCanvas\"></canvas>") {
    fail("HTML should contain canvas element")
  }
  if !html.contains("ctx.arc(50, 50, 25, 0, 2 * Math.PI)") {
    fail("HTML should contain arc command")
  }
}

///|
test "canvas semi-transparent color" {
  let doc = @canvas.new_canvas(100.0, 100.0)
    .render_circle(
      @geometry.Point::new(50.0, 50.0),
      25.0,
      @color.rgba(1.0, 0.0, 0.0, 0.5),
    )
  inspect(
    doc,
    content=(
      #|{width: 100, height: 100, commands: ["ctx.beginPath();", "ctx.arc(50, 50, 25, 0, 2 * Math.PI);", "ctx.fillStyle = 'rgba(255,0,0,0.5)';", "ctx.fill();"]}
    ),
  )
}

///|
test "canvas chained operations" {
  let doc = @canvas.new_canvas(200.0, 200.0)
    .render_rectangle(0.0, 0.0, 200.0, 200.0, @color.white())
    .render_circle(@geometry.Point::new(100.0, 100.0), 40.0, @color.red())
    .render_text("Canvas", @geometry.Point::new(100.0, 50.0), 16.0, @color.black())
  if doc.commands.length() != 11 {
    fail("Should have 11 commands from chained operations")
  }
}
