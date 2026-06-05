{
  lib,
  stdenv,
  stdenvNoCC,
  fetchzip,
  patchelf,
  makeWrapper,
  ripgrep,
}:

let
  version = "1.16.2";

  platformMap = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      ext = "zip";
      hash = "sha256-0imWG80GkFUGnAEZarfMdvlCKe2RaPxrBAUYJc561bk=";
    };

    "x86_64-darwin" = {
      suffix = "darwin-x64";
      ext = "zip";
      hash = "sha256-AdPsawGo+B9g0EYeYbr8x9Fk7GoEwlinZzYy8AkB1rM=";
    };

    "x86_64-linux" = {
      suffix = "linux-x64";
      ext = "tar.gz";
      hash = "sha256-2WGy3qzg+2xr0bcAGQNCrBepcPbgSNKoardRyld2rc4=";
    };

    "aarch64-linux" = {
      suffix = "linux-arm64";
      ext = "tar.gz";
      hash = "sha256-81/qZ3gLYhumCJbkOaV6TwYpe4PONyQ6QRtbaB2KPm8=";
    };
  };

  platform =
    platformMap.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  src = fetchzip {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-${platform.suffix}.${platform.ext}";
    hash = platform.hash;
    stripRoot = false;
  };
in
stdenvNoCC.mkDerivation {
  pname = "opencode";
  inherit version src;

  nativeBuildInputs = [ makeWrapper ] ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ patchelf ];

  dontAutoPatchelf = true;
  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 opencode $out/bin/opencode
  ''
  + lib.optionalString stdenvNoCC.hostPlatform.isLinux ''
    patchelf --set-interpreter "$(cat ${stdenv.cc}/nix-support/dynamic-linker)" $out/bin/opencode
  ''
  + ''
    wrapProgram $out/bin/opencode \
      --prefix PATH : ${lib.makeBinPath [ ripgrep ]}
    runHook postInstall
  '';

  meta = {
    description = "AI coding agent built for the terminal";
    homepage = "https://github.com/anomalyco/opencode";
    license = lib.licenses.mit;
    platforms = builtins.attrNames platformMap;
    mainProgram = "opencode";
  };
}
