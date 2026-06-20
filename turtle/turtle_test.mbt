// Unit test for L-system rewriting (rendering demos live in README.mbt.md).

///|
test "lsystem: koch curve rewriting" {
  let koch = @turtle.LSystem::new("F", [('F', "F+F-F-F+F")])
  inspect(koch.expand(0), content="F")
  inspect(koch.expand(1), content="F+F-F-F+F")
}
