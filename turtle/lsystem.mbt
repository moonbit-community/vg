// Deterministic L-systems: rewrite an axiom by per-symbol production rules.

///|
/// A deterministic, context-free L-system.
pub struct LSystem {
  axiom : String
  rules : Map[Char, String]
}

///|
/// Create an L-system from an `axiom` and a list of single-symbol production
/// `rules`. Symbols without a rule are left unchanged when expanding.
pub fn LSystem::new(axiom : String, rules : Array[(Char, String)]) -> LSystem {
  { axiom, rules: Map::from_array(rules) }
}

///|
/// Expand the axiom by applying the production rules `iterations` times.
pub fn LSystem::expand(self : LSystem, iterations : Int) -> String {
  let mut s = self.axiom
  for _ in 0..<iterations {
    s = [
      for ch in s => {
        match self.rules.get(ch) {
          Some(replacement) => replacement
          None => ch.to_string()
        }
      }
    ].join("")
  }
  s
}
