{
  description = "Monorepo of non-nixpkgs app flakes.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];

      appNames = builtins.attrNames (
        nixpkgs.lib.filterAttrs (_name: type: type == "directory") (builtins.readDir ./apps)
      );

      forEachSystem = f: nixpkgs.lib.genAttrs systems (system: f system);

      pkgsFor = system: import nixpkgs { inherit system; config.allowUnfree = true; };

      packageFor =
        system: name: ((pkgsFor system).callPackage ./apps/${name}/package.nix { });

      mkPackages =
        system:
        if appNames == [ ] then
          { }
        else
          let
            defaultName = builtins.head appNames;
          in
          builtins.listToAttrs (
            [
              {
                name = "default";
                value = packageFor system defaultName;
              }
            ]
            ++ map (name: {
              name = name;
              value = packageFor system name;
            }) appNames
          );

      mkChecks =
        system:
        let
          pkgs = pkgsFor system;
          buildChecks = builtins.listToAttrs (
            map (name: {
              name = "${name}-build";
              value = packageFor system name;
            }) appNames
          );
          openclawSmoke =
            if system == "x86_64-linux" && builtins.elem "openclaw" appNames then
              let
                pkg = packageFor system "openclaw";
              in
              {
                openclaw-smoke = pkgs.runCommand "openclaw-smoke" { nativeBuildInputs = [ pkgs.nodejs ]; } ''
                  export HOME="$TMPDIR"
                  test -d "${pkg}/libexec/openclaw/skills"
                  ${pkgs.nodejs}/bin/node -e 'import("file://${pkg}/libexec/openclaw/node_modules/sharp/lib/index.js").then(() => console.log("sharp import ok")).catch((err) => { console.error(err); process.exit(1); })'
                  cd "${pkg}/libexec/openclaw"
                  ${pkgs.nodejs}/bin/node --input-type=module -e 'await import("@mariozechner/pi-ai/oauth"); console.log("pi-ai oauth import ok")'
                  ${pkg}/bin/openclaw skills list >/dev/null
                  touch "$out"
                '';
              }
            else
              { };
        in
        buildChecks // openclawSmoke;

      mkApps =
        system:
        builtins.listToAttrs (
          map (
            name:
            let
              pkg = packageFor system name;
            in
            {
              name = name;
              value = {
                type = "app";
                meta = {
                  description = pkg.meta.description or "${name} app";
                  mainProgram = pkg.meta.mainProgram or name;
                };
                program = "${pkg}/bin/${pkg.meta.mainProgram or name}";
              };
            }
          ) appNames
        );
    in
    {

      packages = forEachSystem mkPackages;
      checks = forEachSystem mkChecks;
      apps = forEachSystem mkApps;

      overlays.default =
        final: prev:
        builtins.listToAttrs (
          map (name: {
            name = name;
            value = final.callPackage ./apps/${name}/package.nix { };
          }) appNames
        );

      legacyPackages = forEachSystem (
        system:
        let
          pkgs = pkgsFor system;
        in
        builtins.listToAttrs (
          map (name: {
            name = name;
            value = pkgs.callPackage ./apps/${name}/package.nix { };
          }) appNames
        )
      );
    };
}
