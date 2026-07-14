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
  version = "0.144.4";

  platformMap = {
    "aarch64-darwin" = {
      target = "aarch64-apple-darwin";
      codexHash = "sha256-d8iWmkgTAvnbHZ6ipsIcCDq64/Go/Ipyddw4MjaZOR4=";
      codeModeHostHash = "sha256-o0KbpqbWWkym8ywpLTXw2gZ2UfwPgzPc+kKnw7a119k=";
    };

    "x86_64-darwin" = {
      target = "x86_64-apple-darwin";
      codexHash = "sha256-J06kkxJGYh1HetYdYeozA1J4eOd/qRAIffUhU/XmGI4=";
      codeModeHostHash = "sha256-S0noOKsdZt1P7PyANBGmtjUiW6S/j+JkjTFROFUSmA0=";
    };

    "x86_64-linux" = {
      target = "x86_64-unknown-linux-musl";
      codexHash = "sha256-N8mFvp2J6MT0OzqgWUwSE+rCEtMK4rlSIfCP7IB1FdE=";
      codeModeHostHash = "sha256-MClBvtb7PIgp3eX+coZO4ERm7sFiPHO0PNRL8vr+gDg=";
    };

    "aarch64-linux" = {
      target = "aarch64-unknown-linux-musl";
      codexHash = "sha256-TQckPvSuZ4a4syHXrqP5vk4dLFl65UB+fBuYczNAgrI=";
      codeModeHostHash = "sha256-y2nctK5lcykENf5Wch8f7VgPlpl9JY81Nv/hjQX6a48=";
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
