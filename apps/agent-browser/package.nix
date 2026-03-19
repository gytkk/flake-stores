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
  version = "0.21.2";

  platformMap = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha256-rn2gnheaM2Q5EnpJ7le22IBOvrR+Kd9Aa33L+sWuZLc=";
    };

    "x86_64-darwin" = {
      suffix = "darwin-x64";
      hash = "sha256-I7fM2Q+amliTqQLTzcbIA8sAfFXdNWiReWT4MJBTmpk=";
    };

    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha256-ypVeoZvPHmAOpZSip61lyh3xOVUhFHDYKrtrs1fvgHg=";
    };

    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha256-O3wNNHEH35mCHm1+f8q65SbXD3ABt/e/bZyi/qlQt/0=";
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
