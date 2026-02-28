{
  lib,
  stdenvNoCC,
  fetchurl,
  bun,
  cacert,
  procps,
  ripgrep,
  bubblewrap,
  socat,
}:

let
  version = "2.1.63";

  src = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-eHztBWax0Rp5AMuSJvd9Kv5dAiueu6hef9XNB758unc=";
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

  nativeBuildInputs = [
    bun
    cacert
  ];

  buildPhase = ''
    runHook preBuild
    export HOME=$TMPDIR
    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt

    mkdir -p $out/lib/node_modules/@anthropic-ai
    tar -xzf ${src} -C $out/lib/node_modules/@anthropic-ai
    mv $out/lib/node_modules/@anthropic-ai/package $out/lib/node_modules/@anthropic-ai/claude-code

    cd $out/lib/node_modules/@anthropic-ai/claude-code
    ${bun}/bin/bun install --production --ignore-scripts
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin

    cat > $out/bin/claude << WRAPPER
    #!/usr/bin/env bash
    export NODE_PATH="$out/lib/node_modules"
    export DISABLE_AUTOUPDATER=1
    export DISABLE_INSTALLATION_CHECKS=1
    export PATH="${runtimePath}\''${PATH:+:\$PATH}"

    # Intercept npm update commands used by claude-code self-update check
    _NPM_DIR="\$(mktemp -d)"
    trap 'rm -rf "\$_NPM_DIR"' EXIT
    cat > "\$_NPM_DIR/npm" << 'NPM_SCRIPT'
    #!/usr/bin/env bash
    case "\$1" in
      update|outdated) echo "Updates managed by Nix (v${version})"; exit 0 ;;
      view) [[ "\$2" =~ @anthropic-ai/claude-code ]] && { echo "Updates managed by Nix (v${version})"; exit 0; } ;;
    esac
    exec ${bun}/bin/bun "\$@"
    NPM_SCRIPT
    chmod +x "\$_NPM_DIR/npm"
    export PATH="\$_NPM_DIR:\$PATH"

    exec ${bun}/bin/bun run $out/lib/node_modules/@anthropic-ai/claude-code/cli.js "\$@"
    WRAPPER
    chmod +x $out/bin/claude

    runHook postInstall
  '';

  meta = {
    description = "AI coding assistant in your terminal (Bun runtime)";
    homepage = "https://www.anthropic.com/claude-code";
    license = lib.licenses.unfree;
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "claude";
  };
}
