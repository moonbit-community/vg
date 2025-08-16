fn main {
  println("Vg - Declarative 2D Vector Graphics for MoonBit")
  println("==============================================")
  
  // Create a complex scene
  let background = @lib.rectangle(@lib.gray(0.95), 400.0, 300.0)
  
  // Create some shapes
  let red_circle = @lib.circle(@lib.red(), 50.0)
  let blue_rect = @lib.translate_image(100.0, 0.0, @lib.rectangle(@lib.blue(), 60.0, 40.0))
  let green_ellipse = @lib.translate_image(-80.0, 60.0, @lib.circle(@lib.green(), 30.0))
  
  // Create a gradient
  let gradient = @lib.linear_gradient(
    @lib.yellow(), 
    @lib.magenta(), 
    @lib.point(-100.0, -50.0), 
    @lib.point(100.0, 50.0)
  )
  let gradient_rect = @lib.cut(@lib.rectangle(@lib.white(), 80.0, 60.0), gradient)
  let positioned_gradient = @lib.translate_image(0.0, -80.0, gradient_rect)
  
  // Compose the scene
  let scene = background
    |> @lib.compose_images(red_circle)
    |> @lib.compose_images(blue_rect)
    |> @lib.compose_images(green_ellipse)
    |> @lib.compose_images(positioned_gradient)
  
  // Render to SVG
  let svg_output = @lib.render_image_to_svg(scene, 400.0, 300.0, 100)
  
  println("\nGenerated SVG:")
  println("==============")
  println(svg_output)
  
  // Also demonstrate path creation
  println("\n\nPath Example:")
  println("=============")
  
  let star_path = @lib.empty_path()
    |> @lib.move_to(@lib.point(0.0, -30.0))
    |> @lib.line_to(@lib.point(10.0, -10.0))
    |> @lib.line_to(@lib.point(30.0, -10.0))
    |> @lib.line_to(@lib.point(15.0, 5.0))
    |> @lib.line_to(@lib.point(20.0, 25.0))
    |> @lib.line_to(@lib.point(0.0, 15.0))
    |> @lib.line_to(@lib.point(-20.0, 25.0))
    |> @lib.line_to(@lib.point(-15.0, 5.0))
    |> @lib.line_to(@lib.point(-30.0, -10.0))
    |> @lib.line_to(@lib.point(-10.0, -10.0))
    |> @lib.close_path()
  
  let star_svg = @lib.new_svg(100.0, 100.0)
    |> @lib.render_path(star_path, @lib.gold())
  
  println(@lib.to_svg_string(star_svg))
  
  println("\nLibrary demonstration complete!")
}
