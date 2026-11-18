{ pkgs }:
rec {
  default = zai;
  zai = import ./zai.nix { inherit pkgs; };
  python = pkgs.mkShell {
    buildInputs = [
      pkgs.python314
      pkgs.uv
    ];
    shellHook = ''
      echo "uv version: $(uv --version)"
      echo "python version: $(python --version)"
    '';
  };
  js = pkgs.mkShell {
    buildInputs = [
      pkgs.nodejs_24
      pkgs.pnpm
      pkgs.bun
      pkgs.yarn
      pkgs.typescript-language-server
      pkgs.typescript
    ];
    shellHook = ''
      echo "node version: $(node --version)"
      echo "npm version: $(npm --version)"
      echo "pnpm version: $(pnpm --version)"
      echo "bun version: $(bun --version)"
      echo "yarn version: $(yarn --version)"
    '';
  };
  java21 = pkgs.mkShell {
    buildInputs = [
      pkgs.gradle_9
      pkgs.maven
      pkgs.javaPackages.compiler.semeru-bin.jdk-21
    ];
    shellHook = ''
      echo "gradle version: $(gradle --version)"
      echo "maven version: $(maven --version)"
      echo "java version: $(java --version)"
      echo "javac version: $(javac --version)"
    '';
  };
  java8 = pkgs.mkShell {
    buildInputs = [
      pkgs.gradle_9
      pkgs.maven
      pkgs.javaPackages.compiler.semeru-bin.jdk-8
    ];
    shellHook = ''
      echo "gradle version: $(gradle --version)"
      echo "maven version: $(maven --version)"
      echo "java version: $(java --version)"
      echo "javac version: $(javac --version)"
    '';
  };
  go = pkgs.mkShell {
    buildInputs = [
      pkgs.go
      pkgs.gotools
      pkgs.golangci-lint
    ];
    shellHook = ''
      echo "go version: $(go version)"
      echo "golangci-lint version: $(golangci-lint --version)"
      echo $GOPATH
    '';
  };
  kotlin = pkgs.mkShell {
    buildInputs = [
      pkgs.kotlin
      pkgs.gradle_9
      pkgs.maven
      pkgs.javaPackages.compiler.semeru-bin.jdk-21
    ];
    shellHook = ''
      echo "gradle version: $(gradle --version)"
      echo "maven version: $(mvn -v)"
      echo "java version: $(java --version)"
      echo "javac version: $(javac --version)"
      echo "kotlin version: $(kotlin -version)"
    '';
  };
  csharp = pkgs.mkShell {
    buildInputs = [
      pkgs.dotnet-sdk
      pkgs.omnisharp-roslyn
      # pkgs.dotnet-aspnetcore  # Web開発時に追加
    ];
    shellHook = ''
      echo "dotnet version: $(dotnet --version)"
      echo "OmniSharp version: $(omnisharp --version)"
    '';
  };
}
