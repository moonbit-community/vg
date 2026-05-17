# Promotion validation report

## Command

```sh
moon test --target all
```

## Relevant output

```text
[bobzhang/vg] test README.mbt.md:400 ("spirograph") failed
expect test failed at README.mbt.md:445
```

The remaining failure is the `__snapshot__/spirograph.svg` snapshot. Updating
the native snapshot with:

```sh
moon test --target native --update
```

passes native, but `moon test --target all` still reports the same SVG snapshot
as different on another target.

## Analysis

The spirograph snapshot serializes a very large floating-point SVG path. The
remaining failure appears to be cross-target floating-point serialization drift
for the generated SVG path, not a MoonBit type-checking error. Other test
snapshot updates produced by `moon test --update` were kept because they reflect
current debug output formatting.
