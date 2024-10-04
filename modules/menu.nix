{
  config,
  lib,
  flake-parts-lib,
  ...
}: let
  inherit (flake-parts-lib) mkPerSystemOption;
  packageName = package: package.pname or package.python.pname or package.name;

  packageVersion = package: package.version or package.python.version or "";
  packageVersionString = package: let
    version = packageVersion package;
  in
    if version != ""
    then "(${version})"
    else "";
  packageInfo = package: ''table.add_row("${packageName package}", "${packageVersion package}", "${package.meta.description or package.description or "--"}")'';

  enabledPreCommitHooks = preCommitHooks: lib.attrsets.filterAttrs (n: v: v.enable) preCommitHooks;

  precommitInfo = _: v: ''table.add_row("${v.name}", "${v.description}")'';
in {
  options.perSystem = mkPerSystemOption ({
    config,
    pkgs,
    ...
  }: let
    cfg = config.devenv-menu;
  in {
    options = {
      devenv.shells = lib.mkOption {
        type = lib.types.lazyAttrsOf (lib.types.submoduleWith {
          modules = [
            ({
              config,
              options,
              name,
              ...
            }: {
              options = {
                menu = {
                  enable = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                    description = ''
                      Enable displaying a menu upon entering a devenv shell.
                    '';
                  };
                  header = lib.mkOption {
                    type = lib.types.str;
                    default = "# 🚀 ⚡️ Welcome to ${config.name} ❄ 🐍";
                    description = ''
                      The header line of the menu.
                    '';
                  };
                  description = lib.mkOption {
                    type = lib.types.lines;
                    default = ''
                      This shell is built on [devenv.sh](https://devenv.sh/) which is powered by  [Nix ❄ 😍](https://nixos.org/).

                      **Workflow**

                        - ❄ Declarativeley manage system dependencies (and more) in [.nix/flake.nix](.nix/flake.nix)\
                          &rarr; Check [devenv options](https://devenv.sh/reference/options/) and set them under [devenv.shells.${name}](.nix/flake.nix)
                        - 🐍 Install and manage python dependencies with [uv 🚀](https://github.com/astral-sh/uv) (uv add + uv sync)
                        - [direnv](https://github.com/direnv/direnv) automatically updates your environment whenever .nix or uv.lock change
                    '';
                    description = ''
                      Markdown description of the development environment printed after the header.
                    '';
                  };
                  showPreCommitHooks = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                    description = ''
                      Print all pre-commit hooks enabled through devenv.shells.<name>.pre-commit
                    '';
                  };
                  showInstalledPackages = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                    description = ''
                      Print all packages explicitly installed through devenv.shells.<name>.packages
                    '';
                  };
                  show = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                    description = ''
                      Print menu to terminal.
                    '';
                  };
                  linkReadmeToRoot = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                    description = ''
                      Link the description of the shell to the repository root as a markdown file (for convenience).
                    '';
                  };

                  markdown = lib.mkOption {
                    type = lib.types.path;
                    readOnly = true;
                    default = pkgs.writeText "menu.md" ''
                      ${config.menu.description}
                    '';
                  };
                  show-cmd = lib.mkOption {
                    type = lib.types.package;
                    default = let
                      precommitHooksTable = preCommitHooks: ''
                        from rich.table import Table
                        import rich.box as box

                        table = Table(title="", box=box.MINIMAL_HEAVY_HEAD)
                        table.add_column("Hook")
                        table.add_column("Description")
                        ${lib.concatStringsSep "\n" (lib.mapAttrsToList precommitInfo (enabledPreCommitHooks preCommitHooks))}
                        console.print(Panel(table, title="Enabled Pre-commit Hooks", subtitle="[link]${config.devenv.root}/.nix/flake.nix[/link]: [bold italic]devenv.shells.${name}.pre-commit.hooks[/bold italic]", expand=True))'';
                      packageTable = packages: ''
                        from rich.table import Table
                        import rich.box as box

                        table = Table(title="", box=box.MINIMAL_HEAVY_HEAD)
                        table.add_column("Package")
                        table.add_column("Version")
                        table.add_column("Description")
                        ${lib.concatStringsSep "\n" (lib.unique (map packageInfo packages))}
                        console.print(Panel(table, title="Installed Packages", subtitle="[link]${config.devenv.root}/.nix/flake.nix[/link]: [bold italic]devenv.shells.${name}.packages[/bold italic]", expand=True))'';
                    in
                      pkgs.writers.writePython3Bin "show-menu" {
                        libraries = [pkgs.python3Packages.rich];
                        flakeIgnore = ["E501" "E402" "E121" "W391"];
                      } ''
                        from rich.console import Console
                        from rich.markdown import Markdown
                        from rich.panel import Panel
                        console = Console()

                        console.print(Markdown("${config.menu.header}"))
                        with open("${config.menu.markdown}") as menu:
                            raw_markdown = menu.read()
                            markdown = Markdown(raw_markdown)
                        console.print(Panel(markdown, title="README", expand=True))
                        ${lib.optionalString config.menu.showInstalledPackages (packageTable config.packages)}
                        ${lib.optionalString config.menu.showPreCommitHooks (precommitHooksTable config.pre-commit.hooks)}
                      '';
                    description = ''
                      The program showing the menu.
                    '';
                  };
                };
              };
              config = lib.mkIf config.menu.enable {
                enterShell = lib.concatStringsSep "\n" [(lib.optionalString config.menu.show "${config.menu.show-cmd}/bin/show-menu") (lib.optionalString config.menu.linkReadmeToRoot "ln -sf ${config.menu.markdown} _README.md")];
              };
            })
          ];
          shorthandOnlyDefinesConfig = false;
        });
      };
    };
  });
}
