{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  procps,
  ripgrep,
  bubblewrap,
  socat,
}:

let
  version = "2.1.145";

  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";

  platformMap = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha256-No3NlwnIVTT2cwcefMjrVCK8/zZ/ub31ziXZYZqrfvU=";
    };

    "x86_64-darwin" = {
      suffix = "darwin-x64";
      hash = "sha256-wj3FZiFCedBwj0ISJh8CPY5j1a9a75Fjjr/cCQs+M94=";
    };

    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha256-s/+8Emib/oE4nWV3eH/OpMq4G9O2u6m3Gec3cLYtcg4=";
    };

    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha256-da1h1pDXlEDIK1hBRE4bQsquVXNq83yX3Q4GjvIM45A=";
    };
  };

  platform =
    platformMap.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  src = fetchurl {
    url = "${baseUrl}/${version}/${platform.suffix}/claude";
    hash = platform.hash;
  };

  runtimePath = lib.makeBinPath (
    [
      procps
      ripgrep
    ]
    ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [
      bubblewrap
      socat
    ]
  );
in
stdenvNoCC.mkDerivation {
  pname = "claude-code";
  inherit version;

  dontUnpack = true;

  nativeBuildInputs =
    [ makeWrapper ]
    ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [
    stdenv.cc.cc.lib
  ];

  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 ${src} $out/bin/claude
    wrapProgram $out/bin/claude \
      --set DISABLE_AUTOUPDATER 1 \
      --set DISABLE_INSTALLATION_CHECKS 1 \
      --prefix PATH : "${runtimePath}"
    runHook postInstall
  '';

  meta = {
    description = "AI coding assistant in your terminal (native binary)";
    homepage = "https://www.anthropic.com/claude-code";
    license = lib.licenses.unfree;
    platforms = builtins.attrNames platformMap;
    mainProgram = "claude";
  };
}
