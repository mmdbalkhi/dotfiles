;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "komeil Parseh"
      user-mail-address "ahmdparsh129@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-dracula)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/Documents/org")

;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(setq doom-irc-servers '("irc.freenode.net" "irc.oftc.net" "irc.libera.chat"))
(setq doom-irc-nick "mmdbalkhi")

(setq url-gateway-method 'socks)
(setq socks-server '("Default server" "127.0.0.1" 8086 5))

(setenv "ALL_PROXY" "socks5://127.0.0.1:8086")
(setenv "all_proxy" "socks5://127.0.0.1:8086")

(use-package minimap
  :ensure t
  :config
  (add-hook 'prog-mode-hook #'minimap-mode)
)

;; 
(global-undo-tree-mode)

;; rainbow
(add-hook 'prog-mode-hook #'rainbow-delimiters-mode)

;; modeline height
(setq doom-modeline-height 25)

;; multiple-cursors
(global-set-key (kbd "C-c m c") 'mc/edit-lines)

(use-package! org-roam
  :custom
  (org-roam-directory "~/Documents/org")
  :config
  (org-roam-db-autosync-mode))

(setq lsp-ui-doc-enable t
      lsp-ui-doc-show-with-cursor t
      lsp-ui-sideline-show-code-actions t)


(setq display-line-numbers-type 'relative) ; یا 't برای شماره خطوط مطلق
(global-display-line-numbers-mode t)

(add-hook 'c-mode-common-hook
          (lambda ()
            (setq tab-width 8)               ; عرض هر تب ۸ اسپیس
            (setq c-basic-offset 8)          ; تنظیم تورفتگی به ۸ اسپیس
            (setq indent-tabs-mode nil)))    ; استفاده از اسپیس به جای تب

(add-hook 'python-mode-hook
          (lambda ()
            (setq tab-width 4)
            (setq indent-tabs-mode nil))) ; استفاده از اسپیس به جای تب

(use-package lsp-mode
  :ensure t
  :hook ((c-mode . lsp)
         (c++-mode . lsp))
  :commands lsp
  :config
  (setq lsp-enable-snippet t              ;; فعال کردن تکه‌های کد (snippets)
        lsp-enable-file-watchers t        ;; فعال کردن نظارت بر تغییرات فایل
        lsp-idle-delay 0.500              ;; تاخیر برای واکنش‌دهی LSP
        lsp-signature-auto-activate t))    ;; فعال کردن امضای خودکار توابع

(use-package company-lsp
  :ensure t
  :after (lsp-mode company)
  :config
  (push 'company-lsp company-backends))   ;; استفاده از شرکت (company) برای تکمیل خودکار

(setq lsp-hover-enable t) ; فعال کردن نمایش مستندات

(use-package lsp-ui
  :ensure t
  :after lsp-mode
  :config
  (setq lsp-ui-sideline-enable t        ;; فعال کردن نوار کنار کد برای نمایش خطاها
        lsp-ui-doc-enable t             ;; فعال کردن نمایش مستندات به‌صورت پاپ‌آپ
        lsp-ui-doc-position 'at-point)) ;; نمایش مستندات در مکان موس

