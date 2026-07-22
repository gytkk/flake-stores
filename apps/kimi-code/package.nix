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
  version = "0.29.0";

  platformMap = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha256-+m12U8bKdhLJnQyptHE+7ogJ7ahhXNdiHRb69QYn8PU=";
    };

    "x86_64-darwin" = {
      suffix = "darwin-x64";
      hash = "sha256-vs0xpCYf2MUHZr1E2bfO/5rpxtIHzVD5vKMvJ9wD/Qg=";
    };

    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha256-uyULVBEbB1sDKXybLmZ9hSRczXaMzmoboEUn/RPYQgA=";
    };

    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha256-Fqy3HW88H1CkrCqRXAtMGnlcBke0XXqwYeMvhpHYyRE=";
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
