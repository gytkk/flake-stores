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
  version = "0.144.3";

  platformMap = {
    "aarch64-darwin" = {
      target = "aarch64-apple-darwin";
      codexHash = "sha256-JJqvEmRK3Th250CZjLoOrI19F16QOt2MvI2Oqh8C4rU=";
      codeModeHostHash = "sha256-Jw/+9mEDVFVJZc/NZ9JsQuc2+d21X8PYZ/dSUlEQFaQ=";
    };

    "x86_64-darwin" = {
      target = "x86_64-apple-darwin";
      codexHash = "sha256-igGRESKH4GhqqvGz2uz0y78jvg4BNPo8ibD2i+vcqqI=";
      codeModeHostHash = "sha256-FzRv9bi++OsZaKPxioyXoTnhWEAIFr5J+lEKi5CfCzY=";
    };

    "x86_64-linux" = {
      target = "x86_64-unknown-linux-musl";
      codexHash = "sha256-ubSujptWHGTfvF71LGMZy6dQrIfePH9ViFAmIx466ok=";
      codeModeHostHash = "sha256-NnURRlACC9c5RoTgXWYNYEPucZkI+DnooLv2sTu/ZP4=";
    };

    "aarch64-linux" = {
      target = "aarch64-unknown-linux-musl";
      codexHash = "sha256-3XbP1aLPm88OMiSv4o4jBlz9JyYuBuD/vI+kA0PwkFo=";
      codeModeHostHash = "sha256-yxx6NPVm6W3K2fuq7Yp6D1XaxEj+C22ewLQgt0Xjifo=";
    };
  };

  platform =
    platformMap.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  mkSrc =
    name: hash:
    fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/${name}-${platform.target}.tar.gz";
      inherit hash;
    };

  codexSrc = mkSrc "codex" platform.codexHash;
  codeModeHostSrc = mkSrc "codex-code-mode-host" platform.codeModeHostHash;
in
stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit version;

  dontUnpack = true;

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

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
    tar xzf ${codexSrc} -C $out/bin
    mv $out/bin/codex-${platform.target} $out/bin/codex
    tar xzf ${codeModeHostSrc} -C $out/bin
    mv $out/bin/codex-code-mode-host-${platform.target} $out/bin/codex-code-mode-host
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
