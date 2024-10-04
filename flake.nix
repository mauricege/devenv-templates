{
  description = "A collection of personal flake templates built in devenv.";
  outputs = inputs @ {self, ...}: {
    # Put your original flake attributes here.
    templates = {
      dl-python = {
        path = ./templates/dl-python;
        description = "Contains assortment of deep learning packages. Uses uv for dependency management and installs into local virtual env. Pip is supported.";
      };
      minimal-python = {
        path = ./templates/minimal-python;
        description = "Only contains python and uv. Uses uv for dependency management and installs into local virtual env. Pip is supported.";
      };
    };

    defaultTemplate = self.templates.minimal-python;
    flakeModules = rec {
      devenv-menu = import ./modules/menu.nix;
      default = devenv-menu;
    };
  };
}
