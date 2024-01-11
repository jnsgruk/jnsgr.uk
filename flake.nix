{
  description = "jnsgruk's personal website and blog";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    formatters.url = "github:Gerschtli/nix-formatter-pack";
    formatters.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self
    , formatters
    , nixpkgs
    , ...
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" ];

      pkgsForSystem = system: (import nixpkgs {
        inherit system;
      });
    in
    {
      packages = forAllSystems (system:
        let
          inherit (pkgsForSystem system) buildGoModule hugo cacert;
          inherit (self) lastModifiedDate;
          version = self.rev or self.dirtyRev or "dirty";
        in
        rec {
          default = jnsgruk;
          jnsgruk = buildGoModule {
            inherit version;
            pname = "jnsgruk";
            src = self;
            vendorHash = "sha256-bHGM+4aL2rjddEGXd4RGUFLK7/gTc2fMGa4KqLou0lk=";
            buildInputs = [ cacert ];
            nativeBuildInputs = [ hugo ];

            preBuild = ''
              go generate ./...
            '';

            ldflags = [
              "-X main.commit=${version}"
              "-X main.date=${lastModifiedDate}"
            ];

            postInstall = ''
              mv $out/bin/jnsgr.uk $out/bin/jnsgruk
            '';
          };
        });

      devShells = forAllSystems (system:
        let
          pkgs = pkgsForSystem system;
        in
        {
          default = pkgs.mkShell {
            name = "jnsgruk";
            NIX_CONFIG = "experimental-features = nix-command flakes";
            nativeBuildInputs = with pkgs; [
              go_1_21
              go-tools
              gofumpt
              gopls
              hugo
              zsh
            ];
            shellHook = "exec zsh";
          };
        });

      formatter = forAllSystems (system:
        formatters.lib.mkFormatter {
          pkgs = pkgsForSystem system;
          config.tools = {
            deadnix.enable = true;
            nixpkgs-fmt.enable = true;
            statix.enable = true;
          };
        }
      );
    };
}

