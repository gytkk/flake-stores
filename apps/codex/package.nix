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
  version = "0.143.0";

  platformMap = {
    "aarch64-darwin" = {
      target = "aarch64-apple-darwin";
      hash = "sha256-ffI4TwN1Gd/32/QlLmCROlwcf9tmwUZ8kSWystNZSoY=";
    };

    "x86_64-darwin" = {
      target = "x86_64-apple-darwin";
      hash = "sha256-93bvHV5fAxUd1uavlMx7E+mwjDxSvWAydpIAmwHb+0o=";
    };

    "x86_64-linux" = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-2dxzHcZuInsXWxPAcb6eoSbMdnL8rIqHgj2lCw0rL/4=";
    };

    "aarch64-linux" = {
      target = "aarch64-unknown-linux-musl";
      hash = "sha256-2uxMsY860+VB6JhnY+cwGbPdtybR+GkuUOpfqYjAnXg=";
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
