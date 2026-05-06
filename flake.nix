{
    description = "pinentry program using a dropdown terminal as ui";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

        lg.url = "github:lifantsev/lg";
        lg.inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs = { self, nixpkgs, ... }@args: {
        packages = nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ] (system: {
            default   = import ./src/pinentry-dropdown.nix args system;
            getpin    = import ./src/getpin.nix            args system;
            getpin-ui = import ./src/getpin-ui.nix         args system;
        });

        homeManagerModules.default = hmargs: import ./homemodule.nix hmargs;

        nixosModules.default = { pkgs, ... }: {
            nixpkgs.overlays = [(final: prev: {
                pinentry-dropdown = self.packages.${final.system}.default;
                getpin            = self.packages.${final.system}.getpin;
                getpin-ui         = self.packages.${final.system}.getpin-ui;
            })];

            environment.systemPackages = with pkgs; [ pinentry-dropdown getpin getpin-ui ];
        };
    };
}
