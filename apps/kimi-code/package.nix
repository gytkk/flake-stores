{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  unzip,
  fd,
  ripgrep,
}:

let
  version = "0.28.0";

  platformMap = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha256-VV6RYOA0uLUjpliIOXA26VA5nmbCRBVSDQXWHSVtl8w=";
    };

    "x86_64-darwin" = {
      suffix = "darwin-x64";
      hash = "sha256-Hbib2ivzjCSaYbTj20/cSYH9G4bwV7dWGB1v1ZCv5kk=";
    };

    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha256-Zf58vs0tJpcVW3zfQjOJz2S/dkQf1+/Fa2IaWsmJLOo=";
    };

    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha256-rxi2liKuoAt7IODVGEmYjHIU1zbPAvxPWY1r/y+yANk=";
    };
  };

  platform =
    platformMap.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  src = fetchurl {
    url = "https://github.com/MoonshotAI/kimi-code/releases/download/%40moonshot-ai/kimi-code%40${version}/kimi-code-${platform.suffix}.zip";
    inherit (platform) hash;
  };

  runtimePath = lib.makeBinPath [
    fd
    ripgrep
  ];
in
stdenvNoCC.mkDerivation {
  pname = "kimi-code";
  inherit version src;

  dontUnpack = true;

  nativeBuildInputs = [
    makeWrapper
    unzip
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [
    stdenv.cc.cc.lib
  ];

  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    unzip -p ${src} kimi > $out/bin/kimi
    chmod +x $out/bin/kimi
    wrapProgram $out/bin/kimi \
      --set KIMI_CODE_NO_AUTO_UPDATE 1 \
      --prefix PATH : "${runtimePath}"
    runHook postInstall
  '';

  meta = {
    description = "Kimi Code CLI";
    homepage = "https://github.com/MoonshotAI/kimi-code";
    license = lib.licenses.mit;
    platforms = builtins.attrNames platformMap;
    mainProgram = "kimi";
  };
}
