{
    description = "pinentry program using a niridrop dropdown terminal as ui";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

        lg.url = "github:lifantsev/lg";
        lg.inputs.nixpkgs.follows = "nixpkgs";

        niridrop.url = "github:lifantsev/niridrop";
        niridrop.inputs.lg.follows = "lg";
        niridrop.inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs = { self, nixpkgs, ... }@args: {
        packages = nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ] (system: {
            default   = import ./src/pinentry-niridrop.nix args system;
            getpin    = import ./src/getpin.nix            args system;
            getpin-ui = import ./src/getpin-ui.nix         args system;
        });

        nixosModules.default = { pkgs, ... }: {
            nixpkgs.overlays = [(final: prev: {
                pinentry-niridrop = self.packages.${final.system}.default;
                getpin            = self.packages.${final.system}.getpin;
                getpin-ui         = self.packages.${final.system}.getpin-ui;
            })];

            environment.systemPackages = with pkgs; [ pinentry-niridrop getpin getpin-ui ];
        };
    };
}
