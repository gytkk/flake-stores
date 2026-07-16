{
  lib,
  stdenv,
  buildNpmPackage,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  nodejs_22,
  zlib,
}:

let
  version = "0.80.8";

  src = fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
    hash = "sha512-oal0jK9E221Imhrj4Q4wXOhWmhzZEzbt9gmbVHs3UR4+KaClg+Ki1vH2FTVY7hntga89koPFSq4kQ6XV/HoSng==";
  };
in
buildNpmPackage {
  pname = "pi";
  inherit version src;

  npmDepsHash = "sha256-oGkSxc83fwE1UAbRL92Xl7Sn2cfFUiaQ91qlOmkIt50=";
  sourceRoot = "package";
  makeCacheWritable = true;
  npmInstallFlags = [
    "--omit=dev"
    "--ignore-scripts"
  ];
  dontNpmBuild = true;
  nodejs = nodejs_22;

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
    zlib
  ];

  postPatch = ''
    cp ${./npm-shrinkwrap.json} npm-shrinkwrap.json
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/libexec/pi" "$out/bin"
    cp -R . "$out/libexec/pi/"

    find "$out/libexec/pi/node_modules/.bin" -xtype l -delete 2>/dev/null || true

    makeWrapper ${nodejs_22}/bin/node "$out/bin/pi" \
      --add-flags "$out/libexec/pi/dist/cli.js"

    runHook postInstall
  '';

  meta = {
    description = "Coding agent CLI with read, bash, edit, write tools and session management";
    homepage = "https://pi.dev";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "pi";
  };
}
