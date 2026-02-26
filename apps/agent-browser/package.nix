{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  patchelf,
  autoPatchelfHook,
  makeWrapper,
  playwright-driver,
}:

let
  version = "0.15.1";

  platformMap = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha256-mMHHSodSGXeMdqqaSJSV3RbrxkuEd8pxJRgp55Uapdw=";
    };

    "x86_64-darwin" = {
      suffix = "darwin-x64";
      hash = "sha256-kdHje9KyHFL/kfYrJD1MJg9WcGZCgI8xEcuS89wbjV0=";
    };

    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha256-GL3lqe8QRw0Ke+hYf0aepc6SBTDtlG810RjJ4jxRo5Y=";
    };

    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha256-CYXab9bXlPUsBKblgKawgCzXmxfpFMXIXS03sx0OhMY=";
    };
  };

  platform =
    platformMap.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  src = fetchurl {
    url = "https://github.com/vercel-labs/agent-browser/releases/download/v${version}/agent-browser-${platform.suffix}";
    hash = platform.hash;
  };
in
stdenvNoCC.mkDerivation {
  pname = "agent-browser";
  inherit version;

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ] ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ patchelf ];

  dontAutoPatchelf = true;
  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 ${src} $out/bin/agent-browser
  ''
  + lib.optionalString stdenvNoCC.hostPlatform.isLinux ''
    patchelf --set-interpreter "$(cat ${stdenv.cc}/nix-support/dynamic-linker)" $out/bin/agent-browser
  ''
  + ''
    wrapProgram $out/bin/agent-browser \
      --set PLAYWRIGHT_BROWSERS_PATH "${playwright-driver.browsers}"
    runHook postInstall
  '';

  meta = {
    description = "Browser automation CLI for AI agents";
    homepage = "https://github.com/vercel-labs/agent-browser";
    license = lib.licenses.asl20;
    platforms = builtins.attrNames platformMap;
    mainProgram = "agent-browser";
  };
}
