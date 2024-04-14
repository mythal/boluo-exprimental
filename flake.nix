{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.napalm.url = "github:nix-community/napalm";

  # NOTE: This is optional, but is how to configure napalm's env
  inputs.napalm.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    {
      self,
      nixpkgs,
      napalm,
    }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages."${system}";
      nodeDeps =
        napalm.legacyPackages."${system}".buildPackage
          # Keeps only package.json and package-lock.json files
          (pkgs.lib.sourceByRegex ./. [
            ".*package.json"
            ".*package-lock.json"
            "(apps|packages)"
            "(apps|packages)/[a-zA-Z0-9_-]+"
          ])
          {
            buildInputs = with pkgs; [ cacert ];
            npmCommands = [ "npm ci --loglevel verbose --nodedir=${pkgs.nodejs}/include/node" ];
          };
    in
    {

      packages."${system}".boluo = pkgs.stdenv.mkDerivation {
        name = "boluo";
        src = ./.;
        version = "0.0.0";
        buildInputs = [
          nodeDeps
          pkgs.nodejs
          pkgs.cacert
        ];

        configurePhase = ''
          runHook preConfigure

          export HOME=$(mktemp -d)

          runHook postConfigure
        '';
        buildPhase = ''
          runHook preBuild
          cp -r ${nodeDeps}/_napalm-install/node_modules .
          chmod -R u+w .
          npm run build
          runHook postBuild
        '';
        installPhase = ''
          mkdir -p $out
          cp -r apps/web/.next/* $out
        '';
      };

      devShells."${system}".default = pkgs.mkShell { nativeBuildInputs = with pkgs; [ nodejs ]; };
    };
}
