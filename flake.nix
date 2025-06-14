{
  description = "axolotl browser engine";

 inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { 
          inherit system overlays;
          config.allowUnfree = true;
        };
        rustToolchain = pkgs.rust-bin.stable."1.70.0".default.override {
          extensions = [ "rust-src" "rustfmt" "clippy" ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "axolotl-dev";
          nativeBuildInputs = [
            rustToolchain
            pkgs.bazel_6
            pkgs.bazel-buildtools
            pkgs.gcc
            pkgs.binutils
            pkgs.glibc
            pkgs.stdenv.cc.cc.lib
            pkgs.jdk
          ];
          
          shellHook = ''
          export PATH="${rustToolchain}/bin:$PATH"
          export CARGO_HOME=$(mktemp -d)
          export RUSTUP_HOME=$(mktemp -d)
          export JAVA_HOME="${pkgs.jdk}"
          export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.glibc}/lib:$LD_LIBRARY_PATH"
          export RUSTFLAGS="-C link-arg=-fuse-ld=bfd"
          echo "Using Rust: $(rustc --version)"
          echo "Using GCC: $(gcc --version | head -n1)"
          '';
        };
      }
    );
}
