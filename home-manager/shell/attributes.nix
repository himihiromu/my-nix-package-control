{
  lib,
  shellIntegrationPrograms,
  ...
}:
{
  programs = lib.genAttrs shellIntegrationPrograms (_: {
    enable = true;
  });
}
