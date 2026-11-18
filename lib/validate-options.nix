# local-options is data, never an environment/secret lookup.
options:
let
  fail = detail: throw ("local-options: " + detail + " Specify --override-input local-options path:/path/to/default.nix (see README.md).");
  systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
in
if !builtins.isAttrs options then fail "Expected an attribute set."
else if !(options ? username) || !builtins.isString options.username || builtins.match "[[:space:]]*" options.username != null then fail "username must be a non-empty string."
else if !(options ? isDesktop) || !builtins.isBool options.isDesktop then fail "isDesktop must be a boolean."
else if options ? system && !(builtins.elem options.system systems) then fail "system must be a supported Linux/Darwin system."
else options
