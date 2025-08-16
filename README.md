# Vg — Declarative 2D vector graphics for MoonBit

Vg is a declarative 2D vector graphics library ported from OCaml to MoonBit. Images are values that denote functions mapping points of the cartesian plane to colors and combinators are provided to define and compose them.

This is a MoonBit port of the original [Vg library](https://github.com/dbuenzli/vg) by Daniel Bünzli.

## Features

- Declarative approach to 2D vector graphics
- Functional composition of images
- Multiple rendering backends (SVG, Canvas)
- Comprehensive test suite
- WebAssembly and JavaScript targets

## Installation

```bash
moon install moonbit/vg
```

## Usage

```moonbit
import @moonbit/vg as Vg

// Create a red circle
let circle = Vg.circle(Vg.red(), 50.0)

// Render to SVG
let svg = Vg.render_svg(circle, 100, 100)
```