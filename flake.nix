{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      darwin,
      homebrew,
      home-manager,
      ...
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          imports = [
            homebrew.darwinModules.nix-homebrew
            home-manager.darwinModules.home-manager
          ];

          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.neovim
            pkgs.git
            pkgs.tmux
            pkgs.nodejs
          ];

          fonts.packages = [ (pkgs.nerdfonts.override { fonts = [ "Meslo" ]; }) ];

          nix-homebrew = {
            enable = true;
            user = "bamil";
          };
          homebrew = {
            enable = true;
            casks = [
              "google-chrome"
              "visual-studio-code"
              "spotify"
              "slack"
              "iterm2"
              "docker"
              "raycast"
              "monitorcontrol"
              "flux"
              "zed"
            ];
            onActivation.cleanup = "zap";
            onActivation.autoUpdate = true;
            onActivation.upgrade = true;
          };

          system.defaults = {
            dock.autohide = true;
            dock.orientation = "bottom";
          };

          users.users.bamil = {
            name = "bamil";
            home = "/Users/bamil";
          };

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.bamil = {
              home.stateVersion = "25.05";
              programs = {
                git = {
                  enable = true;
                  userName = "Kamil Baryś";
                  userEmail = "kamil.barys@stxnext.pl";
                };
                zsh = {
                  enable = true;
                  enableCompletion = true;
                  enableAutosuggestions = true;
                  enableSyntaxHighlighting = true;
                  oh-my-zsh = {
                    enable = true;
                    theme = "robbyrussell";
                    plugins = ["vi-mode" "git" "gh" "docker" "docker-compose"];
                  };
                };
              };
            };
          };

          # environment

          # Auto upgrade nix package and the daemon service.
          services.nix-daemon.enable = true;
          # nix.package = pkgs.nix;

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Enable alternative shell support in nix-darwin.
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 5;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";
          nixpkgs.config = {
            allowUnfree = true;
          };
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations."mac-mini" = darwin.lib.darwinSystem {
        modules = [ configuration ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."mac-mini".pkgs;
    };
}
