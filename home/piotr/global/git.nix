{
  pkgs,
  config,
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

    includes = [
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
    ];

    ignores = [
      "*~"
      "*.swp"
      ".idea/"
      "result/"
      "result"

      "node_modules/"

      "auth.json"

      "*.elc"
      ".dir-locals.el"
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
    };
  };
}
