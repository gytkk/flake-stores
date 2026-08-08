{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "0.8.0";

  platformMap = {
    "aarch64-darwin" = {
      target = "macos-aarch64";
      hash = "sha256-1Tqfk/zP38xVYyknv1EAL1rdCqeZC831CP+9hKxlgXg=";
    };

    "x86_64-darwin" = {
      target = "macos-x86_64";
      hash = "sha256-d8ta/WyPyqrzvCjkdOwBwgkzGtCAlOINf4qpsLt41kk=";
    };

    "x86_64-linux" = {
      target = "linux-x86_64";
      hash = "sha256-uHLqfkD6LLF+hXrJtisb8m23tAPGIvXS8/WzX26azSg=";
    };

    "aarch64-linux" = {
      target = "linux-aarch64";
      hash = "sha256-9kesZkaNnvvGQv5TT7KERo8K6mBkFgb8AI38DYKjyoc=";
    };
  };

  platform =
    platformMap.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  src = fetchurl {
    url = "https://github.com/herdrdev/herdr/releases/download/v${version}/herdr-${platform.target}";
    hash = platform.hash;
  };
in
stdenvNoCC.mkDerivation {
  pname = "herdr";
  inherit version;

  dontUnpack = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 ${src} $out/bin/herdr
    runHook postInstall
  '';

  meta = {
    description = "Terminal workspace manager for AI coding agents";
    homepage = "https://herdr.dev";
    license = lib.licenses.asl20;
    platforms = builtins.attrNames platformMap;
    mainProgram = "herdr";
  };
}
