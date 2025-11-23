// Core types for SVG rendering

///|
/// SVG document structure
pub struct SvgDocument {
  width : Double
  height : Double
  elements : Array[String]
} derive(Show)
