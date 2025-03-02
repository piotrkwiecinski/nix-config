{ ... }:
{
  programs.git = {
    enable = true;

    userName = "Piotr Kwiecinski";
    userEmail = "piotr.kwiecinski@codemanufacture.com";

    lfs.enable = true;

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      rebase.autoStash = true;
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
      "github.com" = {
        user = "git";
        identityFile = "~/.ssh/gh_rsa";
      };
    };
  };
}
