;;; early-init.el -*- lexical-binding: t; -*-

(let ((normal-gc-cons-threshold (* 20 1024 1024))
      (init-gc-cons-threshold (* 128 1024 1024)))
  (setq gc-cons-threshold init-gc-cons-threshold)
  (add-hook 'emacs-startup-hook
            (lambda () (setq gc-cons-threshold normal-gc-cons-threshold))))

(customize-set-variable 'load-prefer-newer t)
(customize-set-variable 'inhibit-startup-message t)
(customize-set-variable 'inhibit-startup-screen t)

(push '(tool-bar-lines . 0) default-frame-alist)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

(customize-set-variable 'initial-major-mode 'fundamental-mode)
;;; early-init.el ends here
