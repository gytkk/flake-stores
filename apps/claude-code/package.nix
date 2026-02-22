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
  version = "2.1.50";

  platformMap = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha256-S2wcteAkKNv2ANCPiMKPnqBmGQAcPv6/iJA2Xlt50bc=";
    };

    "x86_64-darwin" = {
      suffix = "darwin-x64";
      hash = "sha256-IhWBjG4qT6BJfuiKGfjYS5HwuynMQVCjCqd191uiEzw=";
    };

    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha256-dAQnORl8WKR5HB9nQUwNiVZjnsLy6TUoCHK4PUMXvng=";
    };

    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha256-Tisj2/L5eRjV7cla4d4D0jCma5TV+jGlfMZzdC7GriI=";
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
