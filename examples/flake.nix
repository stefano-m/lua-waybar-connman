{
  description = "Example flake that consumes the waybar_connman module";

  inputs = {
    waybar-connman-module.url = "github:stefano-m/lua-waybar-connman/main";
    waybar-connman-module.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, home-common, waybar-connman-module }@inputs:
    let
      system = "x86_64-linux";
      username = "theUser";
      flakePkgs = import nixpkgs {
        inherit system;
        overlays = [ waybar-connman-module.overlays.default ];
      };
    in
    {
      homeConfigurations = {
        ${username} = home-manager.lib.homeManagerConfiguration {
          modules = [
            ./home.nix
            {
              home = {
                inherit username;
                homeDirectory = "/home/${username}";
              };
            }
          ] ++ builtins.attrValues home-common.nixosModules;
          extraSpecialArgs = {
            flakeInputs = inputs;
          };
          pkgs = flakePkgs;
        };
      };
    };
}
