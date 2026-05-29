{
  lib,
  stdenv,
  buildNpmPackage,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  jq,
  nodejs,
  openssl,
  zlib,
  libcap,
}:

let
  version = "2026.5.27";

  src = fetchurl {
    url = "https://registry.npmjs.org/openclaw/-/openclaw-${version}.tgz";
    hash = "sha512-2N93zhdAo88KAbHt6T7KvYXf4s7XIkYXBgv1npYpn7e1Y9FvrtgtpsA38my9rtFW+70uXEojRPX5/OqnuDqJPw==";
  };
in
buildNpmPackage {
  pname = "openclaw";
  inherit version src;

  npmDepsHash = "sha256-Ie1KomavKXSSty3W8fM+EIrUM/Cef5eZFemgXZ4Ns6I=";
  sourceRoot = "package";
  makeCacheWritable = true;
  npmFlags = [ "--legacy-peer-deps" ];
  npmInstallFlags = [ "--legacy-peer-deps" ];
  dontNpmBuild = true;

  nativeBuildInputs = [
    makeWrapper
    jq
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
    openssl
    zlib
  ];

  postPatch = ''
    cp ${./npm-shrinkwrap.json} npm-shrinkwrap.json
  '';

  installPhase = ''
    runHook preInstall

    prune_dev_dependencies() {
      local root="$1"
      [ -f "$root/npm-shrinkwrap.json" ] || return 0

      ${jq}/bin/jq -r '
        .packages
        | to_entries[]
        | select(.value.dev == true)
        | .key
        | select(startswith("node_modules/"))
        | sub("^node_modules/"; "")
      ' "$root/npm-shrinkwrap.json" | LC_ALL=C sort -r | while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        rm -rf "$root/node_modules/$rel"
      done
    }

    prune_dev_dependencies "$PWD"

    mkdir -p "$out/libexec/openclaw" "$out/bin"
    cp -R . "$out/libexec/openclaw/"

    packageOut="$out/libexec/openclaw"

    rm -rf "$packageOut/node_modules/@discordjs/opus"/build-tmp-*

    ${lib.optionalString
      (stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isx86_64 && !stdenv.hostPlatform.isMusl)
      ''
        # Keep JS runtime packages intact. Only prune prebuilt artifacts whose
        # package names clearly target a non-x86_64-linux-gnu platform.
        rm -rf \
          "$packageOut/node_modules/@img/sharp-darwin-arm64" \
          "$packageOut/node_modules/@img/sharp-darwin-x64" \
          "$packageOut/node_modules/@img/sharp-libvips-darwin-arm64" \
          "$packageOut/node_modules/@img/sharp-libvips-darwin-x64" \
          "$packageOut/node_modules/@img/sharp-libvips-linux-arm" \
          "$packageOut/node_modules/@img/sharp-libvips-linux-arm64" \
          "$packageOut/node_modules/@img/sharp-libvips-linux-ppc64" \
          "$packageOut/node_modules/@img/sharp-libvips-linux-riscv64" \
          "$packageOut/node_modules/@img/sharp-libvips-linux-s390x" \
          "$packageOut/node_modules/@img/sharp-libvips-linuxmusl-arm64" \
          "$packageOut/node_modules/@img/sharp-libvips-linuxmusl-x64" \
          "$packageOut/node_modules/@img/sharp-linux-arm" \
          "$packageOut/node_modules/@img/sharp-linux-arm64" \
          "$packageOut/node_modules/@img/sharp-linux-ppc64" \
          "$packageOut/node_modules/@img/sharp-linux-riscv64" \
          "$packageOut/node_modules/@img/sharp-linux-s390x" \
          "$packageOut/node_modules/@img/sharp-linuxmusl-arm64" \
          "$packageOut/node_modules/@img/sharp-linuxmusl-x64" \
          "$packageOut/node_modules/@img/sharp-win32-arm64" \
          "$packageOut/node_modules/@img/sharp-win32-ia32" \
          "$packageOut/node_modules/@img/sharp-win32-x64" \
          "$packageOut/node_modules/@lancedb/lancedb-darwin-arm64" \
          "$packageOut/node_modules/@lancedb/lancedb-linux-arm64-gnu" \
          "$packageOut/node_modules/@lancedb/lancedb-linux-arm64-musl" \
          "$packageOut/node_modules/@lancedb/lancedb-linux-x64-musl" \
          "$packageOut/node_modules/@lancedb/lancedb-win32-arm64-msvc" \
          "$packageOut/node_modules/@lancedb/lancedb-win32-x64-msvc" \
          "$packageOut/node_modules/@lydell/node-pty-darwin-arm64" \
          "$packageOut/node_modules/@lydell/node-pty-darwin-x64" \
          "$packageOut/node_modules/@lydell/node-pty-linux-arm64" \
          "$packageOut/node_modules/@lydell/node-pty-win32-arm64" \
          "$packageOut/node_modules/@lydell/node-pty-win32-x64" \
          "$packageOut/node_modules/@mariozechner/clipboard-darwin-arm64" \
          "$packageOut/node_modules/@mariozechner/clipboard-darwin-universal" \
          "$packageOut/node_modules/@mariozechner/clipboard-darwin-x64" \
          "$packageOut/node_modules/@mariozechner/clipboard-linux-arm64-gnu" \
          "$packageOut/node_modules/@mariozechner/clipboard-linux-arm64-musl" \
          "$packageOut/node_modules/@mariozechner/clipboard-linux-riscv64-gnu" \
          "$packageOut/node_modules/@mariozechner/clipboard-linux-x64-musl" \
          "$packageOut/node_modules/@mariozechner/clipboard-win32-arm64-msvc" \
          "$packageOut/node_modules/@mariozechner/clipboard-win32-x64-msvc" \
          "$packageOut/node_modules/@napi-rs/canvas-android-arm64" \
          "$packageOut/node_modules/@napi-rs/canvas-darwin-arm64" \
          "$packageOut/node_modules/@napi-rs/canvas-darwin-x64" \
          "$packageOut/node_modules/@napi-rs/canvas-linux-arm-gnueabihf" \
          "$packageOut/node_modules/@napi-rs/canvas-linux-arm64-gnu" \
          "$packageOut/node_modules/@napi-rs/canvas-linux-arm64-musl" \
          "$packageOut/node_modules/@napi-rs/canvas-linux-riscv64-gnu" \
          "$packageOut/node_modules/@napi-rs/canvas-linux-x64-musl" \
          "$packageOut/node_modules/@napi-rs/canvas-win32-arm64-msvc" \
          "$packageOut/node_modules/@napi-rs/canvas-win32-x64-msvc" \
          "$packageOut/node_modules/@snazzah/davey-android-arm-eabi" \
          "$packageOut/node_modules/@snazzah/davey-android-arm64" \
          "$packageOut/node_modules/@snazzah/davey-darwin-arm64" \
          "$packageOut/node_modules/@snazzah/davey-darwin-x64" \
          "$packageOut/node_modules/@snazzah/davey-freebsd-x64" \
          "$packageOut/node_modules/@snazzah/davey-linux-arm-gnueabihf" \
          "$packageOut/node_modules/@snazzah/davey-linux-arm64-gnu" \
          "$packageOut/node_modules/@snazzah/davey-linux-arm64-musl" \
          "$packageOut/node_modules/@snazzah/davey-linux-x64-musl" \
          "$packageOut/node_modules/@snazzah/davey-win32-arm64-msvc" \
          "$packageOut/node_modules/@snazzah/davey-win32-ia32-msvc" \
          "$packageOut/node_modules/@snazzah/davey-win32-x64-msvc"

        if [ -d "$packageOut/node_modules/koffi/build/koffi" ]; then
          find "$packageOut/node_modules/koffi/build/koffi" -mindepth 1 -maxdepth 1 ! -name linux_x64 -exec rm -rf {} +
        fi

        rm -rf \
          "$packageOut/node_modules/lightningcss-linux-x64-musl" \
          "$packageOut/node_modules/@oxlint/binding-linux-x64-musl" \
          "$packageOut/node_modules/@rolldown/binding-linux-x64-musl" \
          "$packageOut/node_modules/sqlite-vec-darwin-arm64" \
          "$packageOut/node_modules/sqlite-vec-darwin-x64" \
          "$packageOut/node_modules/sqlite-vec-linux-arm64" \
          "$packageOut/node_modules/sqlite-vec-windows-x64"

        rm -rf \
          "$packageOut/node_modules/vite/node_modules/@rolldown/binding-linux-x64-musl" \
          "$packageOut/node_modules/unrun/node_modules/@rolldown/binding-linux-x64-musl"
      ''
    }

    find "$packageOut/node_modules/.bin" -xtype l -delete 2>/dev/null || true

    ${
      if stdenv.hostPlatform.isLinux then
        ''
          makeWrapper ${nodejs}/bin/node "$out/bin/openclaw" \
            --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libcap ]}" \
            --add-flags "$out/libexec/openclaw/openclaw.mjs"
        ''
      else
        ''
          makeWrapper ${nodejs}/bin/node "$out/bin/openclaw" \
            --add-flags "$out/libexec/openclaw/openclaw.mjs"
        ''
    }

    runHook postInstall
  '';

  meta = {
    description = "Multi-channel AI gateway with extensible messaging integrations";
    homepage = "https://github.com/openclaw/openclaw";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "openclaw";
  };
}
