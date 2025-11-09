# Connman Waybar Custom Module

A custom module that can be used with Waybar to display the status of your
network connections from Connman.

## Notice

This module is developed in my spare time, is maintained on a best-effort basis
and updated so that it "Works for me"™.

## Usage

A nix flake is provided to install the script with all its dependencies. For
example, it can be integrated with home-manager.

You can run the script directly with

``` shell
lua waybar_connman.lua run
```

or the wrapper script provided by the nix flake with

```shell
waybar_connman run
```

See also the examples in the `examples` directory.

## Nix flake

Build with

``` shell
nix build '.#default'
```

and test with

``` shell
nix build '.#default.passthru.tests'
```

Attributes for Lua 5.2 (default), Lua 5.3 an LuaJit are provided.

## Dependencies

- GLib
- Lua >= 5.2
- cjson
- lgi
- connman_dbus


