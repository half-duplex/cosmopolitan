{
  description = "Your build-once run-anywhere c library";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-24.11";

  outputs = {
    self,
    nixpkgs,
  }: let
    # to work with older version of flakes
    lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

    version = "4.0.2";

    # System types to support.
    supportedSystems = ["x86_64-linux" "x86_64-darwin"]; #"aarch64-linux" "aarch64-darwin" ];

    # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    # Nixpkgs instantiated for supported system types.
    nixpkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
        overlays = [self.overlays.default];
      });
  in {
    formatter.x86_64-darwin = nixpkgs.legacyPackages.x86_64-darwin.alejandra;

    # A Nixpkgs overlay.
    overlays.default = final: prev: {
      s0ph0s-cosmopolitan = prev.cosmopolitan.overrideAttrs (finalAttrs: prevAttrs: {
        version = "4.0.2";
        src = ./.;
        patches = [];
        meta = {
          inherit (prevAttrs.meta) description license platforms;
          homepage = "https://github.com/s0ph0s-dog/cosmopolitan";
        };
      });
    };

    # Provide some binary packages for selected system types.
    packages = forAllSystems (system: {
      inherit (nixpkgsFor.${system}) s0ph0s-cosmopolitan;
      default = self.packages.${system}.s0ph0s-cosmopolitan;
    });

    nixosModules.default = {pkgs, ...}: {
      boot.binfmt.registrations.APE = {
        interpreter = "${self.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/ape";
        recognitionType = "magic";
        magicOrExtension = "MZqFpD";
        fixBinary = true;
        preserveArgvZero = true;
        wrapInterpreterInShell = false;
      };
    };
  };
}
