{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  libcap,
  openssl,
  zlib,
}:

let
  version = "0.117.0";

  platformMap = {
    "aarch64-darwin" = {
      target = "aarch64-apple-darwin";
      hash = "sha256-HoL2K02PjvnA3vyw5o3DXaFofSyPteaMovRB85WZh/0=";
    };

    "x86_64-darwin" = {
      target = "x86_64-apple-darwin";
      hash = "sha256-lI0w8Nm3Yt449UqN4ufJQg+rQRkMXOKLDCG+1d5/GjI=";
    };

    "x86_64-linux" = {
      target = "x86_64-unknown-linux-gnu";
      hash = "sha256-BcHez4Lp6N0911ZTUrRH1V9IHdDTs1r6q2KORJ1oiV0=";
    };

    "aarch64-linux" = {
      target = "aarch64-unknown-linux-gnu";
      hash = "sha256-vDxjK/scU461qKim8+WuRtTJVFhsjgbmOlwGyTDIQ0E=";
    };
  };

  platform =
    platformMap.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-${platform.target}.tar.gz";
    hash = platform.hash;
  };
in
stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit version;

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ] ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [
    libcap
    openssl
    zlib
    stdenv.cc.cc.lib
  ];

  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar xzf ${src} -C $out/bin
    mv $out/bin/codex-${platform.target} $out/bin/codex
    runHook postInstall
  '';

  meta = {
    description = "Lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    platforms = builtins.attrNames platformMap;
    mainProgram = "codex";
  };
}
