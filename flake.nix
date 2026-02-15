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

      packageFor =
        system: name: (nixpkgs.legacyPackages.${system}.callPackage ./apps/${name}/package.nix { });

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
        builtins.listToAttrs (
          map (name: {
            name = "${name}-build";
            value = packageFor system name;
          }) appNames
        );

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
          pkgs = nixpkgs.legacyPackages.${system};
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
