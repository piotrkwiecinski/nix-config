;;; init.el -*- lexical-binding: t; -*-
(add-to-list 'load-path (locate-user-emacs-file "lisp"))
(add-to-list 'load-path (locate-user-emacs-file "lisp-private"))

;; Load on :bind/:hook/:commands/:mode autoloads; startup-critical packages use :demand.
(setq use-package-always-defer t)

(use-package emacs
  :ensure nil
  :custom
  (native-comp-async-report-warnings-errors 'silent)
  (delete-by-moving-to-trash t)
  (use-short-answers t)
  (use-file-dialog nil)
  (use-dialog-box nil)
  (tab-always-indent 'complete)
  :init
  (delete-selection-mode 1)
  (electric-pair-mode 1)
  (save-place-mode 1)
  (global-so-long-mode 1)
  (pixel-scroll-precision-mode 1))

(defgroup pk-emacs nil
  "User options for my dotemacs."
  :group 'file)

(setq user-full-name "Piotr Kwiecinski")

(use-package exec-path-from-shell
  :demand t
  :config
  (exec-path-from-shell-initialize)
  ;; Subprocesses (ghostel, claude-code-ide) edit in this frame: the session-wide
  ;; `emacsclient -t' fails inside an Emacs terminal ("Fontset 'tty' does not exist").
  (setenv "EDITOR" "emacsclient")
  (setenv "VISUAL" "emacsclient"))

(use-package recentf
  :ensure nil
  :custom
  (recentf-exclude '(".gz" ".xz" ".zip" "/elpa/" "/ssh:" "/sudo:"))
  (recentf-max-saved-items 1000)
  :hook (after-init . recentf-mode))

;;; Defaults
(use-package autorevert
  :ensure nil
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
  :ensure nil
  :custom
  (history-delete-duplicates t)
  :init
  (savehist-mode 1))

;; Customize writes are throwaway; keep settings in this file.
(setq custom-file (make-temp-file "emacs-custom-" nil ".el"))
(setq initial-scratch-message nil)

(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

;;; File management
(use-package dired
  :ensure nil
  :custom
  (dired-listing-switches "-agFv --group-directories-first")
  (dired-dwim-target #'dired-dwim-target-next)
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'always)
  (dired-auto-revert-buffer t)
  :hook (dired-mode . dired-hide-details-mode))

(use-package dired-x
  :ensure nil
  :after dired
  :demand t)

(use-package dired-subtree
  :after dired
  :bind (:map dired-mode-map
              ("<tab>" . dired-subtree-toggle)))

(use-package no-littering
  :demand t
  :config
  (require 'recentf)
  (add-to-list 'recentf-exclude
               (recentf-expand-file-name no-littering-var-directory))
  (add-to-list 'recentf-exclude
               (recentf-expand-file-name no-littering-etc-directory))
  (no-littering-theme-backups))

(use-package files
  :ensure nil
  :custom
  (backup-by-copying t)
  (delete-old-versions t)
  (kept-new-versions 6)
  (kept-old-versions 2)
  (version-control t))

(use-package bookmark
  :ensure nil
  :custom
  (bookmark-save-flag 1))

;;; Completion
(defvar xref-show-xrefs-function)
(defvar xref-show-definitions-function)

(use-package consult
  :demand t
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
         ("M-g I" . consult-imenu-multi)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s r" . consult-ripgrep)
         ("M-s f" . consult-fd))
  :config
  (setq consult-line-numbers-widen t)
  (setq completion-in-region-function #'consult-completion-in-region)
  (setq consult-narrow-key "<")
  (with-eval-after-load 'xref
    (setq xref-show-xrefs-function #'consult-xref
          xref-show-definitions-function #'consult-xref)))

(use-package embark
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim)
         ("C-h B" . embark-bindings)))

(use-package embark-consult
  :after (embark consult)
  :demand t)

(use-package which-key
  :ensure nil
  :hook (after-init . which-key-mode))

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
  :after vertico
  :bind (:map vertico-map
         ("RET" . vertico-directory-enter)
         ("DEL" . vertico-directory-delete-char)
         ("M-DEL" . vertico-directory-delete-word))
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

(use-package marginalia
  :init
  (marginalia-mode 1))

(use-package orderless
  :demand t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles . (partial-completion)))
                                   (eglot (styles . (orderless)))
                                   (eglot-capf (styles . (orderless))))))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-abbrev)
  ;; Elisp buffers already get symbols from `elisp-completion-at-point'.
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
  :ensure nil
  :custom
  (compilation-auto-jump-to-first-error t)
  ;; Only jump to errors, not cargo warnings.
  (compilation-skip-threshold 2)
  (compilation-scroll-output t))

(use-package ansi-color
  :ensure nil
  :hook (compilation-filter . ansi-color-compilation-filter))

(use-package term
  :ensure nil
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

;; Must load before the theme: solaire decides on `load-theme' whether the
;; theme is supported, and modus isn't by default.
(use-package solaire-mode
  :demand t
  :custom
  (solaire-mode-supported-themes '("^modus-"))
  :config
  ;; Tint non-file buffers with modus `bg-dim' (slightly lighter than the
  ;; editor in vivendi, like Zed's side panels).
  (defun pk--apply-solaire-faces (&rest _)
    "Derive solaire faces from the current modus palette."
    (when (fboundp 'modus-themes-get-color-value)
      (let ((bg (modus-themes-get-color-value 'bg-dim)))
        (dolist (face '(solaire-default-face solaire-fringe-face
                        solaire-line-number-face))
          (set-face-attribute face nil :background bg)))))
  (add-hook 'enable-theme-functions #'pk--apply-solaire-faces)
  (solaire-global-mode +1))

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
(use-package ghostel
  :commands (ghostel ghostel-project)
  :hook (ghostel-mode . pk--disable-line-prefix)
  :init
  (defun pk--disable-line-prefix ()
    "Disable line-prefix in terminal buffers."
    (setq-local line-prefix nil))
  (with-eval-after-load 'project
    (add-to-list 'project-switch-commands '(ghostel-project "Terminal" "t") t)
    (keymap-set project-prefix-map "t" #'ghostel-project)))

(use-package tab-bar
  :ensure nil
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
  :demand t
  :config
  (if (daemonp)
      (add-hook 'server-after-make-frame-hook #'nerd-icons-set-font)
    (nerd-icons-set-font)))

;;;; Mode line
(defun pk-modeline--major-mode-icon ()
  "Return a nerd-icon for the current major mode."
  (let ((icon (nerd-icons-icon-for-mode major-mode)))
    (if (stringp icon) (concat icon " ") "")))

(defun pk-modeline--vc-branch ()
  "Return the current VC branch name, or empty string if detached/not tracked."
  (when-let* ((vc vc-mode)
              (branch (substring-no-properties vc))
              ((string-match "^ Git[:-]\\(.+\\)" branch)))
    (let ((name (match-string 1 branch)))
      (unless (string-match-p "\\`[0-9a-f]\\{7,\\}\\'" name)
        (concat " " (nerd-icons-octicon "nf-oct-git_branch") " " name)))))

(setq-default mode-line-format
              '(" "
                (:eval (pk-modeline--major-mode-icon))
                "%b"
                mode-line-format-right-align
                (:eval (pk-modeline--vc-branch))
                "  %l:%c "))
(use-package nerd-icons-corfu
  :after (nerd-icons corfu)
  :demand t
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(use-package nerd-icons-dired
  :hook
  (dired-mode . nerd-icons-dired-mode))

;;; IDE

(use-package prog-mode
  :ensure nil
  :hook ((prog-mode . column-number-mode)
         (prog-mode . display-line-numbers-mode)))

(use-package flymake
  :ensure nil
  :bind (:map flymake-mode-map
         ("M-n" . flymake-goto-next-error)
         ("M-p" . flymake-goto-prev-error)))

(use-package eldoc
  :ensure nil
  :hook (prog-mode . eldoc-mode))

;; rust-analyzer replies are large; the 64k default means many reads per message.
(setq read-process-output-max (* 1024 1024))

(use-package eglot
  :ensure nil
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
  (add-to-list 'eglot-server-programs '(nix-ts-mode . ("nil")))
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
                                :lifetimeElisionHints (:enable "skip_trivial")))
                  ;; Fetch missing flake inputs without the "Fetch them now?" prompt.
                  :nil (:nix (:flake (:autoArchive t)))))
  ;; Fresh candidates from the server on every keystroke (Corfu wiki).
  (advice-add 'eglot-completion-at-point :around #'cape-wrap-buster)
  :hook (eglot-managed-mode . eglot-inlay-hints-mode))

(use-package editorconfig
  :ensure nil
  :hook (prog-mode . editorconfig-mode))

(use-package autoinsert
  :ensure nil
  :custom
  (auto-insert-query nil)
  :init
  (auto-insert-mode 1))

(use-package yasnippet
  :demand t
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
        (when (and (derived-mode-p 'rust-ts-mode 'nix-ts-mode 'toml-ts-mode 'php-ts-mode)
                   (fboundp 'eglot-current-server)
                   (not (eglot-current-server)))
          (eglot-ensure)))))
  (if (fboundp 'envrc--apply)
      (advice-add 'envrc--apply :after #'pk--envrc-eglot-ensure)
    (display-warning 'envrc "`envrc--apply' is gone: eglot won't start after slow direnv loads")))

(use-package rainbow-mode)

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode)
  :custom
  (rainbow-delimiters-max-face-count 6))

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
                   :program (lambda () (pk--cargo-pick-executable "build" "--bins")))))

  ;; Built-in `xdebug' expects the adapter under dape-adapter-dir; ours comes from nixpkgs.
  (add-to-list 'dape-configs
               `(php-xdebug
                 modes (php-mode php-ts-mode)
                 ensure dape-ensure-command
                 command "node"
                 command-args (,(expand-file-name "out/phpDebug.js"
                                                  (locate-user-emacs-file "php-debug")))
                 :type "php"
                 :port 9003)))

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
  ;; magit-region-sections calls `magit-section-siblings' on nil when the
  ;; region starts outside any section (e.g. the blank line after the status
  ;; headers), erroring on every redisplay.  Remove once fixed upstream.
  (defun pk--magit-region-sections-guard (fn &rest args)
    (unless (and (region-active-p)
                 (not (magit-section-at (region-beginning))))
      (apply fn args)))
  (advice-add 'magit-region-sections :around
              #'pk--magit-region-sections-guard)
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
  :ensure nil
  :custom
  (ediff-split-window-function 'split-window-horizontally)
  (ediff-window-setup-function 'ediff-setup-windows-plain))

;;;;; GitHub
;; Tokens live in KeePassXC, reached through the Secret Service default
;; collection; Forge looks up host api.github.com, user <github.user>^forge.
(use-package auth-source
  :ensure nil
  :custom
  (auth-sources '(default)))

(use-package forge
  :after magit
  :demand t)

;;;; Programming languages
(use-package paredit
  :hook ((emacs-lisp-mode . paredit-mode)
         (scheme-mode . paredit-mode)))

;;;;; Bash

(use-package bats-mode)

;;;;; Elisp

(use-package package-lint)

;;;;; Nix

(use-package nix-ts-mode
  :mode "\\.nix\\'"
  :hook (nix-ts-mode . eglot-ensure))

;;;;; PHP

(use-package php-mode)

;; Eglot's default server for php-ts-mode is phpactor.
(use-package php-ts-mode
  :ensure nil
  :if (treesit-available-p)
  :mode "\\.php\\'"
  :hook (php-ts-mode . eglot-ensure))

;; Magento vendor modules are nested git checkouts, so project.el stops at the
;; module and phpactor starts without vendor/autoload.php.  For Eglot only,
;; root the server at the nearest .phpactor.json instead.
(defun pk--eglot-phpactor-root (dir)
  "Use the nearest dir above DIR containing .phpactor.json as the LSP root."
  (when-let* ((_ (bound-and-true-p eglot-lsp-context))
              (root (locate-dominating-file dir ".phpactor.json")))
    (cons 'transient (expand-file-name root))))
;; Defer until project.el is loaded: adding to the still-unbound hook would
;; make its defvar a no-op and drop the default `project-try-vc'.
(with-eval-after-load 'project
  (add-hook 'project-find-functions #'pk--eglot-phpactor-root))

(use-package magento2-yasnippets
  :if (file-directory-p "~/projects/opensource/magento2-yasnippets")
  :load-path "~/projects/opensource/magento2-yasnippets"
  :after yasnippet
  :demand t
  :config
  (auto-insert-mode 1)
  (let ((di-template (concat magento2-yasnippets-templates-dir "xml/di.xml")))
    (add-to-list 'auto-insert-alist
                 `(("etc/\\(?:adminhtml/\\|frontend/\\|crontab/\\)?di\\.xml\\'" . "Magento 2 di.xml") . [,di-template  autoinsert-yas-expand])))
  (add-to-list 'auto-insert-alist
               '(("etc/module\\.xml\\'" . "Magento 2 module.xml") . ["magento/module.xml" autoinsert-yas-expand]))
  (add-to-list 'auto-insert-alist '(("\\.php\\'" . "PHP class") . "skeleton.php")))

;; trivialBuild package: no generated autoloads.
(use-package magento-cache-clean
  :commands (magento-cache-clean
             magento-cache-clean-watch
             magento-cache-clean-watch-stop
             magento-cache-clean-transient))

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
  :ensure nil
  :mode "\\.rs\\'"
  :hook ((rust-ts-mode . eglot-ensure)
         (rust-ts-mode . pk--rust-format-on-save))
  :bind (:map rust-ts-mode-map
         ("C-c C-c t" . pk-cargo-test-at-point)
         ("C-c C-c r" . pk-cargo-run)
         ("C-c C-c b" . pk-cargo-build)
         ("C-c C-c l" . pk-cargo-clippy))
  :init
  ;; rust-analyzer runs the devshell's rustfmt.
  (defun pk--rust-format-on-save ()
    (add-hook 'before-save-hook
              (lambda () (when (eglot-managed-p) (eglot-format-buffer)))
              nil t))

  (defun pk--cargo (args)
    "Compile `cargo ARGS' from the nearest crate; prefix arg edits the command.
`compile' carries this buffer's direnv environment."
    (let ((default-directory (or (locate-dominating-file default-directory "Cargo.toml")
                                 (project-root (project-current t))))
          (command (concat "cargo " args))
          ;; On compile's pty nextest shows only a progress bar, then erases it.
          (compilation-environment (cons "NEXTEST_HIDE_PROGRESS_BAR=1"
                                         compilation-environment)))
      (compile (if current-prefix-arg (compilation-read-command command) command))))

  (defun pk-cargo-test-at-point ()
    "Run the test function at point, or all tests outside one; nextest if present."
    (interactive)
    (let* ((fn (treesit-parent-until
                (treesit-node-at (point))
                (lambda (n) (equal (treesit-node-type n) "function_item"))
                t))
           (name (and fn (treesit-node-text
                          (treesit-node-child-by-field-name fn "name") t))))
      (pk--cargo (concat (if (executable-find "cargo-nextest") "nextest run" "test")
                         (and name (concat " " name))))))

  (defun pk-cargo-run () (interactive) (pk--cargo "run"))
  (defun pk-cargo-build () (interactive) (pk--cargo "build"))
  (defun pk-cargo-clippy () (interactive) (pk--cargo "clippy --all-targets")))

;;;;; TOML

(use-package toml-ts-mode
  :ensure nil
  :if (treesit-available-p)
  :mode ("Cargo\\.toml\\'" "\\.toml\\'")
  :hook (toml-ts-mode . eglot-ensure))

;;;;; Web
(use-package web-mode
  :mode "\\.phtml\\'"
  :config
  (add-to-list 'web-mode-engines-alist '("php" . "\\.phtml\\'")))

;;;;; XML
(use-package nxml-mode
  :ensure nil)

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
  :ensure nil
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
  :demand t
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
  :after elfeed-tube
  :demand t)

;;; Personal information management
;; Demanded: org-protocol must be live for browser capture links.
(use-package org
  :ensure nil
  :demand t
  :custom
  (org-return-follows-link t)
  (org-mouse-1-follows-link t)
  (org-src-preserve-indentation t)
  (org-confirm-babel-evaluate nil)
  (org-src-strip-leading-add-trailing-blank-lines t)
  (org-agenda-files (list "~/projects/personal/second-brain/"))
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
      :demand t
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

(use-package websocket)

(use-package org-roam-ui
  :after (org-roam websocket))

(use-package async
  :after dired
  :demand t
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
  (claude-code-ide-emacs-tools-setup)
  (setq claude-code-ide-terminal-backend 'ghostel)

  (defun my/claude-code-propagate-envrc (orig-fun &rest args)
    "Propagate envrc environment variables to Claude Code terminal sessions."
    (let* ((envrc-env (when (bound-and-true-p envrc--status)
                        (cl-set-difference
                         (buffer-local-value 'process-environment (current-buffer))
                         (default-value 'process-environment)
                         :test #'string=)))
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
  :demand t
  :config
  (claude-code-ide-companion-project-switch-mode 1))

(use-package pilish
  :commands (pilish pilish-toggle pilish-session-browser)
  :bind ("C-c C-;" . pilish)
  :custom
  (pilish-grammar-declined-set
   '(c cpp go ruby java cmake dockerfile c-sharp clojure elixir haskell
       heex kotlin gomod scala))
  :config
  (defalias 'pi 'pilish))

(use-package abbrev
  :ensure nil
  :hook ((prog-mode text-mode) . abbrev-mode))

(use-package work
  :demand t
  :load-path "lisp-private")
