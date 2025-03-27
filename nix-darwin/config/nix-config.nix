{ pkgs, ... }:
{
  nix = {
    enable = false;
    nrBuildUsers = 350;
    optimise.automatic = false;
    settings = {
      experimental-features = "nix-command flakes";
      max-jobs = 8;
    };
  };
}
