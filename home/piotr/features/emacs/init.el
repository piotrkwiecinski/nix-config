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
  (completion-category-overrides '((file (styles . (partial-completion)))
                                   (eglot (styles . (orderless)))
                                   (eglot-capf (styles . (orderless))))))

(use-package yasnippet-capf
  :after yasnippet)

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-abbrev)
  (add-to-list 'completion-at-point-functions #'yasnippet-capf)
  (add-to-list 'completion-at-point-functions #'cape-elisp-symbol)
  (setq completion-at-point-functions
        (remove 'ispell-completion-at-point completion-at-point-functions))
  ;; Emacs 30 text-mode adds ispell-completion-at-point buffer-locally;
  ;; it errors without a plain word-list (ispell-alternate-dictionary).
  (setq text-mode-ispell-word-completion nil))

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
  ;; Only jump to errors, not cargo warnings.
  (compilation-skip-threshold 2)
  (compilation-scroll-output t))

(use-package ansi-color
  :hook (compilation-filter . ansi-color-compilation-filter))

(use-package term
  :hook (term-mode . compilation-shell-minor-mode))

(use-package olivetti
  :bind (("C-c t o" . olivetti-mode))
  :custom
  (olivetti-body-width 120)
  :hook ((elfeed-show-mode . olivetti-mode)
         (olivetti-mode . hide-mode-line-mode)))

(use-package hide-mode-line
  :hook (elfeed-show-mode . hide-mode-line-mode))

