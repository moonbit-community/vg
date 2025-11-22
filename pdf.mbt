// Basic PDF rendering backend

///|
/// PDF document structure
pub struct PdfDocument {
  width : Double
  height : Double
  objects : Array[String]
  object_count : Int
} derive(Show)

///|
/// Create a new PDF document
pub fn PdfDocument::new(width : Double, height : Double) -> PdfDocument {
  { width, height, objects: [], object_count: 0 }
}

///|
/// Convert color to PDF color values (0-1 range)
fn color_to_pdf(c : Color) -> String {
  "\{c.r} \{c.g} \{c.b} rg"
}

///|
/// Convert point to PDF coordinates (flip Y axis)
fn point_to_pdf(p : Point, height : Double) -> String {
  "\{p.x} \{height - p.y}"
}

///|
/// Convert a path to PDF path commands
fn path_to_pdf_commands(path : Path, height : Double) -> Array[String] {
  let commands = Array::new()
  for segment in path.0 {
    match segment {
      MoveTo(p) => commands.push("\{point_to_pdf(p, height)} m")
      LineTo(p) => commands.push("\{point_to_pdf(p, height)} l")
      CurveTo(cp1, cp2, end) =>
        commands.push(
          "\{point_to_pdf(cp1, height)} \{point_to_pdf(cp2, height)} \{point_to_pdf(end, height)} c",
        )
      QCurveTo(cp, end) => {
        // Convert quadratic to cubic Bézier for PDF
        // PDF doesn't support quadratic curves natively
        commands.push("% Quadratic curve converted to cubic")
        commands.push(
          "\{point_to_pdf(cp, height)} \{point_to_pdf(cp, height)} \{point_to_pdf(end, height)} c",
        )
      }
      EArcTo(_, _, _, _, _, end) => {
        // Simplified arc for PDF - just line to end point
        commands.push("% Elliptical arc simplified")
        commands.push("\{point_to_pdf(end, height)} l")
      }
      Close => commands.push("h") // Close path
    }
  }
  commands
}

// ===== OBJECT-ORIENTED API METHODS =====

///|
/// Add an object to the PDF document (OO-style)
fn PdfDocument::add_object(self : PdfDocument, obj : String) -> PdfDocument {
  let new_objects = Array::new()
  for o in self.objects {
    new_objects.push(o)
  }
  new_objects.push(obj)
  {
    width: self.width,
    height: self.height,
    objects: new_objects,
    object_count: self.object_count + 1,
  }
}

///|
/// Render a circle to PDF (OO-style)
pub fn PdfDocument::render_circle(
  self : PdfDocument,
  center : Point,
  radius : Double,
  color : Color,
) -> PdfDocument {
  let kappa = 0.5522847498
  let offset = radius * kappa
  let content = "q\n" + // Save graphics state
    "\{color_to_pdf(color)}\n" +
    "\{point_to_pdf(Point::new(center.x, center.y - radius), self.height)} m\n" + // Move to top
    // Four cubic curves to approximate circle
    "\{point_to_pdf(Point::new(center.x + offset, center.y - radius), self.height)} \{point_to_pdf(Point::new(center.x + radius, center.y - offset), self.height)} \{point_to_pdf(Point::new(center.x + radius, center.y), self.height)} c\n" +
    point_to_pdf(Point::new(center.x + radius, center.y + offset), self.height) +
    " " +
    point_to_pdf(Point::new(center.x + offset, center.y + radius), self.height) +
    " " +
    point_to_pdf(Point::new(center.x, center.y + radius), self.height) +
    " c\n" +
    point_to_pdf(Point::new(center.x - offset, center.y + radius), self.height) +
    " " +
    point_to_pdf(Point::new(center.x - radius, center.y + offset), self.height) +
    " " +
    point_to_pdf(Point::new(center.x - radius, center.y), self.height) +
    " c\n" +
    point_to_pdf(Point::new(center.x - radius, center.y - offset), self.height) +
    " " +
    point_to_pdf(Point::new(center.x - offset, center.y - radius), self.height) +
    " " +
    point_to_pdf(Point::new(center.x, center.y - radius), self.height) +
    " c\n" +
    "f\n" + // Fill
    "Q" // Restore graphics state
  self.add_object(content)
}

