{
  rustPlatform,
  fetchCrate,
  pkg-config,
  openssl,
  zlib,
  libssh2,
}:
rustPlatform.buildRustPackage {
  pname = "keifu";
  version = "0.1.5";

  src = fetchCrate {
    pname = "keifu";
    version = "0.1.5";
    sha256 = "sha256-fo0c68H65/6GqOCQrkAEHvVssBL5n7ZL/XVcm4VIijo=";
  };

  cargoHash = "sha256-AyyLl9ZLMMikaeDvJhFXwAWgivi89gOqz52eyJZQTXQ=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    openssl
    zlib
    libssh2
  ];

  # libgit2-sys 0.17 は libgit2 1.8 系が必要なため、同梱版を使う。
  # cargoSetupHook が設定する値を configure 後に上書きする。
  preBuild = ''
    export LIBGIT2_NO_VENDOR=0
  '';

  env = {
    OPENSSL_NO_VENDOR = "1";
    OPENSSL_DIR = "${openssl.dev}";
    OPENSSL_LIB_DIR = "${openssl.out}/lib";
    OPENSSL_INCLUDE_DIR = "${openssl.dev}/include";
  };
}
