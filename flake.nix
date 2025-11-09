{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    lua-connman_dbus.url = "github:stefano-m/lua-connman_dbus/master";
    lua-connman_dbus.inputs.nixpkgs.follows = "nixpkgs";

  };

  outputs = { self, nixpkgs, lua-connman_dbus }:
    let

      flakePkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ self.overlays.default ];
      };

      currentVersion = "0.1";

      buildPackage = pname: luaPackages: with luaPackages;
        let
          derivationData = rec {
            name = "${pname}-${version}";
            inherit pname;
            version = "${currentVersion}-${self.shortRev or "dev"}";

            src = ./.;

            propagatedBuildInputs = [ lua lgi cjson connman_dbus flakePkgs.glib ];

            nativeBuildInputs = [
              flakePkgs.makeWrapper
            ];

            buildPhase = ":";

            installPhase = with flakePkgs; ''
              mkdir -p "$out/share/lua/${lua.luaversion}"
              cp -r src/${pname}.lua $out/share/lua/${lua.luaversion}/
              chmod +x $out/share/lua/${lua.luaversion}/${pname}.lua

              mkdir -p $out/bin
              makeWrapper $out/share/lua/${lua.luaversion}/${pname}.lua $out/bin/${pname} \
                  --set-default LUA_PATH ";;" \
                  --suffix LUA_PATH ';' "$LUA_PATH" \
                  --set-default LUA_CPATH ";;" \
                  --suffix LUA_CPATH ';' "$LUA_CPATH" \
                  --set-default GI_TYPELIB_PATH : \
                  --suffix GI_TYPELIB_PATH : ${lib.getLib glib}/lib/girepository-1.0
            '';

            doCheck = false;
            checkPhase = ":";
          };

          derivationData' = derivationData // {
            passthru.tests = buildLuaPackage (derivationData // {
              # Doing this so the luackeck dependencies don't end up in the
              # clousre and included in the wrapped script.
              buildInputs = [ luacheck ];
              doCheck = true;
              checkPhase = "luacheck src";
            });
          };

        in
        buildLuaPackage derivationData';

    in
    {
      packages.x86_64-linux = rec {
        default = lua_waybar_connman;
        lua_waybar_connman = buildPackage "waybar_connman" flakePkgs.luaPackages;
        lua52_waybar_connman = buildPackage "waybar_connman" flakePkgs.lua52Packages;
        lua53_waybar_connman = buildPackage "waybar_connman" flakePkgs.lua53Packages;
        luajit_waybar_connman = buildPackage "waybar_connman" flakePkgs.luajitPackages;
      };

      overlays.default = final: prev:
        let
          thisOverlay = final: prev: with self.packages.x86_64-linux; {
            # NOTE: lua = prev.lua.override { packageOverrides = this: other: {... }}
            # Seems to be broken as it does not allow to combine different overlays.

            luaPackages = prev.luaPackages // {
              waybar_connman = lua_waybar_connman;
            };

            lua52Packages = prev.lua52Packages // {
              waybar_connman = lua52_waybar_connman;
            };

            lua53Packages = prev.lua53Packages // {
              waybar_connman = lua53_waybar_connman;
            };

            luajitPackages = prev.luajitPackages // {
              waybar_connman = luajit_waybar_connman;
            };

          };
        in
        # expose the other lua overlays together with this one.
        (nixpkgs.lib.composeManyExtensions [ thisOverlay lua-connman_dbus.overlays.default ]) final prev;


      devShells.x86_64-linux.default = flakePkgs.mkShell {
        LUA_PATH = "./src/?.lua;./src/?/init.lua";

        buildInputs = (with self.packages.x86_64-linux.lua53_waybar_connman; buildInputs ++ propagatedBuildInputs) ++ (with flakePkgs; [
          nixpkgs-fmt
          luarocks
        ]);
      };
    };
}
