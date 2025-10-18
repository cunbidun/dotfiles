# Fixing Cache Misses for Flake Inputs

## Problem
When using a flake input's homeManagerModule (or nixosModule), the module may rebuild packages using your system's nixpkgs instead of the input's own nixpkgs. This causes cache misses because the derivation hash differs.

## Root Cause
- With `home-manager.useGlobalPkgs = true`, modules receive your system's `pkgs`
- The module builds its package with your nixpkgs version (e.g., `544961d`)
- The upstream cache has the package built with the input's nixpkgs (e.g., `e9f00bd`)
- Different nixpkgs = different dependencies = different derivation hash = cache miss

## Solution
Override the package to use the input's own flake output:

```nix
services.vicinae = {
  enable = true;
  package = inputs.vicinae.packages.${pkgs.system}.default;
  # ... other config
};
```

This forces the module to use the pre-built package from the input's flake, which matches what's in the cache.
