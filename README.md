# pinentry-niridrop

A simple pinentry program that uses a dropdown terminal as its ui (with the help of [niridrop](https://github.com/lifantsev/niridrop)). If possible, it prefers showing its ui inside a terminal, otherwise it uses the dropdown ui.

TODO add a video

Maybe will add config to let non-niridrop users use this (TODO).

## Installation

This program has three components:
- pinentry-niridrop: the pinentry server gpg can interface with
- getpin: a utility that shows a ui to get the user's pin
- getpin-ui: the ui of said utility (should be running in a [niridrop](https://github.com/lifantsev/niridrop) dropdown terminal)

### flake
``` nix
# add the flake input
# flake.nix
inputs.pinentry-niridrop.url = "github:lifantsev/pinentry-niridrop";

# install the 3 packages
# configuration.nix
imports = [ inputs.pinentry-niridrop.nixosModules.default ];

# if you use the `niridrop` module, add this to register the required `getpin-ui` dropdown window
# home.nix
imports = [ inputs.pinentry-niridrop.homeManagerModules.default ];

programs.pinentry-niridrop.enable = true;
```

### other
If you don't use nix, you may download the [scripts](https://github.com/lifantsev/pinentry-niridrop/tree/main/src), add shebangs, and install them however you usually do. The scripts optionally depend on [lg](https://github.com/lifantsev/lg), if you don't have it installed, just remove the lines that refer to `lg` with `sed -i '/ *lg / d' <script.sh>`. Make sure that `niridrop` is installed and that you have added `getpin-ui` as a dropdown window in its config.

## Usage

To use this script as your default pinentry:
``` nix
# home.nix
services.gpg-agent.pinentry.package = pkgs.pinentry-niridrop;
```

### getpin

TODO

### getpin-ui

TODO
