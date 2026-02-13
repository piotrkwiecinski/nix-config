{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    nodejs_20
    nodePackages.bash-language-server
    nodePackages.typescript
    nodePackages.typescript-language-server
    nodePackages.yaml-language-server
    rust-analyzer
    rustc
    rustfmt
    unstable.phpactor
    lua-language-server
    jetbrains-mono
    pandoc
  ];

  xdg.configFile."emacs/init.el".source = ./init.el;
  xdg.configFile."emacs/early-init.el".source = ./early-init.el;

  programs.emacs.enable = true;
  programs.emacs.package = pkgs.unstable.emacsWithPackagesFromUsePackage {
    config = ./init.el;
    package = pkgs.unstable.emacs30-pgtk;
    alwaysEnsure = true;
    extraEmacsPackages =
      epkgs: with epkgs; [
        (treesit-grammars.with-grammars (ts: [
          ts.tree-sitter-bash
          ts.tree-sitter-css
          ts.tree-sitter-graphql
          ts.tree-sitter-javascript
          ts.tree-sitter-json
          ts.tree-sitter-nix
          ts.tree-sitter-php
          ts.tree-sitter-jsdoc
          ts.tree-sitter-python
          ts.tree-sitter-rust
          ts.tree-sitter-lua
          ts.tree-sitter-toml
          ts.tree-sitter-tsx
          ts.tree-sitter-typescript
          ts.tree-sitter-yaml
          ts.tree-sitter-html
          ts.tree-sitter-phpdoc
        ]))
        pkgs.claude-code-ide
        ob-php
      ];
  };

  services.emacs = {
    enable = true;
    socketActivation.enable = true;

    client = {
      enable = true;
    };
  };

  home.sessionVariables = {
    ALTERNATIVE_EDITOR = "";
    EDITOR = "emacsclient -t";
    VISUAL = "emacsclient -c -a emacs";
  };
}
