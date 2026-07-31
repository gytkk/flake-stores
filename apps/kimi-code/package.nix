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
  version = "0.31.1";

  platformMap = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha256-9r1Be6u85ttiIkF0UYCAEeMYt6gOXQ+1NZIWeHQ3ZwQ=";
    };

    "x86_64-darwin" = {
      suffix = "darwin-x64";
      hash = "sha256-OlUNpAzHJ3Sld/x0bpgZO+Ba6TIqCaa8Uk81QvmpJpI=";
    };

    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha256-2njpSLACqNgH6uirfLVRg48zAyHRR/N2t8exh8DTHj8=";
    };

    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha256-RNGcEyT2CaksHm0NwH1sV+Wie9T4xn0xw4oPfFl+upE=";
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
