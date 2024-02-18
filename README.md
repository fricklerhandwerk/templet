# `templet`

Templates, from Nix, for Nix.
Using [npins](https://github.com/andir/npins), because that works.

## What it does

`templet shell` creates a very simple `default.nix` and an accompanying `shell.nix`, where dependencies are pinned with `npins`.
It takes initial packages to include from the command line, and always adds `npins` for convience.

## How to use it

Create an environment with packages from Nixpkgs in the current directory:

```
templet shell --packages cowsay lolcat -- --branch nixpkgs-23.11
```

This will produce the following files:

```
.
├── default.nix       # Nix project with pinned sources and shell
├── npins             # `npins` source references
└── shell.nix         # Wrapper for `nix-shell`
```

```nix
# default.nix
{
  sources ? import ./npins,
  system ? builtins.currentSystem,
}:
let
  shell = pkgs.mkShell {
    packages = with pkgs; [
      cowsay
      lolcat
      npins
    ];
  };
  pkgs = import sources.nixpkgs {
    inherit system;
    config = { };
    overlays = [ ];
  };
in
{
  inherit shell;
}
```

```nix
# shell.nix
{
  sources ? import ./npins,
  system ? builtins.currentSystem,
}:
(import ./. { inherit sources system; }).shell
```

## How it works

`templet` builds the initial files as a Nix derivation, copies them to the current directory, and runs `npins` to fetch the desired version of Nixpkgs (default: `nixpkgs-unstable`).

From there, modify `default.nix` and manage remote sources with `npins` as usual.

## Why it exists

Nix is very flexible, configurations are code.
This is great, because everything can be customised without compromise.

But I'm tired of creating new Nix environments by hand.
Especially since a few patterns emerged that I keep coming back to.

This is an attempt to codify ideas that work well and scale.
