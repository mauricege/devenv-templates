{
  description = "Description for the project";

  inputs = {
    devenv-root = {
      url = "file+file:///dev/null";
      flake = false;
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
    nixpkgs-python = {
      url = "github:cachix/nixpkgs-python";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devenv-templates.url = "github:mauricege/devenv-templates";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = inputs @ {
    flake-parts,
    devenv-root,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.devenv.flakeModule
        inputs.devenv-templates.flakeModules.devenv-menu
      ];
      systems = ["x86_64-linux" "i686-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.

        # needed for devenv up
        packages.devenv-up = self'.devShells.default.config.procfileScript;

        # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;
        formatter = pkgs.alejandra;

        devenv.shells.default = {
          # removes need for impure
          devenv.root = let
            devenvRootFileContent = builtins.readFile devenv-root.outPath;
          in
            pkgs.lib.mkIf (devenvRootFileContent != "") devenvRootFileContent;
          name = "minimal-python";

          menu = {
            enable = true;
            showInstalledPackages = true;
            showPreCommitHooks = true;
            linkReadmeToRoot = true;
          };

          # enterShell = ''
          #   echo Hello
          # '';

          imports = [
            # This is just like the imports in devenv.nix.
            # See https://devenv.sh/guides/using-with-flake-parts/#import-a-devenv-module
            # ./devenv-foo.nix
          ];

          # https://devenv.sh/reference/options/
          packages = with pkgs; [
            git
            cowsay
          ];
          languages.python = {
            enable = true;
            venv.enable = true;
            uv = {
              package = inputs'.unstable.legacyPackages.uv;
              enable = true;
              sync.enable = true;
            };
            manylinux.enable = false;
            version = "3.11";

            libraries = with pkgs; [
              zlib
            ];
          };
          # See https://devenv.sh/reference/options/#pre-commithooks for options
          pre-commit.hooks = {
            alejandra.enable = true; # nix formatter
            ruff.enable = true;
            ruff-format.enable = true;
          };
          scripts = {
            reinstall-venv = {
              exec = "rm -rf $DEVENV_ROOT/.venv $DEVENV_ROOT/.direnv $DEVENV_ROOT/.devenv && direnv reload";
              description = "Wipe any state that might have accumulated - useful for reinstalling python dependencies.";
            };
          };
        };
      };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
      };
    };
}
