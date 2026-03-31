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
  version = "0.118.0";

  platformMap = {
    "aarch64-darwin" = {
      target = "aarch64-apple-darwin";
      hash = "sha256-utPCyDuHS3Z86Gr2T08AW8FN6nny2MrDfPput3cQxxc=";
    };

    "x86_64-darwin" = {
      target = "x86_64-apple-darwin";
      hash = "sha256-IjSzWk30WXMEQjmTaNWEBNg459VrIm9m3x3LTqW0Mcw=";
    };

    "x86_64-linux" = {
      target = "x86_64-unknown-linux-gnu";
      hash = "sha256-Ig8VyhxjnpBarjhdqWDhiXiC/udmU/X59d/6X3VPfJg=";
    };

    "aarch64-linux" = {
      target = "aarch64-unknown-linux-gnu";
      hash = "sha256-n5wSQdOXgzhDE5dXI0dQIN++G9ewI8IrBIFhaBWfj9c=";
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