(use-package org-present
  :commands org-present
  :hook ((org-present-mode . (lambda ()
                               (setq-local face-remapping-alist
                                           '((default (:height 1.15) default)
                                             (header-line (:height 2.0) variable-pitch)
                                             (org-document-title (:height 1.0) org-document-title)
                                             (org-level-1 (:height 1.0) org-level-1)))
                               (org-present-big)
                               (org-present-hide-cursor)
                               (org-present-read-only)
                               (olivetti-mode 1)
                               (hide-mode-line-mode 1)))
         (org-present-mode-quit . (lambda ()
                                    (setq-local face-remapping-alist nil)
                                    (org-present-small)
                                    (org-present-show-cursor)
                                    (setq-local cursor-type t)
                                    (org-present-read-write)
                                    (olivetti-mode -1)
                                    (hide-mode-line-mode -1)))))

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
  (load-theme 'modus-vivendi :no-confirm)
  (defun pk--apply-ui-padding ()
    "Apply padding to mode-line and tab-bar faces based on current theme colors."
    (let ((ml-active-bg (face-attribute 'mode-line :background nil t))
          (ml-inactive-bg (face-attribute 'mode-line-inactive :background nil t))
          (bar-bg (face-attribute 'tab-bar :background (selected-frame)))
          (tab-active-bg (face-attribute 'tab-bar-tab :background (selected-frame)))
          (tab-inactive-bg (face-attribute 'tab-bar-tab-inactive :background (selected-frame))))
      (set-face-attribute 'mode-line-active nil
                          :box (list :line-width '(5 . 5) :color ml-active-bg)
                          :height 1.0)
      (set-face-attribute 'mode-line-inactive nil
                          :box (list :line-width '(5 . 5) :color ml-inactive-bg)
                          :height 1.0)
      (set-face-attribute 'tab-bar nil :box (list :line-width '(5 . 5) :color bar-bg))
      (set-face-attribute 'tab-bar-tab nil :box (list :line-width '(10 . 5) :color tab-active-bg))
      (set-face-attribute 'tab-bar-tab-inactive nil :box (list :line-width '(10 . 5) :color tab-inactive-bg))))
  (add-hook 'server-after-make-frame-hook #'pk--apply-ui-padding)
  (unless (daemonp) (pk--apply-ui-padding)))

(setq-default line-prefix (propertize " " 'display '(space :width (15))))
(use-package vterm
  :commands (vterm vterm-other-window)
  :hook (vterm-mode . pk--disable-line-prefix)
  :init
  (defun pk--disable-line-prefix ()
    "Disable line-prefix in terminal buffers."
    (setq-local line-prefix nil))
  (defun vterm-project ()
    "Open a vterm buffer in the current project's root directory."
    (interactive)
    (defvar vterm-buffer-name)
    (let* ((default-directory (project-root (project-current t)))
           (vterm-buffer-name (project-prefixed-buffer-name "vterm"))
           (vterm-buffer (get-buffer vterm-buffer-name)))
      (if (and vterm-buffer (not current-prefix-arg))
          (pop-to-buffer vterm-buffer (bound-and-true-p display-comint-buffer-action))
        (vterm-other-window t))))
  (with-eval-after-load 'project
    (add-to-list 'project-switch-commands '(vterm-project "vterm" "t") t)
    (keymap-set project-prefix-map "t" #'vterm-project)))

(use-package ghostel
  :commands (ghostel ghostel-project))

(use-package tab-bar
  :custom
  (tab-bar-close-button-show nil)
  (tab-bar-separator " ")
  (tab-bar-format '(tab-bar-format-history tab-bar-separator tab-bar-format-tabs))
  (tab-bar-tab-name-format-function
   (lambda (tab _i)
     (propertize (concat " " (alist-get 'name tab))
                 'face (if (eq (car tab) 'current-tab)
                           'tab-bar-tab
                         'tab-bar-tab-inactive)))))

(use-package nerd-icons
  :config
  (if (daemonp)
      (add-hook 'server-after-make-frame-hook #'nerd-icons-set-font)
    (nerd-icons-set-font)))

;;;; Mode line
(defun pk-modeline--major-mode-icon ()
  "Return a nerd-icon for the current major mode."
  (let ((icon (nerd-icons-icon-for-mode major-mode)))
    (if (stringp icon) (concat icon " ") "")))

(defun pk-modeline--right-align (right)
  "Return a space string that right-aligns RIGHT in the mode line."
  (let ((rlen (string-width (format-mode-line right))))
    (propertize " " 'display `(space :align-to (- right ,rlen)))))

(defun pk-modeline--vc-branch ()
  "Return the current VC branch name, or empty string if detached/not tracked."
  (when-let* ((vc vc-mode)
              (branch (substring-no-properties vc))
              ((string-match "^ Git[:-]\\(.+\\)" branch)))
    (let ((name (match-string 1 branch)))
      (unless (string-match-p "\\`[0-9a-f]\\{7,\\}\\'" name)
        (concat " " (nerd-icons-octicon "nf-oct-git_branch") " " name)))))

(defvar pk-modeline--right-segment
  '("" (:eval (pk-modeline--vc-branch)) "  %l:%c"))

(setq-default mode-line-format
              '(" "
                (:eval (pk-modeline--major-mode-icon))
                "%b"
                (:eval (pk-modeline--right-align pk-modeline--right-segment))
                (:eval (pk-modeline--vc-branch))
                "  %l:%c "))
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

(use-package flymake
  :bind (:map flymake-mode-map
         ("M-n" . flymake-goto-next-error)
         ("M-p" . flymake-goto-prev-error)))

(use-package eldoc
  :hook (prog-mode . eldoc-mode))

;; rust-analyzer replies are large; the 64k default means many reads per message.
(setq read-process-output-max (* 1024 1024))

(use-package eglot
  :bind (:map eglot-mode-map
         ("C-c l r" . eglot-rename)
         ("C-c l a" . eglot-code-actions)
         ("C-c l q" . eglot-code-action-quickfix)
         ("C-c l o" . eglot-code-action-organize-imports)
         ("C-c l f" . eglot-format-buffer)
         ("C-c l i" . eglot-find-implementation)
         ("C-c l t" . eglot-find-typeDefinition)
         ("C-c l d" . flymake-show-buffer-diagnostics)
         ("C-c l D" . flymake-show-project-diagnostics)
         ("C-c l h" . eglot-inlay-hints-mode)
         ("C-c l R" . eglot-reconnect))
  :custom
  ;; Logging every JSON-RPC message from rust-analyzer is expensive.
  (eglot-events-buffer-config '(:size 0 :format full))
  ;; rust-analyzer is memory hungry; stop it when the last buffer goes.
  (eglot-autoshutdown t)
  ;; Jumping into ~/.cargo/registry or rust-src keeps the project's server.
  (eglot-extend-to-xref t)
  :config
  (add-to-list 'eglot-server-programs '(nix-mode . ("nil")))
  (add-to-list 'eglot-server-programs '((rust-ts-mode rust-mode) . ("rust-analyzer")))
  (add-to-list 'eglot-server-programs '(toml-ts-mode . ("taplo" "lsp" "stdio")))
  ;; Sent via workspace/configuration so projects can override in .dir-locals.el:
  ;; ((rust-ts-mode . ((eglot-workspace-configuration
  ;;                    . (:rust-analyzer (:cargo (:features ["foo"]))))))
  (setq-default eglot-workspace-configuration
                '(:rust-analyzer
                  (:check (:command "clippy")
                   :procMacro (:enable t
                               :attributes (:enable t))
                   :cargo (:buildScripts (:enable t)
                           :features "all"
                           ;; Own target dir: no cargo lock contention with
                           ;; builds/tests run from compile or a terminal.
                           :targetDir t)
                   :inlayHints (:bindingModeHints (:enable t)
                                :closingBraceHints (:minLines 20)
                                :closureReturnTypeHints (:enable "with_block")
                                :lifetimeElisionHints (:enable "skip_trivial")))))
  ;; Fresh candidates from the server on every keystroke (Corfu wiki).
  (advice-add 'eglot-completion-at-point :around #'cape-wrap-buster)
  :hook (eglot-managed-mode . eglot-inlay-hints-mode))

;; Wraps rust-analyzer's stdio in emacs-lsp-booster (JSON -> bytecode, buffered I/O).
(use-package eglot-booster
  :after eglot
  :config
  (eglot-booster-mode 1))

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
  :custom
  ;; Block at most 2s waiting for direnv, then continue asynchronously,
  ;; so sentinels can't pile up inside a long wait.
  (envrc-async 2)
  ;; Never run direnv in debugger buffers (avoids repeating the hang on C-g / USR2).
  (envrc-global-modes '((not debugger-mode) t))
  :init
  (envrc-global-mode)
  :config
  ;; When direnv outlives `envrc-async', eglot-ensure has already run without
  ;; the devshell PATH (no global rust-analyzer/nil), so start it once the
  ;; environment lands.  envrc has no public hook for this.
  (defun pk--envrc-eglot-ensure (buf _result)
    (when (buffer-live-p buf)
      (with-current-buffer buf
        (when (and (derived-mode-p 'rust-ts-mode 'nix-mode 'toml-ts-mode)
                   (fboundp 'eglot-current-server)
                   (not (eglot-current-server)))
          (eglot-ensure)))))
  (advice-add 'envrc--apply :after #'pk--envrc-eglot-ensure))

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

(use-package dape
  :custom
  (dape-buffer-window-arrangement 'right)
  :config
  (defun pk--cargo-executables (&rest args)
    "Run cargo ARGS with JSON output; return alist of (LABEL . EXECUTABLE)."
    (message "Running cargo %s..." (string-join args " "))
    ;; Carry the buffer's direnv environment into the temp buffer.
    (inheritenv (with-temp-buffer
                  (unless (zerop (apply #'process-file "cargo" nil '(t nil) nil
                                        (append args '("--message-format=json"))))
                    (user-error "cargo %s failed; run it in a terminal for details"
                                (string-join args " ")))
                  (goto-char (point-min))
                  (let (result)
                    (while (not (eobp))
                      (let ((msg (ignore-errors
                                   (json-parse-string
                                    (buffer-substring (point) (line-end-position))
                                    :object-type 'alist :null-object nil))))
                        (when-let* (((equal (alist-get 'reason msg) "compiler-artifact"))
                                    (exe (alist-get 'executable msg))
                                    (target (alist-get 'target msg)))
                          (push (cons (format "%s (%s%s)" (alist-get 'name target)
                                              (string-join (alist-get 'kind target) ",")
                                              ;; `cargo test` also emits a bin's unit-test harness.
                                              (if (and (eq (alist-get 'test (alist-get 'profile msg)) t)
                                                       (not (seq-contains-p (alist-get 'kind target) "test")))
                                                  " unittests" ""))
                                      exe)
                                result)))
                      (forward-line 1))
                    (nreverse result)))))

  (defun pk--cargo-pick-executable (&rest args)
    "Build with cargo ARGS and pick one of the produced executables."
    (let ((exes (or (apply #'pk--cargo-executables args)
                    (user-error "cargo %s produced no executables"
                                (string-join args " ")))))
      (if (cdr exes)
          (cdr (assoc (completing-read "Debug: " exes nil t) exes))
        (cdar exes))))

  (defun pk--rust-lldb-init-commands ()
    "lldb commands loading rustc's pretty-printers for Vec, String, Option, ..."
    (let* ((sysroot (string-trim (shell-command-to-string "rustc --print sysroot")))
           (etc (expand-file-name "lib/rustlib/etc" sysroot))
           (lookup (expand-file-name "lldb_lookup.py" etc))
           ;; Older toolchains register types from a separate commands file.
           (commands (expand-file-name "lldb_commands" etc)))
      (vconcat
       (when (file-exists-p lookup)
         (list (format "command script import %s" (shell-quote-argument lookup))))
       (when (file-exists-p commands)
         (list (format "command source -s 0 %s" (shell-quote-argument commands)))))))

  (let ((rust-common
         `(modes (rust-ts-mode rust-mode)
           ensure dape-ensure-command
           command "lldb-dap"
           command-cwd dape-command-cwd
           :type "lldb-dap"
           :cwd dape-command-cwd
           :initCommands pk--rust-lldb-init-commands)))
    (add-to-list 'dape-configs
                 `(rust-lldb-test
                   ,@rust-common
                   :program (lambda () (pk--cargo-pick-executable "test" "--no-run"))))
    (add-to-list 'dape-configs
                 `(rust-lldb
                   ,@rust-common
                   :program (lambda () (pk--cargo-pick-executable "build" "--bins"))))))

(use-package dap-mode
  :config
  (dap-auto-configure-mode))

(use-package dap-php
  :after dap-mode
  :custom
  (dap-php-debug-path (locate-user-emacs-file "dap-php-debug"))
  (dap-php-debug-program `("node" ,(expand-file-name "out/phpDebug.js"
                                                      (locate-user-emacs-file "dap-php-debug"))))
  :config
  (dap-register-debug-template "PHP Listen for Xdebug"
                               (list :type "php"
                                     :request "launch"
                                     :name "PHP Listen for Xdebug"
                                     :port 9003
                                     :stopOnEntry nil)))

(defun project-environment-command (command)
  "Run project environment related command."
  (interactive "sEnter command: ")
  (let ((default-directory (project-root (project-current t))))
    (async-shell-command (concat "~/bin/dm " command))))

;;;; Version control
(use-package magit
  :config
  ;; magit-refresh-buffer reads `hi-lock-mode' without loading hi-lock.
  (require 'hi-lock)
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

(use-package magento-cache-clean)

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

(use-package rust-ts-mode
  :mode "\\.rs\\'"
  :hook ((rust-ts-mode . eglot-ensure)
         (rust-ts-mode . pk--rust-format-on-save))
  :init
  ;; rustic's format-on-save only fires in rust-mode/rustic-mode; let
  ;; rust-analyzer run the devshell's rustfmt instead.
  (defun pk--rust-format-on-save ()
    (add-hook 'before-save-hook
              (lambda () (when (eglot-managed-p) (eglot-format-buffer)))
              nil t)))

;; Only for the cargo commands below (they inherit the direnv environment).
(use-package rustic
  :after rust-ts-mode
  :custom
  (rustic-lsp-client 'eglot)
  (rustic-lsp-setup-p nil)
  (rustic-cargo-use-last-stored-arguments t)
  :bind (:map rust-ts-mode-map
         ("C-c C-c t" . rustic-cargo-current-test)
         ("C-c C-c r" . rustic-cargo-run)
         ("C-c C-c b" . rustic-cargo-build)
         ("C-c C-c l" . rustic-cargo-clippy))
  :config
  (setq auto-mode-alist (delete '("\\.rs\\'" . rustic-mode) auto-mode-alist)))

;;;;; TOML

(use-package toml-ts-mode
  :if (treesit-available-p)
  :mode ("Cargo\\.toml\\'" "\\.toml\\'")
  :hook (toml-ts-mode . eglot-ensure))

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
  :init
  (pdf-loader-install)
  :custom
  (pdf-view-display-size 'fit-width)
  :hook (pdf-view-mode . pdf-view-midnight-minor-mode))

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
  :bind (("C-c o a" . org-agenda)
         ("C-c o c" . org-capture))
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
      :if (file-directory-p "~/projects/personal/second-brain/")
      :after org
      :custom
      (org-roam-directory (file-truename "~/projects/personal/second-brain/"))
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

(use-package activity-watch-mode
  :hook (after-init . global-activity-watch-mode))

(defcustom piotr/aw-server-url "http://homeserver:5600"
  "Base URL of the ActivityWatch aggregator."
  :type 'string :group 'piotr)

(defcustom piotr/aw-review-file
  "~/projects/personal/second-brain/activitywatch-reviews.org"
  "Org file where weekly ActivityWatch reviews are appended."
  :type 'file :group 'piotr)

(defun piotr/--aw-get-json (path)
  "GET PATH from the AW server and return parsed JSON."
  (let ((url-request-method "GET"))
    (with-current-buffer
        (url-retrieve-synchronously (concat piotr/aw-server-url path) t t 10)
      (goto-char (point-min))
      (re-search-forward "\n\n")
      (prog1 (json-parse-buffer :object-type 'alist :array-type 'list)
        (kill-buffer)))))

(defun piotr/--aw-bucket-events (bucket start end)
  "Fetch events from BUCKET between START and END ISO strings."
  (piotr/--aw-get-json
   (format "/api/0/buckets/%s/events?start=%s&end=%s&limit=-1"
           (url-hexify-string bucket)
           (url-hexify-string start)
           (url-hexify-string end))))

(defun piotr/--aw-aggregate (events key)
  "Aggregate EVENTS into ((KEY-value . total-seconds) ...) sorted desc."
  (let ((acc (make-hash-table :test 'equal)))
    (dolist (ev events)
      (let* ((data (alist-get 'data ev))
             (dur (or (alist-get 'duration ev) 0))
             (k (or (alist-get key data) "<unknown>")))
        (puthash k (+ dur (gethash k acc 0)) acc)))
    (sort (let (xs) (maphash (lambda (k v) (push (cons k v) xs)) acc) xs)
          (lambda (a b) (> (cdr a) (cdr b))))))

(defun piotr/--aw-format-table (title rows)
  "Render TITLE + ROWS (alist of label . seconds) as an org table string."
  (concat
   (format "** %s\n" title)
   "| Rank | Item | Hours |\n|------+------+-------|\n"
   (mapconcat
    (lambda (idx-row)
      (format "| %d | %s | %.2f |"
              (car idx-row)
              (replace-regexp-in-string "|" "\\\\vert" (car (cdr idx-row)))
              (/ (cdr (cdr idx-row)) 3600.0)))
    (let ((i 0))
      (mapcar (lambda (r) (setq i (1+ i)) (list i (car r) (cdr r)))
              (seq-take rows 20)))
    "\n")
   "\n"))

(defun piotr/aw-weekly-review ()
  "Fetch last 7 days of ActivityWatch data and append an org datetree entry."
  (interactive)
  (require 'org-datetree)
  (let* ((now (current-time))
         (end (format-time-string "%Y-%m-%dT%H:%M:%S+00:00" now t))
         (start (format-time-string "%Y-%m-%dT%H:%M:%S+00:00"
                                    (time-subtract now (days-to-time 7)) t))
         (buckets (mapcar #'symbol-name
                          (mapcar #'car (piotr/--aw-get-json "/api/0/buckets/"))))
         (win-buckets (seq-filter
                       (lambda (b) (string-prefix-p "aw-watcher-window_" b)) buckets))
         (web-buckets (seq-filter
                       (lambda (b) (string-prefix-p "aw-watcher-web_" b)) buckets))
         (win-events (apply #'append
                            (mapcar (lambda (b) (piotr/--aw-bucket-events b start end))
                                    win-buckets)))
         (web-events (apply #'append
                            (mapcar (lambda (b) (piotr/--aw-bucket-events b start end))
                                    web-buckets))))
    (find-file (expand-file-name piotr/aw-review-file))
    (org-datetree-find-date-create (calendar-current-date))
    (org-narrow-to-subtree)
    (goto-char (point-max))
    (insert "\n"
            (format "Window: %d events across %d buckets; Web: %d events across %d buckets.\n\n"
                    (length win-events) (length win-buckets)
                    (length web-events) (length web-buckets))
            (piotr/--aw-format-table "Top apps (last 7 days)"
                                     (piotr/--aw-aggregate win-events 'app))
            "\n"
            (piotr/--aw-format-table "Top domains (last 7 days)"
                                     (piotr/--aw-aggregate web-events 'domain)))
    (widen)
    (save-buffer)
    (message "AW weekly review updated: %s" piotr/aw-review-file)))

(keymap-global-set "C-c n r" #'piotr/aw-weekly-review)

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
  (require 'emms-player-mpd)
  (emms-all)
  (setq emms-player-list '(emms-player-mpd emms-player-mpv))
  (setq emms-player-mpd-server-name "homeserver.tailfbbc95.ts.net")
  (setq emms-player-mpd-server-port "6600")
  (setq emms-player-mpd-music-directory "/var/lib/music")
  (setq emms-info-functions '(emms-info-mpd)))

;;;; llm
(use-package claude-code-ide
  :bind ("C-c C-'" . claude-code-ide-menu)
  :config
  (claude-code-ide-emacs-tools-setup)
  (setq claude-code-ide-terminal-backend 'ghostel)

  (defun my/claude-code-propagate-envrc (orig-fun &rest args)
    "Propagate envrc environment variables to Claude Code terminal sessions."
    (let* ((envrc-env (when (bound-and-true-p envrc--status)
                        (cl-set-difference
                         (buffer-local-value 'process-environment (current-buffer))
                         (default-value 'process-environment)
                         :test #'string=)))
           ;; For vterm: add to vterm-environment (dynamically scoped)
           (vterm-environment (append envrc-env (when (boundp 'vterm-environment)
                                                  vterm-environment)))
           ;; For eat: add to process-environment
           (process-environment (append envrc-env process-environment)))
      (apply orig-fun args)))

  (advice-add 'claude-code-ide--create-terminal-session
              :around #'my/claude-code-propagate-envrc)

  (defun my/claude-code-session-name (dir)
    "Stable session name for DIR: its basename, or parent-basename when generic."
    (let* ((dir (directory-file-name (expand-file-name dir)))
           (base (file-name-nondirectory dir)))
      (if (member base '("db" "src" "app" "web" "cli"))
          (concat (file-name-nondirectory (directory-file-name (file-name-directory dir)))
                  "-" base)
        base)))

  (defun my/claude-code-name-session (orig-fun buffer-name working-dir &rest args)
    "Start Claude Code with `-n <project>' so other sessions can @-address it."
    (let ((claude-code-ide-cli-extra-flags
           (string-trim
            (concat claude-code-ide-cli-extra-flags " -n "
                    (shell-quote-argument (my/claude-code-session-name working-dir))))))
      (apply orig-fun buffer-name working-dir args)))

  (advice-add 'claude-code-ide--create-terminal-session
              :around #'my/claude-code-name-session)

  (defun my/claude-code--background-sessions ()
    "Alist of (LABEL . SESSION) for background sessions from `claude agents'."
    (let* ((json (with-temp-buffer
                   (unless (zerop (call-process "claude" nil t nil "agents" "--json"))
                     (user-error "claude agents --json failed: %s" (buffer-string)))
                   (goto-char (point-min))
                   (json-parse-buffer :object-type 'alist :null-object nil)))
           (sessions (seq-filter (lambda (s)
                                   (and (equal (alist-get 'kind s) "background")
                                        (alist-get 'id s)))
                                 json)))
      (mapcar (lambda (s)
                (cons (format "%-24s %-8s %s"
                              (alist-get 'name s)
                              (or (alist-get 'state s) "")
                              (abbreviate-file-name (alist-get 'cwd s)))
                      s))
              sessions)))

  (defun my/claude-code-attach (session)
    "Attach to a background Claude Code SESSION in a ghostel side window.
The session keeps running when the buffer is killed; `claude agents'
still lists it."
    (interactive
     (let ((choices (or (my/claude-code--background-sessions)
                        (user-error "No background Claude sessions"))))
       (list (cdr (assoc (completing-read "Attach to: " choices nil t) choices)))))
    (let* ((id (alist-get 'id session))
           (name (format "*claude-attach[%s]*" (alist-get 'name session)))
           (buffer (get-buffer name)))
      (unless (and buffer (get-buffer-process buffer))
        (setq buffer (get-buffer-create name))
        (with-current-buffer buffer
          (setq default-directory (file-name-as-directory (alist-get 'cwd session))))
        ;; Display first so ghostel sizes the terminal to the window.
        (claude-code-ide--display-buffer-in-side-window buffer)
        (ghostel-exec buffer "claude" (list "attach" id)))
      (claude-code-ide--display-buffer-in-side-window buffer)))

  (with-eval-after-load 'claude-code-ide-transient
    (transient-append-suffix 'claude-code-ide-menu "l"
      '("a" "Attach to background session" my/claude-code-attach))))

(use-package claude-code-ide-companion
  :config
  (claude-code-ide-companion-project-switch-mode 1))

(use-package pilish
  :commands (pilish pilish-toggle pilish-session-browser)
  :bind ("C-c C-;" . pilish)
  :config
  (defalias 'pi 'pilish))

(use-package abbrev
  :hook ((prog-mode text-mode) . abbrev-mode))

(use-package work
  :load-path "lisp-private")
