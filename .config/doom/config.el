;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
(setq doom-font (font-spec :family "Fira Code" :size 18 :weight 'semi-light)
      doom-variable-pitch-font (font-spec :family "Fira Code " :size 19))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
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
(setq shell-file-name "/bin/bash")

;; fill column setting globaly
(setq-default fill-column 80)
(global-display-fill-column-indicator-mode 1)

(custom-set-faces
  '(line-number-current-line ((t (:inherit default :weight bold))))
  '(fill-column-indicator ((t (:foreground "#5B6268" :weight thin)))))


;; python, uv, etc. based on: https://mclare.blog/posts/using-uv-in-emacs/
;;; Python + uv + pyrefly
(defvar my/pyrefly-executable "/home/komeil/w/pyrefly/target/release/pyrefly"
  "Absolute path to the pyrefly executable.")

(defun my/python-uv-activate ()
  "Activate .venv from the current project root, if present."
  (let* ((root (doom-project-root))
         (venv (and root (expand-file-name ".venv" root)))
         (python (and venv
                      (expand-file-name
                       (if (eq system-type 'windows-nt)
                           "Scripts/python.exe"
                         "bin/python")
                       venv))))
    (when (and python (file-exists-p python))
      (setq-local python-shell-interpreter python)
      (let ((venv-bin (file-name-directory python)))
        (setq-local exec-path (cons venv-bin (remove venv-bin exec-path)))
        (setenv "PATH" (concat venv-bin path-separator (getenv "PATH"))))
      (setenv "VIRTUAL_ENV" venv)
      (setenv "PYTHONHOME" nil))))

(add-hook 'python-mode-hook #'my/python-uv-activate)
(add-hook 'python-ts-mode-hook #'my/python-uv-activate)

(after! eglot
  (add-to-list 'eglot-server-programs
               `((python-mode python-ts-mode)
                 . (,my/pyrefly-executable "lsp"))))

(add-hook 'python-mode-hook #'eglot-ensure)
(add-hook 'python-ts-mode-hook #'eglot-ensure)

