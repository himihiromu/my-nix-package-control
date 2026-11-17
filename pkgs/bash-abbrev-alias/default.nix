{
  stdenvNoCC,
  fetchFromGitHub,
  bash,
  lib,
}:
stdenvNoCC.mkDerivation {
  pname = "bash-abbrev-alias";
  version = "0.1.0-unstable-2020-05-15";

  src = fetchFromGitHub {
    owner = "momo-lab";
    repo = "bash-abbrev-alias";
    rev = "6afb671fc95b3c559f2665637df65d9060f4d320";
    hash = "sha256-bvbMyniy5TGoU0hVGKV2bo+qf6fAfMjlJQ1/DYw5RKo=";
  };

  dontBuild = true;
  doCheck = true;
  checkPhase = ''
    runHook preCheck
    ${bash}/bin/bash -n abbrev-alias.plugin.bash
    runHook postCheck
  '';
  installPhase = ''
    runHook preInstall
    install -Dm644 abbrev-alias.plugin.bash \
      $out/share/bash-abbrev-alias/abbrev-alias.plugin.bash
    install -Dm644 LICENSE $out/share/licenses/bash-abbrev-alias/LICENSE
    runHook postInstall
  '';

  meta = {
    description = "Abbreviation expansion for Bash";
    homepage = "https://github.com/momo-lab/bash-abbrev-alias";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
