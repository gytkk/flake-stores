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
  version = "0.32.2";

  platformMap = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha256-uVjIHCmwxr8EB0efk/7549VA6OFYi8QvdqzDP6GpKHo=";
    };

    "x86_64-darwin" = {
      suffix = "darwin-x64";
      hash = "sha256-RjD/d8b9vagJ/WKmzOgHhS4PH/qqPmCg/05GkZ9hiMo=";
    };

    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha256-ZmoRKS/xr7KBwCMhL2YguX+BAmy7SY4xTc+vZ+CpKck=";
    };

    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha256-vMJPygfxJ5LjHxbLT7s4iT692cu+lEYxQ5sqVh1yX7w=";
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
