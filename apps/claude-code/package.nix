{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  patchelf,
  makeBinaryWrapper,
  procps,
  ripgrep,
  bubblewrap,
  socat,
}:

let
  version = "2.1.49";

  platformMap = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha256-K5hIFDUO2am3BQa8vBC3faRvWz4GqcaTLwcx0EIEm5g=";
    };

    "x86_64-darwin" = {
      suffix = "darwin-x64";
      hash = "sha256-MVXFoT6PqZdgOKS5VcPsAGqhfCwS2LuKLdMFZmHu7SU=";
    };

    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha256-56dWVmXsvMyixpErLvKdorE30mAgG5Mcc3t904Icbi8=";
    };

    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha256-5OTqip+Lzl+Puq57rHx6GCbqe6aLOLnClR6EZrypEzE=";
    };
  };

  platform =
    platformMap.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platform.suffix}/claude";
    hash = platform.hash;
  };
in
stdenvNoCC.mkDerivation {
  pname = "claude-code";
  inherit version;

  dontUnpack = true;

  nativeBuildInputs = [
    makeBinaryWrapper
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ patchelf ];

  dontAutoPatchelf = true;
  dontPatchELF = true;
  # Critical: stripping corrupts the self-contained Bun trailer
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 ${src} $out/bin/.claude-unwrapped
  ''
  + lib.optionalString stdenvNoCC.hostPlatform.isLinux ''
    patchelf --set-interpreter "$(cat ${stdenv.cc}/nix-support/dynamic-linker)" $out/bin/.claude-unwrapped
  ''
  + ''
    makeBinaryWrapper $out/bin/.claude-unwrapped $out/bin/claude \
      --set DISABLE_AUTOUPDATER 1 \
      --set DISABLE_INSTALLATION_CHECKS 1 \
      --set USE_BUILTIN_RIPGREP 0 \
      --prefix PATH : ${
        lib.makeBinPath (
          [
            procps
            ripgrep
          ]
          ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [
            bubblewrap
            socat
          ]
        )
      }
    runHook postInstall
  '';

  meta = {
    description = "AI coding assistant in your terminal";
    homepage = "https://www.anthropic.com/claude-code";
    license = lib.licenses.unfree;
    platforms = builtins.attrNames platformMap;
    mainProgram = "claude";
  };
}
