;;; init.el -*- lexical-binding: t; -*-
(add-to-list 'load-path (locate-user-emacs-file "lisp"))
(add-to-list 'load-path (locate-user-emacs-file "lisp-private"))

(use-package emacs
  :custom
  (native-comp-async-report-warnings-errors 'silent)
  (delete-by-moving-to-trash t)
  (use-short-answers t)
  (use-file-dialog nil)
  (use-dialog-box nil)
  (tab-always-indent 'complete))

(defgroup pk-emacs nil
  "User options for my dotemacs."
  :group 'file)

(setq user-full-name "Piotr Kwiecinski")

(use-package exec-path-from-shell
  :config
  (exec-path-from-shell-initialize))

(use-package recentf
  :custom
  (recentf-exclude '(".gz" ".xz" ".zip" "/elpa/" "/ssh:" "/sudo:"))
  (recentf-max-saved-items 1000)
  :hook (after-init . recentf-mode))

;;; Defaults
(use-package autorevert
  :custom
  (global-auto-revert-non-file-buffers t)
  :init
  (global-auto-revert-mode 1))

;; Use spaces instead of tabs
(setq-default indent-tabs-mode nil)

(setq ring-bell-function 'ignore)

;; Make shebang (#!) file executable when saved
(add-hook 'after-save-hook #'executable-make-buffer-file-executable-if-script-p)

(use-package savehist
  :custom
  (history-delete-duplicates t)
  :init
  (savehist-mode 1))

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(setq initial-scratch-message nil)

(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

;;; File management
(use-package dired
  :custom
  (dired-listing-switches "-agFv --group-directories-first")
  (dired-dwim-target #'dired-dwim-target-next)
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'always)
  (dired-auto-revert-buffer t)
  :hook (dired-mode . dired-hide-details-mode))

(use-package dired-x
  :after dired)

(use-package dired-subtree
  :after dired
  :bind (:map dired-mode-map
              ("<tab>" . dired-subtree-toggle)))

(use-package no-littering
  :config
  (require 'recentf)
  (add-to-list 'recentf-exclude
               (recentf-expand-file-name no-littering-var-directory))
  (add-to-list 'recentf-exclude
               (recentf-expand-file-name no-littering-etc-directory))
  (no-littering-theme-backups))

(use-package files
  :custom
  (backup-by-copying t)
  (delete-old-versions t)
  (kept-new-versions 6)
  (kept-old-versions 2)
  (version-control t))

(use-package bookmark
  :custom
  (bookmark-save-flag 1))

;;; Completion
(defvar xref-show-xrefs-function)
(defvar xref-show-definitions-function)

(use-package consult
  :bind (("C-x M-:" . consult-complex-command)
         ("C-x b" . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("C-x 5 b" . consult-buffer-other-frame)
         ("C-x r b" . consult-bookmark)
         ("C-x p b" . consult-project-buffer)
         ([remap Info-search] . consult-info)
         ("M-y" . consult-yank-pop)
         ("M-g g" . consult-goto-line)
         ("M-g M-g" . consult-goto-line)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi))
  :config
  (setq consult-line-numbers-widen t)
  (setq completion-in-region-function #'consult-completion-in-region)
  (setq consult-narrow-key "<")
  (with-eval-after-load 'xref
    (setq xref-show-xrefs-function #'consult-xref
          xref-show-definitions-function #'consult-xref)))

(use-package embark)

(use-package embark-consult
  :after (embark consult))

(use-package corfu
  :bind (:map corfu-map
         ("C-j" . corfu-next)
         ("C-k" . corfu-previous)
         ("TAB" . corfu-insert)
         ("RET" . nil))
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  :init
  (global-corfu-mode)
  (global-set-key (kbd "M-i") #'completion-at-point))

(use-package vertico
  :custom
  (vertico-cycle t)
  :init
  (vertico-mode 1))

(use-package vertico-directory
  :after vertico)

(use-package marginalia
  :custom
  (marginalia-annotators '(marginalia-annotators-heavy marginalia-annotators-light nil))
  :init
  (marginalia-mode 1))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles . (partial-completion))))))

(use-package yasnippet-capf
  :after yasnippet)

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-abbrev)
  (add-to-list 'completion-at-point-functions #'yasnippet-capf)
  (add-to-list 'completion-at-point-functions #'cape-elisp-symbol))

;;; User interface
(set-face-attribute 'default nil
                    :font "Fira Code"
                    :weight 'normal
                    :height 120)

(set-face-attribute 'variable-pitch nil :font "DejaVu Sans")

(add-to-list 'display-buffer-alist
             '("\\*Help\\*"
               (display-buffer-reuse-window display-buffer-pop-up-window)))

(add-to-list 'display-buffer-alist
             '("\\*Completions\\*"
               (display-buffer-reuse-window display-buffer-pop-up-window)
               (inhibit-same-window . t)
               (window-height . 12)))

(setq display-buffer-base-action
      '(display-buffer-reuse-mode-window
        display-buffer-reuse-window
        display-buffer-same-window))

;;;; Show dictionary definition on the left
(add-to-list 'display-buffer-alist
             '("^\\*Dictionary\\*"
               (display-buffer-in-side-window)
               (side . left)
               (window-width . 70)))

(add-to-list 'display-buffer-alist
             '("\\*compilation\\*"
               (display-buffer-reuse-window
                display-buffer-in-side-window)
               (window-height . 0.3)
               (side . bottom)))

;;;; Compilation buffer
(use-package compile
  :custom
  (compilation-auto-jump-to-first-error t)
  (compilation-scroll-output t))

(use-package ansi-color
  :hook (compilation-filter . ansi-color-compilation-filter))

(use-package term
  :hook (term-mode . compilation-shell-minor-mode))

(use-package spacious-padding
  :custom
  (spacious-padding-widths  '(:internal-border-width 50
                              :right-divider-width 0
                              :scroll-bar-width 0))
  :config
  (spacious-padding-mode t))

(defun my-modeline-style (&optional _theme)
  "Subtle modeline style"
  (let ((subtle (face-foreground 'shadow)))
    (custom-set-faces
     `(mode-line ((t :background unspecified :box ,subtle)))
     `(mode-line-inactive ((t :background unspecified :foreground ,subtle :box ,subtle))))))

(add-hook 'after-make-frame-functions #'my-modeline-style)

(add-hook 'enable-theme-functions #'my-modeline-style)

(add-hook 'window-setup-hook #'my-modeline-style)

(use-package olivetti
  :bind (("C-c t o" . olivetti-mode))
  :custom
  (olivetti-body-width 120)
  :hook ((elfeed-show-mode . olivetti-mode)
         (olivetti-mode . hide-mode-line-mode)))

(use-package hide-mode-line
  :hook (elfeed-show-mode . hide-mode-line-mode))

(setq-default line-spacing 5)

(use-package modus-themes
  :bind (("C-c t t" . modus-themes-toggle))
  :custom
  (modus-themes-mixed-fonts t)
  (modus-themes-variable-pitch-ui t)
  (modus-themes-headings '((0 . (variable-pitch 1.9))
          (1 . (variable-pitch 1.8))
          (2 . (variable-pitch 1.7))
          (3 . (variable-pitch 1.6))
          (4 . (variable-pitch 1.5))
          (5 . (variable-pitch 1.4)) ; absence of weight means `bold'
          (6 . (variable-pitch 1.3))
          (7 . (variable-pitch 1.2))))
  :init
  (load-theme 'modus-vivendi :no-confirm))

(use-package nerd-icons)
(use-package nerd-icons-corfu
  :after (nerd-icons corfu)
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(use-package nerd-icons-dired
  :hook
  (dired-mode . nerd-icons-dired-mode))

;;; IDE

(use-package prog-mode
  :hook ((prog-mode . column-number-mode)
         (prog-mode . display-line-numbers-mode)))

(use-package eldoc
  :hook (prog-mode . eldoc-mode))

(use-package eglot
  :config
  (add-to-list 'eglot-server-programs '(nix-mode . ("nil"))))

(use-package editorconfig
  :hook (prog-mode . editorconfig-mode))

(use-package autoinsert
  :custom
  (auto-insert-query nil)
  :init
  (auto-insert-mode 1))

(use-package yasnippet
  :custom
  (yas-new-snippet-default "\
# -*- mode: snippet -*-
# uuid: `(uuidgen-4)`
# name: $1
# key: ${2:${1:$(yas--key-from-desc yas-text)}}
# --
$0`(yas-escape-text yas-selected-text)`")
  :config
  (yas-global-mode t)
  (yas-reload-all))

(use-package uuidgen)

(defun autoinsert-yas-expand()
  "Replace text in yasnippet template."
  (yas-expand-snippet (buffer-string) (point-min) (point-max)))

(use-package envrc
  :init
  (envrc-global-mode))

(use-package rainbow-mode)

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode)
  :custom
  (rainbow-delimiters-max-face-count 6))

(use-package lsp-mode
  :commands (lsp lsp-deferred)
  :custom
  (lsp-completion-provider :none)
  (lsp-phpactor-path nil)
  (lsp-clients-php-server-command "phpactor")
  (lsp-headerline-breadcrumb-mode nil)
  :init
  (defun my/orderless-dispatch-flex-first (_pattern index _total)
    (and (eq index 0) 'orderless-flex))

  (defun my/lsp-mode-setup-completion ()
    (setf (alist-get 'styles (alist-get 'lsp-capf completion-category-defaults))
          '(orderless)))
   (add-hook 'orderless-style-dispatchers #'my/orderless-dispatch-flex-first nil 'local)

   (setq-local completion-at-point-functions (list (cape-capf-buster #'lsp-completion-at-point)))

   :hook (lsp-completion-mode . my/lsp-mode-setup-completion)
   :hook (php-ts-mode . lsp-deferred))

(use-package dap-mode)

(defun project-environment-command (command)
  "Run project environment related command."
  (interactive "sEnter command: ")
  (let ((default-directory (project-root (project-current t))))
    (async-shell-command (concat "~/bin/dm " command))))

;;;; Version control
(use-package magit
  :custom
  (magit-log-section-commit-count 10)
  (magit-reflog-limit 64)
  (magit-status-sections-hook
   '(magit-insert-status-headers
     magit-insert-merge-log
     magit-insert-rebase-sequence
     magit-insert-am-sequence
     magit-insert-sequencer-sequence
     magit-insert-bisect-output
     magit-insert-bisect-rest
     magit-insert-bisect-log
     magit-insert-untracked-files
     magit-insert-unstaged-changes
     magit-insert-staged-changes
     magit-insert-unpushed-to-pushremote
     magit-insert-unpushed-to-upstream-or-recent)))

(use-package ediff
  :custom
  (ediff-split-window-function 'split-window-horizontally)
  (ediff-window-setup-function 'ediff-setup-windows-plain))

;;;;; GitHub
(use-package forge
  :after magit)

;;;; Programming languages
(use-package paredit
  :hook ((emacs-lisp-mode . paredit-mode)
         (scheme-mode . paredit-mode)))

;;;;; Bash

(use-package bats-mode)

;;;;; Elisp

(use-package package-lint)

;;;;; Nix

(use-package nix-mode
  :mode "\\.nix\\'"
  :hook (nix-mode . eglot-ensure))

;;;;; PHP

(use-package php-mode)

(use-package php-ts-mode
  :if (treesit-available-p))

(use-package magento2-yasnippets
  :if (file-directory-p "~/projects/opensource/magento2-yasnippets")
  :load-path "~/projects/opensource/magento2-yasnippets"
  :after yasnippet
  :config
  (auto-insert-mode 1)
  (let ((di-template (concat magento2-yasnippets-templates-dir "xml/di.xml")))
    (add-to-list 'auto-insert-alist
                 `(("etc/\\(?:adminhtml/\\|frontend/\\|crontab/\\)?di\\.xml\\'" . "Magento 2 di.xml") . [,di-template  autoinsert-yas-expand])))
  (add-to-list 'auto-insert-alist
               '(("etc/module\\.xml\\'" . "Magento 2 module.xml") . ["magento/module.xml" autoinsert-yas-expand]))
  (add-to-list 'auto-insert-alist '(("\\.php\\'" . "PHP class") . "skeleton.php")))

(use-package composer)

(defun php-types ()
  "PHP types."
  '("string" "void" "array" "int" "float" "bool"))

(use-package magento2-cli
  :bind (("C-c m 2" . magento2-cli))
  :if (file-directory-p "~/projects/opensource/magento2-cli.el/")
  :load-path "~/projects/opensource/magento2-cli.el/")

(use-package magento-cloud
  :bind (("C-c m c" . magento-cloud-dispatch))
  :if (file-directory-p "~/projects/opensource/magento-cloud.el/")
  :load-path "~/projects/opensource/magento-cloud.el/")

(use-package psysh)

;;;;; Rust

(use-package rustic
  :custom
  (rustic-lsp-client 'eglot)
  (rustic-analyzer-command "rust-analyzer"))

;;;;; Web
(use-package web-mode
  :mode "\\.phtml\\'"
  :config
  (add-to-list 'web-mode-engines-alist '("php" . "\\.phtml\\'")))

;;;;; XML
(use-package nxml-mode)

;;;;; YAML

(use-package yaml-mode)

;;;;; Markdown

(use-package markdown-mode
  :custom
  (markdown-command "pandoc")
  (markdown-xhtml-header-content
   "<script type=\"module\">
import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
mermaid.initialize({ startOnLoad: false });
document.addEventListener('DOMContentLoaded', () => {
  for (const code of document.querySelectorAll('code.language-mermaid, code.sourceCode.mermaid')) {
    const pre = document.createElement('pre');
    pre.className = 'mermaid';
    pre.textContent = code.textContent;
    const container = code.closest('.sourceCode') || code.parentElement;
    container.replaceWith(pre);
  }
  for (const pre of document.querySelectorAll('pre.mermaid')) {
    const code = pre.querySelector('code');
    if (code) pre.textContent = code.textContent;
  }
  mermaid.run();
});
</script>"))

;;; Tools

(use-package man
  :custom
  (Man-notify-method 'aggressive))

;;;; PDF

(use-package pdf-tools
  :custom
  (pdf-view-display-size fit-width)
  :hook (pdf-view-mode . pdf-view-midnight-minor-mode)
  :config
  (pdf-tools-install))

;;;; RSS

(defgroup pk-elfeed ()
  "Personal extensions for Elfeed."
  :group 'elfeed)

(defcustom pk-elfeed-feeds-file (concat user-emacs-directory "feeds.el")
  "Path to file with `elfeed-feeds'."
  :type 'string
  :group 'pk-elfeed)

(defvar elfeed-search-mode-map)
(defvar elfeed-show-mode-map)

(use-package elfeed
  :bind (("C-c e" . elfeed)
         :map elfeed-search-mode-map
         ("w" . elfeed-search-yank)
         ("g" . elfeed-update)
         ("G" . elfeed-search-update--force)
         :map elfeed-show-mode-map
         ("w" . elfeed-show-yank))
  :custom
  (elfeed-curl-max-connections 10)
  (elfeed-enclosure-default-dir "~/Downloads/")
  (elfeed-search-filter "@4-months-ago +unread")
  (elfeed-sort-order 'descending)
  (elfeed-search-clipboard-type 'CLIPBOARD)
  (elfeed-search-title-max-width 100)
  (elfeed-search-title-min-width 30)
  (elfeed-search-trailing-width 25)
  (elfeed-show-truncate-long-urls t)
  (elfeed-show-unique-buffers t)
  (elfeed-feeds
   (when (file-exists-p pk-elfeed-feeds-file)
     (with-temp-buffer
       (insert-file-contents pk-elfeed-feeds-file)
       (read (current-buffer)))))
  :hook
  (elfeed-search-mode . elfeed-update))

(use-package elfeed-tube
  :after (elfeed)
  :bind (:map elfeed-show-mode-map
              ("F" . elfeed-tube-fetch)
              ([remap save-buffer] . elfeed-tube-save)
              :map elfeed-search-mode-map
              ("F" . elfeed-tube-fetch)
              ([remap save-buffer] . elfeed-tube-save))
  :config
  (elfeed-tube-setup))

(use-package mpv)

(use-package elfeed-tube-mpv
  :bind (:map elfeed-search-mode-map
              ("v" . elfeed-tube-mpv)
              :map elfeed-show-mode-map
              ("v" . elfeed-tube-mpv)
              ("C-c C-f" . elfeed-tube-mpv-follow-mode)
              ("C-c C-w" . elfeed-tube-mpv-where))
  :after (elfeed elfeed-tube mpv))

;;; Personal information management
(use-package org
  :custom
  (org-return-follows-link t)
  (org-mouse-1-follows-link t)
  (org-src-preserve-indentation t)
  (org-confirm-babel-evaluate nil)
  (org-src-strip-leading-add-trailing-blank-lines t)
  (org-agenda-files (list org-directory))
  (org-agenda-include-diary t)
  (org-log-done t)
  (org-support-shift-select t)
  :bind (("C-c o a" . org-agenda))
  :config
  (require 'ob-js)
  (require 'ob-php)
  (require 'org-tempo)
  (mapc (lambda (template)
        (add-to-list 'org-structure-template-alist template))
        '(("el" . "src emacs-lisp")
          ("js" . "src js")
          ("json" . "src json")
          ("php" . "src php")
          ("py" . "src python")
          ("rust" . "src rust")
          ("sc" . "src scheme")
          ("sh" . "src sh")
          ("ts" . "src typescript")
          ("yaml" . "src yaml")))
  (let ((langs '((js . t)
                 (php . t)
                 (shell . t))))
    (dolist (lang langs)
      (add-to-list 'org-babel-load-languages lang)))
  (add-to-list 'org-babel-tangle-lang-exts '("js" . "js"))
  (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
  (require 'org-protocol))

(use-package org-roam
      :if (file-directory-p "~/projects/second-brain/")
      :after org
      :custom
      (org-roam-directory (file-truename "~/projects/second-brain/"))
      :bind (("C-c n l" . org-roam-buffer-toggle)
             ("C-c n f" . org-roam-node-find)
             ("C-c n g" . org-roam-graph)
             ("C-c n i" . org-roam-node-insert)
             ("C-c n c" . org-roam-capture)
             ("C-c n j" . org-roam-dailies-capture-today))
      :config
      (require 'org-roam-protocol)
      (org-roam-db-autosync-mode)
      (add-to-list 'display-buffer-alist
                   '("\\*org-roam\\*"
                     (display-buffer-in-side-window)
                     (side . right)
                     (slot . 0)
                     (window-width . 0.33)
                     (window-parameters . ((no-other-window . t)
                                           (no-delete-other-windows . t))))))

(use-package org-modern
  :hook (org-mode . org-modern-mode)
  :hook (org-agenda-finalize . org-modern-agenda))

(use-package websocket)

(use-package org-roam-ui
  :after (org-roam websocket))

;;;; Search

(use-package rg)

(use-package async
  :config
  (dired-async-mode 1)
  (async-bytecomp-package-mode 1))

;;;; CSV

(use-package csv-mode)

;;;; Look and feel

(use-package mixed-pitch
  :hook (text-mode . mixed-pitch-mode))

(use-package emms
  :config
  (require 'emms-setup)
  (emms-all)
  (setq emms-player-list '(emms-player-mpv)))

;;;; llm
(use-package claude-code-ide
  :bind ("C-c C-'" . claude-code-ide-menu)
  :config
  (claude-code-ide-emacs-tools-setup))

(use-package abbrev
  :hook ((prog-mode text-mode) . abbrev-mode))

(use-package work
  :load-path "lisp-private")
