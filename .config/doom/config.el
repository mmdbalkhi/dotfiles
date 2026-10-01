;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "Komeil Parseh"
      user-mail-address "komeilparseh@disroot.org")
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
(setq doom-font (font-spec :family "BlexMono Nerd Font Mono" :size 18 :weight 'semi-light)
      doom-variable-pitch-font (font-spec :family "BlexMono Nerd Font Mono" :size 19))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-nord)

                                        ; Source - https://stackoverflow.com/a/1595673␍
                                        ; Posted by Trey Jackson␍
                                        ; Retrieved 2026-08-28, License - CC BY-SA 2.5␍

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

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
;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/Documents/org/")

(after! org
  ;; Set the default export directory to an ABSOLUTE path
  (setq org-export-default-directory (expand-file-name "export" "~/org/"))
  
  ;; Ensure .org links are exported as .html links
  (setq org-html-link-org-files-as-html t)
  
  ;; Remove the annoying "Validation" link at the bottom of HTML exports
  (setq org-html-validation-link nil)
  ;; Keep daily journals separate from the roam graph
  (setq org-journal-dir (expand-file-name "journal" org-directory)))

;; Specific directory for Org-roam (the graph database)
(after! org-roam
  (setq org-roam-directory (expand-file-name "notes" org-directory))
  ;; Make sure the database syncs on startup
  (org-roam-db-sync))
(setq org-directory "~/Documents/org/")

(after! org
  (setq org-html-link-org-files-as-html t)
  (setq org-html-validation-link nil)
  (setq org-journal-dir (expand-file-name "journal" org-directory)))

;; ---------- Export directory mirroring ----------
(defun my/org-export-to-export-dir (orig-fun extension &optional subtreep pub-dir)
  (let* ((org-root   (expand-file-name org-directory))
         (export-root (expand-file-name "export" org-root))
         (file (buffer-file-name (buffer-base-buffer)))
         (rel  (and file
                    (string-prefix-p org-root (expand-file-name file))
                    (file-relative-name (expand-file-name file) org-root)))
         (pub-dir (or pub-dir
                      (and rel
                           (expand-file-name
                            (file-name-directory rel)
                            export-root)))))
    (when pub-dir
      (make-directory pub-dir t))
    (funcall orig-fun extension subtreep pub-dir)))
