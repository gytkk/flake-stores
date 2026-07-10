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
  version = "0.144.1";

  platformMap = {
    "aarch64-darwin" = {
      target = "aarch64-apple-darwin";
      codexHash = "sha256-iOcqyL0wgV99GOYtrDM9wgzjrRy6lL4WSaGXfdm/27g=";
      codeModeHostHash = "sha256-AK2hytz03pE91Ech8mGCqwNoagRW2urjJIKfuvUNKJQ=";
    };

    "x86_64-darwin" = {
      target = "x86_64-apple-darwin";
      codexHash = "sha256-DqctIceUUENC1f4NXQV7AiHApC9L30pIuVryQ68rDA4=";
      codeModeHostHash = "sha256-jP4CaQWEBmSPXVk8vGWvvBgErjUnJW8O9VkCFKr7/Zc=";
    };

    "x86_64-linux" = {
      target = "x86_64-unknown-linux-musl";
      codexHash = "sha256-hAka4gxl/MfUEg25fRvVfX/435x2Cft4HHjC671PWig=";
      codeModeHostHash = "sha256-GJrd8L4WqEaVQJMceKDSdnX2TgX2WaZcfVWBODg90l8=";
    };

    "aarch64-linux" = {
      target = "aarch64-unknown-linux-musl";
      codexHash = "sha256-ufjvX5jkbO1Nu9N1akIj4+4pmkV/9IijMFvqRV2otbg=";
      codeModeHostHash = "sha256-BhJhTfmqRcNsdGNBn+PEbnodN/TO0b6cbonNzDTAWOc=";
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
