{ ... }:
let
  shellIntegrationPrograms = import ../install-package/integrations.nix;
in
{
  _module.args = {
    inherit shellIntegrationPrograms;
  };

  imports = [
    ./attributes.nix
    ./bash.nix
    ./fish.nix
    ./nushell.nix
    ./zsh.nix
  ];

  home.shell = {
    enableShellIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;
  };
}
