{
  pkgs,
  config,
  lib,
  ...
}:
{
  programs.git = {
    enable = true;
    package = pkgs.unstable.gitFull;

    settings = {
      user = {
        name = "Piotr Kwiecinski";
        email = "piotr.kwiecinski@codemanufacture.com";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      rebase.autoStash = true;
    };

    lfs.enable = true;

    maintenance = {
      enable = true;
      repositories = [
        "${config.home.homeDirectory}/projects/opensource/nixos-nixpkgs"
      ];
    };

    includes =
      let
        hasSopsTemplate =
          name: (config ? sops) && (config.sops ? templates) && (config.sops.templates ? ${name});
      in
      # Fallback for hosts without sops (homelab, homeserver)
      lib.optionals (!(hasSopsTemplate "git-personal-github.inc")) [
        {
          condition = "hasconfig:remote.*.url:git@github.com:*/**";
          contents = {
            user = {
              email = "2151333+piotrkwiecinski@users.noreply.github.com";
              signingKey = "EC0DE1CB9D5258B4";
            };

            commit.gpgSign = true;
            tag.gpgSign = true;

            core.sshCommand = "ssh -i ~/.ssh/gh_rsa";
          };
        }
      ]
      # Use sops template when available
      ++ lib.optionals (hasSopsTemplate "git-personal-github.inc") [
        {
          condition = "hasconfig:remote.*.url:git@github.com:*/**";
          path = config.sops.templates."git-personal-github.inc".path;
        }
      ]
      # Forgejo homeserver - fallback for hosts without sops
      ++ lib.optionals (!(hasSopsTemplate "git-forgejo-homeserver.inc")) [
        {
          condition = "hasconfig:remote.*.url:forgejo@forgejo.homeserver.local:*/**";
          contents = {
            user = {
              email = "piotr@noreply.forgejo.homeserver.local";
              signingKey = "EC0DE1CB9D5258B4";
            };
            commit.gpgSign = true;
            tag.gpgSign = true;
            core.sshCommand = "ssh -i ~/.ssh/forgejo_homeserver";
          };
        }
      ]
      # Use sops template when available
      ++ lib.optionals (hasSopsTemplate "git-forgejo-homeserver.inc") [
        {
          condition = "hasconfig:remote.*.url:forgejo@forgejo.homeserver.local:*/**";
          path = config.sops.templates."git-forgejo-homeserver.inc".path;
        }
      ];

    ignores = [
      "*~"
      "*.swp"
      ".idea/"
      "*.iml"
      "result/"
      "result"

      "node_modules/"

      "auth.json"

      "*.elc"
      ".dir-locals.el"

      ".claude/settings.local.json"
    ];
  };

  programs.ssh = {
    matchBlocks = {
      "pkgithub" = {
        user = "git";
        hostname = "github.com";
        identityFile = "~/.ssh/gh_rsa";
        identitiesOnly = true;
      };
      "forgejo.homeserver.local" = {
        user = "forgejo";
        hostname = "forgejo.homeserver.local";
        identityFile = "~/.ssh/forgejo_homeserver";
        identitiesOnly = true;
      };
    };
  };
}