///|
/// Render a rectangle to PDF (OO-style)
pub fn PdfDocument::render_rectangle(
  self : PdfDocument,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  color : Color,
) -> PdfDocument {
  let content = "q\n" + // Save graphics state
    color_to_pdf(color) +
    "\n" +
    "\{x} \{self.height - y - height} \{width} \{height} re\n" + // Rectangle
    "f\n" + // Fill
    "Q" // Restore graphics state
  self.add_object(content)
}

///|
/// Render a line to PDF (OO-style)
pub fn PdfDocument::render_line(
  self : PdfDocument,
  start : Point,
  end : Point,
  color : Color,
  thickness : Double,
) -> PdfDocument {
  let content = "q\n" + // Save graphics state
    color_to_pdf(color) +
    " RG\n" + // Stroke color
    thickness.to_string() +
    " w\n" + // Line width
    "1 J\n" + // Round line caps
    point_to_pdf(start, self.height) +
    " m\n" + // Move to start
    point_to_pdf(end, self.height) +
    " l\n" + // Line to end
    "S\n" + // Stroke
    "Q" // Restore graphics state
  self.add_object(content)
}

///|
/// Render text to PDF (OO-style)
pub fn PdfDocument::render_text(
  self : PdfDocument,
  text : String,
  pos : Point,
  size : Double,
  color : Color,
) -> PdfDocument {
  let content = "q\n" + // Save graphics state
    "BT\n" + // Begin text
    "/F1 " +
    size.to_string() +
    " Tf\n" + // Font and size
    color_to_pdf(color) +
    " rg\n" + // Text color
    point_to_pdf(pos, self.height) +
    " Td\n" + // Text position
    "(" +
    text +
    ") Tj\n" + // Show text
    "ET\n" + // End text
    "Q" // Restore graphics state
  self.add_object(content)
}

///|
/// Render a path to PDF (OO-style)
pub fn PdfDocument::render_path(
  self : PdfDocument,
  path : Path,
  color : Color,
) -> PdfDocument {
  let path_commands = path_to_pdf_commands(path, self.height)
  let mut content = "q\n" // Save graphics state
  content = content + color_to_pdf(color) + "\n"
  for cmd in path_commands {
    content = content + cmd + "\n"
  }
  content = content + "f\n" // Fill
  content = content + "Q" // Restore graphics state
  self.add_object(content)
}

///|
/// Convert to PDF string (OO-style)
pub fn PdfDocument::to_string(self : PdfDocument) -> String {
  let mut pdf = "%PDF-1.4\n"

  // PDF Header
  pdf = pdf + "1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n\n"

  // Pages object
  pdf = pdf +
    "2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n\n"

  // Page object
  pdf = pdf + "3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n"
  pdf = pdf +
    "/MediaBox [0 0 " +
    self.width.to_string() +
    " " +
    self.height.to_string() +
    "]\n"
  pdf = pdf +
    "/Resources <<\n/Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >>\n>>\n"
  pdf = pdf + "/Contents 4 0 R\n>>\nendobj\n\n"

  // Content stream
  let mut content_stream = ""
  for obj in self.objects {
    content_stream = content_stream + obj + "\n"
  }
  pdf = pdf +
    "4 0 obj\n<<\n/Length " +
    content_stream.length().to_string() +
    "\n>>\nstream\n"
  pdf = pdf + content_stream
  pdf = pdf + "endstream\nendobj\n\n"

  // Cross-reference table
  pdf = pdf + "xref\n0 5\n"
  pdf = pdf + "0000000000 65535 f \n"
  pdf = pdf + "0000000009 65535 n \n"
  pdf = pdf + "0000000074 65535 n \n"
  pdf = pdf + "0000000120 65535 n \n"
  pdf = pdf + "0000000300 65535 n \n"

  // Trailer
  pdf = pdf + "trailer\n<<\n/Size 5\n/Root 1 0 R\n>>\n"
  pdf = pdf + "startxref\n" + (pdf.length() + 50).to_string() + "\n%%EOF"
  pdf
}
