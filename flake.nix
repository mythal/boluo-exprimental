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
    in
    {
      # Assuming the flake is in the same directory as package-lock.json
      packages."${system}".boluo = napalm.legacyPackages."${system}".buildPackage ./. {
        buildInputs = with pkgs; [
          cacert
        ];
        certEnv = [
          "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        ];
        npmCommands = [
          "npm install --loglevel verbose --nodedir=${pkgs.nodejs}/include/node"
          "npm exec turbo telemetry disable"
          "npm exec turbo build -- --no-cache --verbosity=3 --no-daemon --no-update-notifier"
        ];
      };

      devShells."${system}".shell-name = pkgs.mkShell { nativeBuildInputs = with pkgs; [ nodejs ]; };
    };
}
