// SVG rendering backend - Re-exports from svg package

// Re-export SVG types and functions
pub type SvgDocument = @svg.SvgDocument
pub let new_svg : (Double, Double) -> SvgDocument = @svg.new_svg
