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
  version = "0.37.2";

  platformMap = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha256-1SVtfcX0O9oc3b3M2BDSR77LxIhNbJceRlBE46aZnHo=";
    };

    "x86_64-darwin" = {
      suffix = "darwin-x64";
      hash = "sha256-cR1r2RvTzMCF+tUEXgFCsG6gIxVAfRV+L6TlmALwAtc=";
    };

    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha256-GmbZylCRxiDnsulrq7QU3YUH4yTYbTmwEc95ElyovQk=";
    };

    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha256-jWx1UOQojnB9biYRFJ2taxxk1AWBYmWwwCKi1ErB8BM=";
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
