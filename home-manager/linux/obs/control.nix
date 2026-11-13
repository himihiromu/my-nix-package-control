{ pkgs }:
let
  python = pkgs.python3.withPackages (ps: [ ps.websockets ]);
in
pkgs.writeShellApplication {
  name = "obs-control";
  runtimeInputs = [ pkgs.libnotify ];
  text = ''
    exec ${python}/bin/python3 ${./control.py} "$@"
  '';
}
