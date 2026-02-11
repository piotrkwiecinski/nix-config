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
  ];

  xdg.configFile."emacs/init.el".source = ./init.el;
  xdg.configFile."emacs/early-init.el".source = ./early-init.el;

  programs.emacs.enable = true;
  programs.emacs.package = (
    (pkgs.unstable.emacsPackagesFor pkgs.unstable.emacs30-pgtk).emacsWithPackages (
      epkgs: with epkgs; [
        async
        bats-mode
        cape
        csv-mode
        compat
        composer
        consult
        corfu
        dap-mode
        debbugs
        dired-hacks-utils
        dired-subtree
        docker
        editorconfig
        eglot
        eldoc
        elfeed
        elfeed-tube
        elfeed-tube-mpv
        embark
        embark-consult
        emms
        envrc
        exec-path-from-shell
        forge
        graphql-ts-mode
        hide-mode-line
        marginalia
        markdown-mode
        modus-themes
        mpv
        mixed-pitch
        nerd-icons
        nerd-icons-dired
        nerd-icons-corfu
        no-littering
        nix-mode
        nix-ts-mode
        lsp-mode
        ob-php
        olivetti
        orderless
        org-modern
        org-roam
        org-roam-ui
        org-web-tools
        package-lint
        paredit
        pdf-tools
        php-mode
        phpunit
        psysh
        rainbow-mode
        rainbow-delimiters
        rg
        rustic
        spacious-padding
        sxhkdrc-mode
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
        vertico
        yasnippet
        yasnippet-capf
        web-mode
        yaml-mode
        uuidgen
        pkgs.claude-code-ide
        vterm
      ]
    )
  );

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
