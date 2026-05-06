{ lib, config, ... }: {
    options.programs.pinentry-dropdown = {
        enable = lib.mkEnableOption "all of the below options";

        integrations.niridrop = lib.mkEnableOption "usage of the niridrop module to register the getpin-ui dropdown";

        show = lib.mkOption {
            description = "bash script that will show the getpin-ui (cfg/getpin/show.sh)";
            type = lib.types.str;
            default = "";
            example = "pypr show getpin-ui";
        };

        hide = lib.mkOption {
            description = "bash script that will hide the getpin-ui (cfg/getpin/hide.sh)";
            type = lib.types.str;
            default = "";
            example = "pypr hide getpin-ui";
        };

        showhide = lib.mkOption {
            description = "set up show/hide scripts using the premade scripts for this dropdown program";
            type = lib.types.enum [ "" "niridrop" ];
            default = "";
            example = "niridrop";
        };
    };

    config = let
        cfg = config.programs.pinentry-dropdown;
    in lib.mkIf cfg.enable
    (lib.mkMerge [
        {
            xdg.configFile."getpin/show.sh".text = cfg.show;
            xdg.configFile."getpin/hide.sh".text = cfg.hide;
        }

        (lib.mkIf cfg.integrations.niridrop {
            programs.niri.niridrop.windows.getpin-ui = {
                app_id = "getpin-ui";
                cmd = "${config.home.sessionVariables.TERMINAL} --class getpin-ui getpin-ui";
                lazy = false;
                size = [ 0.3 0.16 ];
            };
        })

        (lib.mkIf (cfg.showhide == "niridrop") {
            programs.pinentry-dropdown.show = "niridrop --show --forget getpin-ui";
            programs.pinentry-dropdown.hide = "niridrop --hide --forget getpin-ui";
        })
    ]);
}

