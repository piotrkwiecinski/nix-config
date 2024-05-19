{
  inputs,
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
    mermaid-cli
    rust-analyzer
    rustc
    rustfmt
    nil
    phpactor
  ];

  xdg.configFile."emacs/load-path.el".source = pkgs.writeText "load-path.el" ''
    (let ((default-directory (file-name-as-directory
                           "${config.programs.emacs.finalPackage.deps}/share/emacs/site-lisp/"))
          (normal-top-level-add-subdirs-inode-list nil))
    (normal-top-level-add-subdirs-to-load-path))
  '';

  programs.emacs = {
    enable = true;

    package = pkgs.unstable.emacs29-pgtk;

    overrides = _self: _super: {
      copilot =
        let
          rev = inputs.copilot-el.shortRev;
        in
        with pkgs;
        with pkgs.emacsPackages;
        melpaBuild {
          pname = "copilot";
          ename = "copilot";
          version = inputs.copilot-el.lastModifiedDate;
          commit = rev;
          packageRequires = [
            dash
            editorconfig
            s
            jsonrpc
          ];

          src = fetchFromGitHub {
            inherit rev;
            owner = "copilot-emacs";
            repo = "copilot.el";
            sha256 = inputs.copilot-el.narHash;
          };

          recipe = writeText "recipe" ''
            (copilot
            :repo "copilot-emacs/copilot.el"
            :fetcher github
            :files ("*.el" "dist"))
          '';

          meta.description = "Emacs plugin for GitHub Copilot";
        };
    };

    extraPackages = (
      epkgs:
      (with epkgs; [
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
        ob-mermaid
        olivetti
        orderless
        org-modern
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
          ts.tree-sitter-python
          ts.tree-sitter-rust
          ts.tree-sitter-toml
          ts.tree-sitter-tsx
          ts.tree-sitter-typescript
          ts.tree-sitter-yaml
        ]))
        vertico
        yasnippet
        yasnippet-capf
        web-mode
        yaml-mode
        uuidgen
        vterm
      ])
    );
  };

  services.emacs = {
    enable = true;

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
