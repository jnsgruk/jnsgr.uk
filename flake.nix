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
      packages = forAllSystems
        (system:
          let
            inherit (pkgsForSystem system) buildEnv buildGoModule cacert dockerTools hugo lib;
            version = self.shortRev or (builtins.substring 0 7 self.dirtyRev);
            rev = self.rev or self.dirtyRev;
          in
          {
            default = self.packages.${system}.jnsgruk;

            jnsgruk = buildGoModule {
              inherit version;
              pname = "jnsgruk";
              src = lib.cleanSource ./.;

              vendorHash = "sha256-4f04IS76JtH+I4Xpu6gF8JQSO3TM7p56mCs8BwyPo8U=";

              buildInputs = [ cacert ];
              nativeBuildInputs = [ hugo ];

              # Nix doesn't play well with Hugo's "GitInfo" module, so disable it and inject
              # the revision from the flake.
              postPatch = ''
                substituteInPlace ./site/layouts/shortcodes/gitinfo.html \
                  --replace "{{ .Page.GitInfo.Hash }}" "${rev}"
                
                substituteInPlace ./site/config/_default/config.yaml \
                  --replace "enableGitInfo: true" "enableGitInfo: false"
              '';

              # Generate the Hugo site before building the Go application which embeds the
              # built site.
              preBuild = ''
                go generate ./...
              '';

              ldflags = [
                "-X main.commit=${rev}"
              ];

              # Rename the main executable in the output directory
              postInstall = ''
                mv $out/bin/jnsgr.uk $out/bin/jnsgruk
              '';

              meta.mainProgram = "jnsgruk";
            };

            jnsgruk-container = dockerTools.buildImage {
              name = "jnsgruk/jnsgr.uk";
              tag = version;
              created = "now";
              copyToRoot = buildEnv {
                name = "image-root";
                paths = [ self.packages.${system}.jnsgruk cacert ];
                pathsToLink = [ "/bin" "/etc/ssl/certs" ];
              };
              config = {
                Entrypoint = [ "${lib.getExe self.packages.${system}.jnsgruk}" ];
                Expose = [ 8080 8801 ];
                User = "10000:10000";
              };
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
              flyctl
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

