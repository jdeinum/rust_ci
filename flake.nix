{
  description = "INSERT DESCRIPTION HERE";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay }:
    let
      system = "x86_64-linux";
      overlays = [ (import rust-overlay) ];
      pkgs = import nixpkgs {
        inherit system overlays;
      };

      rustToolchain = pkgs.rust-bin.stable.latest.default;

      app = pkgs.rustPlatform.buildRustPackage {
        pname = "CARGO PACKAGE NAME HERE";
        version = "CARGO PACKAGE VERSION HERE (i.e 0.1.0)";
        
        src = ./.;
        
        cargoLock = {
          lockFile = ./Cargo.lock;
        };

        buildInputs = with pkgs; [
        ];

        nativeBuildInputs = with pkgs; [
        ];
        
        # set env variables
        # PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
        
        # if we require any resources for our tests, set to false, otherwise
        # true
        doCheck = false;
      };

    in
    {
      packages.${system}.default = app;

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          rustToolchain
          # Optional dev tools
          # rust-analyzer
          # sqlx-cli      # For database migrations
          # postgresql    # For local postgres server
        ];
      };
    };
}
