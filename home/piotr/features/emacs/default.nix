{
  pkgs,
  config,
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

  xdg.configFile."emacs/load-path.el".source = pkgs.writeText "load-path.el" ''
    (let ((default-directory (file-name-as-directory
                           "${config.programs.emacs.finalPackage.deps}/share/emacs/site-lisp/"))
          (normal-top-level-add-subdirs-inode-list nil))
    (normal-top-level-add-subdirs-to-load-path))
  '';

  programs.emacs.enable = true;
  programs.emacs.package = (
    (pkgs.unstable.emacsPackagesFor pkgs.unstable.emacs30).emacsWithPackages (
      epkgs: with epkgs; [
        async
        bats-mode
        cape
        csv-mode
        compat
        composer
        consult
        consult-yasnippet
        copilot
        corfu
        dap-mode
        debbugs
        diminish
        dired-hacks-utils
        dired-preview
        dired-subtree
        direnv
        docker
        doom-modeline
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
        notmuch
        nix-mode
        nix-ts-mode
        lsp-mode
        ob-php
        olivetti
        orderless
        org-modern
        org-present
        org-roam
        org-roam-ui
        org-transclusion
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
          pkgs.tree-sitter-phpdoc
        ]))
        vertico
        yasnippet
        yasnippet-capf
        web-mode
        yaml-mode
        uuidgen
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