(after! ox
  (require 'ox-tufte)
  (defun my/org-html-embed-tufte-css ()
    "One single <style> block: tufte + ox-tufte + Plex overrides."
    (let* ((css-dir (expand-file-name "static/css" org-directory))
           (tufte   (expand-file-name "tufte.css" css-dir))
           (ox      (expand-file-name "ox-tufte.css" css-dir)))
      (concat
       "<link href=\"https://fonts.googleapis.com/css?family=IBM Plex Mono\" rel=\"stylesheet\">\n"
       "<link href=\"https://fonts.googleapis.com/css?family=IBM Plex Sans\" rel=\"stylesheet\">\n"
       "<link href=\"https://fonts.googleapis.com/css?family=IBM Plex Serif\" rel=\"stylesheet\">\n"
       "<style type=\"text/css\">\n"
       "/* ===== tufte.css ===== */\n"
       (if (file-exists-p tufte)
           (with-temp-buffer (insert-file-contents tufte) (buffer-string))
         "/* WARNING: tufte.css not found */\n")
       "\n\n/* ===== ox-tufte.css ===== */\n"
       (if (file-exists-p ox)
           (with-temp-buffer (insert-file-contents ox) (buffer-string))
         "/* WARNING: ox-tufte.css not found */\n")
       "\n\n/* ===== Plex ===== */\n"
       "body, article {\n"
       "  font-family: \"IBM Plex Serif\", et-book, Georgia, serif !important;\n"
       "  background-color: #fffff8;\n"
       "  color: #111;\n"
       "}\n"
       "h1, h2, h3, h4, h5, .sans {\n"
       "  font-family: \"IBM Plex Sans\", system-ui, sans-serif !important;\n"
       "  font-weight: 500;\n"
       "}\n"
       "code, pre, .org-src-container pre {\n"
       "  font-family: \"IBM Plex Mono\", ui-monospace, monospace !important;\n"
       "}\n"
       ".sidenote, .marginnote {\n"
       "  font-family: \"IBM Plex Serif\", Georgia, serif;\n"
       "}\n"
       "mjx-container, .MathJax, .katex { margin: 0.6em 0; }\n"
       "</style>")))
  (setq org-html-head-include-default-style nil)
  (setq org-html-head (my/org-html-embed-tufte-css)))

(advice-add 'org-export-output-file-name :around #'my/org-export-to-export-dir)
(after! ox
  (require 'ox-tufte))

(setq org-directory "~/Documents/org/")

(after! org
  (setq org-html-link-org-files-as-html t)
  (setq org-html-validation-link nil)
  (setq org-journal-dir (expand-file-name "journal" org-directory)))

(after! org-roam
  (setq org-roam-directory (expand-file-name "notes" org-directory))
  (org-roam-db-sync))

;; ---------- Export directory mirroring ----------
(defun my/org-export-to-export-dir (orig-fun extension &optional subtreep pub-dir)
  (let* ((org-root   (expand-file-name org-directory))
         (export-root (expand-file-name "export" org-root))
         (file (buffer-file-name (buffer-base-buffer)))
         (rel  (and file
                    (string-prefix-p org-root (expand-file-name file))
                    (file-relative-name (expand-file-name file) org-root)))
         (pub-dir (or pub-dir
                      (and rel
                           (expand-file-name
                            (file-name-directory rel)
                            export-root)))))
    (when pub-dir
      (make-directory pub-dir t))
    (funcall orig-fun extension subtreep pub-dir)))

(advice-add 'org-export-output-file-name :around #'my/org-export-to-export-dir)
(after! ox
  (require 'ox-tufte))

;; Tell Org Agenda where to look for tasks
(after! org-agenda
  (setq org-agenda-files (list (expand-file-name "tasks.org" org-directory))))

;; `load!' for loading external *.el files relative to this one
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
(setq shell-file-name "/usr/bin/fish")
;; fill column setting globaly
(setq-default fill-column 80)
(global-display-fill-column-indicator-mode 1)

(custom-set-faces
 '(line-number-current-line ((t (:inherit default :weight bold))))
 '(fill-column-indicator ((t (:foreground "#5B6268" :weight thin)))))

(defun my/editorconfig-fill-column-minus-10 (props)
  "Set fill-column to max_line_length - 10 when EditorConfig provides it."
  (when-let* ((raw (gethash 'max_line_length props))
              (n (and (stringp raw)
                      (not (member raw '("off" "unset")))
                      (string-to-number raw)))
              ((> n 10)))
    (setq-local fill-column (- n (/ n 10)))))

(add-hook 'editorconfig-after-apply-functions
          #'my/editorconfig-fill-column-minus-10)

;; python, uv, etc. based on: https://mclare.blog/posts/using-uv-in-emacs/
;; Python + uv + pyrefly
;; you can install pyrefly with py3-pipx
;; pipx install pyrefly
(defvar my/pyrefly-executable "/home/komeil/.local/bin/pyrefly"
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

;; Enable the www ligature in every possible major mode
(ligature-set-ligatures 't '("www"))

;; Enable ligatures in programming modes                                                           
(ligature-set-ligatures 'prog-mode '("www" "**" "***" "**/" "*>" "*/" "\\\\" "\\\\\\" "{-" "::"
                                     ":::" ":=" "!!" "!=" "!==" "-}" "----" "-->" "->" "->>"
                                     "-<" "-<<" "-~" "#{" "#[" "##" "###" "####" "#(" "#?" "#_"
                                     "#_(" ".-" ".=" ".." "..<" "..." "?=" "??" ";;" "/*" "/**"
                                     "/=" "/==" "/>" "//" "///" "&&" "||" "||=" "|=" "|>" "^=" "$>"
                                     "++" "+++" "+>" "=:=" "==" "===" "==>" "=>" "=>>" "<="
                                     "=<<" "=/=" ">-" ">=" ">=>" ">>" ">>-" ">>=" ">>>" "<*"
                                     "<*>" "<|" "<|>" "<$" "<$>" "<!--" "<-" "<--" "<->" "<+"
                                     "<+>" "<=" "<==" "<=>" "<=<" "<>" "<<" "<<-" "<<=" "<<<"
                                     "<~" "<~~" "</" "</>" "~@" "~-" "~>" "~~" "~~>" "%%"))

(global-ligature-mode 't)
(require 'org-id)
(setq org-id-locations-file (expand-file-name ".org-id-locations" user-emacs-directory))
(setq org-id-link-to-org-use-id 'create-if-interactive-and-no-custom-id)

(defun eos/org-custom-id-get (&optional pom create prefix)
  "Get the CUSTOM_ID property of the entry at point-or-marker POM.
If CREATE is non-nil, create a CUSTOM_ID if none is present already.
Uses an 'h-' prefix to ensure valid HTML/jQuery anchors."
  (interactive)
  (org-with-point-at pom
    (let ((id (org-entry-get nil "CUSTOM_ID")))
      (cond
       ;; If it already exists and starts with "h-" or "h:", keep it
       ((and id (stringp id) (string-match-p "^h[-:]" id))
        id)
       ;; Otherwise, if CREATE is true, generate a new one
       (create
        ;; FIX 1: org-id-new takes no arguments. Concatenate the prefix manually.
        (setq id (concat (or prefix "h-") (org-id-new)))
        (org-entry-put pom "CUSTOM_ID" id)
        ;; FIX 2: Ensure the buffer is actually visiting a file before adding location
        (let ((file (buffer-file-name (buffer-base-buffer))))
          (when file
            (org-id-add-location id file)))
        id)))))

(defun eos/org-add-ids-to-headlines-in-file ()
  "Add CUSTOM_ID properties to all headlines in the current file
which do not already have one. Only runs if `#+OPTIONS:.*auto-id:t`
is present at the top of the file."
  ;; FIX 3: We must return nil for write-contents-functions to let Emacs 
  ;; proceed with the actual file writing.
  (save-excursion
    (widen)
    (goto-char (point-min))
    (when (re-search-forward "^#+OPTIONS:.*auto-id:t" (point-max) t)
      (org-map-entries (lambda () (eos/org-custom-id-get (point) 'create))))
    nil)) 

;; FIX 4: Use write-contents-functions instead of before-save-hook.
;; This ensures the buffer modifications are actually written to disk on the first save.
(add-hook 'org-mode-hook
          (lambda ()
            (add-hook 'write-contents-functions #'eos/org-add-ids-to-headlines-in-file nil t)))

;; FIX 5: Use org-capture-before-finalize-hook and ensure point is on a heading.
(add-hook 'org-capture-before-finalize-hook
          (lambda ()
            (when (org-at-heading-p)
              (eos/org-custom-id-get (point) 'create))))

(use-package! rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))
(after! org
  (setq org-list-allow-alphabetical t))

(use-package! websocket
  :after org-roam)

(use-package! org-roam-ui
  :after org-roam ;; or :after org
  ;;         normally we'd recommend hooking orui after org-roam, but since org-roam does not have
  ;;         a hookable mode anymore, you're advised to pick something yourself
  ;;         if you don't care about startup time, use
  ;;  :hook (after-init . org-roam-ui-mode)
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start t))
