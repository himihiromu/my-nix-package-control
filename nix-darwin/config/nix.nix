{ pkgs, ... }:
{
  nix = {
    optimise.automatic = true;
    settings = {
      experimental-features = "nix-command flakes";
      max-jobs = 8;
    };
    services.nix-daemon.enable = true;
    nix.package = pkgs.nix;
  };
}
