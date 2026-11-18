let
  validate = import ../lib/validate-options.nix;
  good = import ./fixtures/local-options.nix;
  succeeds = value: (builtins.tryEval (builtins.deepSeq (validate value) true)).success;
in
assert succeeds good;
assert succeeds (good // { isDesktop = true; system = "aarch64-darwin"; });
assert !(succeeds null);
assert !(succeeds { isDesktop = false; });
assert !(succeeds (good // { username = ""; }));
assert !(succeeds (good // { username = "  "; }));
assert !(succeeds (good // { username = 1; }));
assert !(succeeds (good // { isDesktop = "true"; }));
assert !(succeeds (good // { system = "invalid"; }));
true
