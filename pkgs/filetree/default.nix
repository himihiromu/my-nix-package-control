{ rustPlatform, fetchCrate }:
rustPlatform.buildRustPackage {
  pname = "filetree";
  version = "0.3.5";

  src = fetchCrate {
    pname = "filetree";
    version = "0.3.5";
    sha256 = "sha256-27LsAG15Rr6Gbm/oL+tIeDrU/xa52bbEocPWInx8cl8=";
  };

  cargoHash = "sha256-TZWIa4L70WpvGwTi8DIadKwXEubxn3OciSaWf9UULZA=";
}
