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
}:

let
  version = "2026.4.14";

  src = fetchurl {
    url = "https://registry.npmjs.org/openclaw/-/openclaw-${version}.tgz";
    hash = "sha512-g+uKkJnaSaSBrPO/1V8Sp9Cba5JMjcgpKBYAn7ll85rBxGEioQAA6RfmZiB06UyHmRCULLB3CaAwjZ+VTJ7UUQ==";
  };
in
buildNpmPackage {
  pname = "openclaw";
  inherit version src;

  npmDepsHash = "sha256-1To4sfd5UX2+Dk0EYIJikQlElx0mbdZVWKH0Kzpgu4Y=";
  sourceRoot = "package";
  makeCacheWritable = true;
  npmFlags = [ "--legacy-peer-deps" ];
  npmInstallFlags = [ "--legacy-peer-deps" ];
  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper jq ] ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
    openssl
    zlib
  ];

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  installPhase = ''
    runHook preInstall

    prune_dev_dependencies() {
      local root="$1"
      [ -f "$root/package-lock.json" ] || return 0

      ${jq}/bin/jq -r '
        .packages
        | to_entries[]
        | select(.value.dev == true)
        | .key
        | select(startswith("node_modules/"))
        | sub("^node_modules/"; "")
      ' "$root/package-lock.json" | LC_ALL=C sort -r | while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        rm -rf "$root/node_modules/$rel"
      done
    }

    keep_only_children() {
      local parent="$1"
      shift
      [ -d "$parent" ] || return 0

      for child in "$parent"/*; do
        [ -e "$child" ] || continue
        local base
        base="$(basename "$child")"
        case " $* " in
          *" $base "*) ;;
          *) rm -rf "$child" ;;
        esac
      done
    }

    prune_dev_dependencies "$PWD"

    mkdir -p "$out/libexec/openclaw" "$out/bin"
    cp -R . "$out/libexec/openclaw/"

    packageOut="$out/libexec/openclaw"

    rm -rf "$packageOut/node_modules/@discordjs/opus"/build-tmp-*

    ${lib.optionalString (stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isx86_64 && !stdenv.hostPlatform.isMusl) ''
      keep_only_children "$packageOut/node_modules/@img" \
        colour \
        sharp-libvips-linux-x64 \
        sharp-linux-x64

      keep_only_children "$packageOut/node_modules/@lancedb" \
        lancedb \
        lancedb-linux-x64-gnu

      keep_only_children "$packageOut/node_modules/@lydell" \
        node-pty-linux-x64

      keep_only_children "$packageOut/node_modules/@mariozechner" \
        clipboard \
        clipboard-linux-x64-gnu \
        jiti \
        pi-agent-core \
        pi-ai \
        pi-coding-agent \
        pi-tui

      keep_only_children "$packageOut/node_modules/@napi-rs" \
        canvas-linux-x64-gnu

      keep_only_children "$packageOut/node_modules/@snazzah" \
        davey-linux-x64-gnu

      keep_only_children "$packageOut/node_modules/koffi/build/koffi" \
        linux_x64

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
    ''}

    find "$packageOut/node_modules/.bin" -xtype l -delete 2>/dev/null || true

    makeWrapper ${nodejs}/bin/node "$out/bin/openclaw" \
      --add-flags "$out/libexec/openclaw/openclaw.mjs"

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
