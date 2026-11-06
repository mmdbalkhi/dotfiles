;;; init.el --- Personal configuration -*- lexical-binding: t; no-byte-compile: t -*-
;; Generated from readme.org – edit the Org file, not this one.

(require 'cl-lib)
(require 'package)
(setq load-prefer-newer t)

(defvar my/config-org
  (expand-file-name "readme.org"
                    (file-name-directory (file-truename user-init-file)))
  "This literate configuration file (used by tangle-on-save).")

(defvar my/first-boot (not (file-directory-p package-user-dir))
  "Non-nil when no packages have been installed yet.")

(defvar my/install-count 0
  "Number of packages installed during this session.")

(when my/first-boot
  (message "First boot: installing packages, this may take a while..."))

(defun my/package-install-advice (orig-fun &rest args)
  "Show progress while installing packages on first boot."
  (when my/first-boot
    (let ((pkg (car args)))
      (cl-incf my/install-count)
      (message "[%d] Installing %s ..." my/install-count
               (if (package-desc-p pkg) (package-desc-name pkg) pkg))))
  (apply orig-fun args))

(advice-add 'package-install :around #'my/package-install-advice)

(add-hook 'emacs-startup-hook
          (lambda ()
            (when my/first-boot
              (message "First boot complete: %d package(s) installed. Restart Emacs."
                       my/install-count)
              (when (fboundp 'dashboard-open)
                (dashboard-open)))))

;; [[file:readme.org::#h-f2eb6f8e][Package archives and use-package:1]]
(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/"))
      package-archive-priorities
      '(("gnu" . 3) ("nongnu" . 2) ("melpa" . 1)))

(package-initialize)

(defun my/use-package-ensure (name ensure _state)
  "Install the packages named by ENSURE (the parsed :ensure arguments).
An argument of t means NAME itself; nil means nothing to install."
  (dolist (arg ensure)
    (let ((pkg (if (eq arg t) name arg)))
      (when (and pkg
                 (not (package-installed-p pkg))
                 (not (locate-library (symbol-name pkg))))
        (unless (assq pkg package-archive-contents)
          (package-refresh-contents))
        (package-install pkg)))))

(setq use-package-ensure-function #'my/use-package-ensure
      use-package-always-ensure   nil  ;; do not wanna load 50+ package.
      use-package-enable-imenu-support t
      use-package-expand-minimally t)
(require 'use-package)
;; Package archives and use-package:1 ends here

;; [[file:readme.org::#h-f280c4b1][Customize file:1]]
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file 'noerror 'nomessage)
;; Customize file:1 ends here

;; [[file:readme.org::#h-fad8804a][Identity and paths:1]]
(defun my/git-config (key)
  "Return git config KEY, or nil when git or the key is missing."
  (when (executable-find "git")
    (let ((out (with-temp-buffer
                 (when (zerop (call-process "git" nil t nil "config" "--get" key))
                   (string-trim (buffer-string))))))
      (and out (not (string-empty-p out)) out))))

(setq user-full-name    (or (my/git-config "user.name")  (getenv "USER")  "user")
      user-mail-address (or (my/git-config "user.email") (getenv "EMAIL") "user@example.com")
      org-directory     (expand-file-name "~/Documents/org/"))

;; Extra binary locations (Guix, user installs, system).  Appended, so your
;; own PATH order wins.  Both `exec-path' and the PATH variable are updated.
(dolist (dir '("~/.local/bin"
               "~/.guix-profile/bin"
               "~/.config/guix/current/bin"
               "/run/current-system/profile/bin"
               "/usr/local/bin"
               "/usr/bin"))
  (let ((dir (expand-file-name dir)))
    (when (and (file-directory-p dir) (not (member dir exec-path)))
      (setq exec-path (append exec-path (list dir)))
      (setenv "PATH" (concat (getenv "PATH") path-separator dir)))))
;; Identity and paths:1 ends here

;; [[file:readme.org::#h-1c7e3d14][Server (plain Emacs and daemon):1]]
(defvar my/start-server t
  "Non-nil means a plain (non-daemon) Emacs also starts the server.")

(add-hook 'after-init-hook
          (lambda ()
            (require 'server)
            (when (and my/start-server (not (daemonp)) (not (server-running-p)))
              (server-start))))
;; Server (plain Emacs and daemon):1 ends here

;; [[file:readme.org::#h-107368dc][Editing defaults:1]]
(electric-indent-mode 1)
(electric-pair-mode 1)          ; the only auto-pairing package (no smartparens)
(save-place-mode 1)
(savehist-mode 1)
(recentf-mode 1)
(global-auto-revert-mode 1)
(global-so-long-mode 1)
(auto-insert-mode 1)

(setq-default word-wrap t
              truncate-lines nil)
(global-visual-line-mode 1)

(setq global-auto-revert-non-file-buffers t
      auto-revert-verbose nil
      recentf-max-saved-items 100
      auto-insert-query nil)
;; Editing defaults:1 ends here

;; [[file:readme.org::#h-1269dbae][Large files:1]]
(defvar my/large-file-threshold (* 1024 1024)
  "Buffers larger than this many characters get heavy features disabled.")

(defun my/large-file-setup ()
  "Disable expensive features in very large buffers."
  (when (> (buffer-size) my/large-file-threshold)
    (display-line-numbers-mode -1)
    (font-lock-mode -1)
    (when (bound-and-true-p flymake-mode) (flymake-mode -1))
    (message "Large file: heavy features disabled.")))

(add-hook 'find-file-hook #'my/large-file-setup)
;; Large files:1 ends here

;; [[file:readme.org::#h-b86876f7][Clipboard:1]]
;; Enable system clipboard integration
(setq select-enable-clipboard t)

;; Use wl-clipboard for seamless Wayland copy/paste
(when (executable-find "wl-copy")
  (defun my/wl-copy (text &optional push)
    "Copy TEXT to the Wayland clipboard using wl-copy."
    (with-temp-buffer
      (insert text)
      ;; -n prevents adding an unwanted trailing newline
      (call-process-region (point-min) (point-max) "wl-copy" nil nil nil "-n")))
  
  (defun my/wl-paste ()
    "Paste text from the Wayland clipboard using wl-paste."
    (let ((text (shell-command-to-string "wl-paste")))
      (when (and text (> (length text) 0))
        ;; Strip trailing newline for cleaner pasting
        (if (string-suffix-p "\n" text)
            (substring text 0 -1)
          text))))
  
  (setq interprogram-cut-function #'my/wl-copy)
  (setq interprogram-paste-function #'my/wl-paste))
;; Clipboard:1 ends here

;; [[file:readme.org::#h-5182d5ed][Fonts:1]]
;; Emacs 31 Rendering Enhancements
  (setopt line-spacing 0.15)
  (setq x-underline-at-descent-line t      ; Beautiful underlines
        x-use-underline-position-properties t
        font-lock-maximum-decoration t
        bidi-paragraph-direction 'left-to-right   ; Crucial for fast rendering
        inhibit-compacting-font-caches t)         ; avoids stutter with large icon fonts

(setq-default line-spacing 0.15)

(when (fboundp 'set-fontset-font)
  (set-fontset-font t 'unicode "Noto Color Emoji" nil 'append))

(defvar my/font-family "BlexMono Nerd Font Mono" "Monospace font for code.")
(defvar my/variable-font-family "IBM Plex Sans" "Proportional font for text/Org.")

(defun my/apply-fonts (&optional frame)
  "Apply comprehensive font settings."
  (with-selected-frame (or frame (selected-frame))
    (when (display-graphic-p)
      (when (find-font (font-spec :family my/font-family))
        (set-face-attribute 'default nil :family my/font-family :height 180 :weight 'semi-light)
        (set-face-attribute 'fixed-pitch nil :family my/font-family :height 1.0))
      (when (find-font (font-spec :family my/variable-font-family))
        (set-face-attribute 'variable-pitch nil :family my/variable-font-family :height 190)))))

(add-hook 'after-make-frame-functions #'my/apply-fonts)
(unless (daemonp) (my/apply-fonts))
;; Fonts:1 ends here

;; [[file:readme.org::#h-ace9c794][org:1]]
(setopt modus-themes-mixed-fonts t)
(setopt modus-themes-headings '((t . (variable-pitch))))
;; org:1 ends here

;; [[file:readme.org::#h-3e1503be][Theme:1]]
(use-package persian-landscapes-themes
  :vc (:url "https://github.com/mmdbalkhi/persian-landscapes" :rev :newest)
  :demand t
  :config
  (load-theme 'goy-dark t))
;; Theme:1 ends here

;; [[file:readme.org::#h-d7822f7c][Personal Dashboard:1]]
(defvar my/reading-list
  '(("Category Theory in Context"      . "Riehl")
    ("Software Foundations, Vol. 1"    . "Pierce et al.")
    ("Types and Programming Languages" . "Pierce")
    ("Practical Foundations for PL"    . "Harper"))
  "Books shown in the dashboard's reading section.  Edit freely.")
 
(defun my/dashboard-reading (list-size)
  "Insert up to LIST-SIZE entries of `my/reading-list'."
  (dashboard-insert-heading "Currently Reading")
  (insert "\n")
  (dolist (book (seq-take my/reading-list list-size))
    (insert "    " (car book)
            (propertize (format "  (%s)" (cdr book)) 'face 'shadow)
            "\n")))
 
(use-package dashboard
  :ensure t
  :demand t
  :custom
  (dashboard-startup-banner 'ascii)
  (dashboard-banner-ascii "λ")
  (dashboard-banner-logo-title "Komeil Parseh")
  (dashboard-init-info (lambda () (format-time-string "%A · %d %B %Y")))
  (dashboard-center-content t)
  (dashboard-startupify-list
   '(dashboard-insert-banner
     dashboard-insert-newline
     dashboard-insert-banner-title
     dashboard-insert-newline
     dashboard-insert-navigator
     dashboard-insert-newline
     dashboard-insert-init-info
     dashboard-insert-items))
  (dashboard-projects-backend 'project-el)
  (dashboard-items '((agenda . 5) (recents . 6) (projects . 5)
                     (bookmarks . 3) (reading . 4)))
  (dashboard-navigator-buttons
   '(((nil "Agenda" "Org agenda" (lambda (&rest _) (org-agenda nil "a")))
      (nil "Notes"  "Org-roam"   (lambda (&rest _) (org-roam-node-find)))
      (nil "Feeds"  "Elfeed"     (lambda (&rest _) (elfeed))))))
  :custom-face
  (dashboard-text-banner       ((t (:inherit font-lock-keyword-face :height 3.0))))
  (dashboard-banner-logo-title ((t (:inherit font-lock-constant-face :weight bold :height 1.3))))
  (dashboard-heading           ((t (:inherit font-lock-function-name-face :weight bold))))
  :config
  (add-to-list 'dashboard-item-generators '(reading . my/dashboard-reading))
  (dashboard-setup-startup-hook))
;; Personal Dashboard:1 ends here

;; [[file:readme.org::#h-c21db571][Modeline:1]]
(defvar-local my/lang-version nil
  "Propertized language version string for the mode line, e.g. \"Py 3.12.3\".")
 
(defvar my/lang-version-cache (make-hash-table :test 'equal)
  "Cache of (EXECUTABLE . DIRECTORY) -> version string.")
 
(defun my/lang-version--spec ()
  "Return (LABEL EXECUTABLE . ARGS) for the current buffer's language, or nil."
  (cond ((derived-mode-p 'python-base-mode)
         (list "Py" (or (executable-find python-shell-interpreter)
                        (executable-find "python3"))
               "--version"))
        ((derived-mode-p 'rust-ts-mode 'rustic-mode 'rust-mode)
         (list "Rust" (executable-find "cargo") "--version"))
        ((derived-mode-p 'go-ts-mode 'go-mode)
         (list "Go" (executable-find "go") "version"))
        ((derived-mode-p 'js-base-mode 'typescript-ts-mode 'tsx-ts-mode)
         (list "Node" (executable-find "node") "--version"))))
 
(defun my/lang-version--run (exe args)
  "Run EXE with ARGS and return the first x.y[.z] number in its output."
  (with-temp-buffer
    (when (zerop (apply #'call-process exe nil t nil args))
      (goto-char (point-min))
      (when (re-search-forward "[0-9]+\\(?:\\.[0-9]+\\)+" nil t)
        (match-string 0)))))
 
(defun my/lang-version-update ()
  "Set `my/lang-version' for this buffer (runs once per mode change)."
  (interactive)
  (setq my/lang-version
        (when-let* (((not (file-remote-p default-directory)))
                    (spec (my/lang-version--spec))
                    (exe  (cadr spec))
                    (key  (cons exe default-directory))
                    (ver  (or (gethash key my/lang-version-cache)
                              (puthash key (my/lang-version--run exe (cddr spec))
                                       my/lang-version-cache))))
          (propertize (format "%s %s" (car spec) ver) 'face 'font-lock-type-face))))
 
(add-hook 'after-change-major-mode-hook #'my/lang-version-update)
 
(defun my/ml-branch ()
  "Return the VC branch name for the mode line, or nil."
  (when (stringp vc-mode)
    (propertize
     (concat (replace-regexp-in-string "\\` *[[:alpha:]]+[-:@!?\\^]" ""
                                       (substring-no-properties vc-mode))
             " ")
     'face 'font-lock-doc-face)))
 
(defun my/ml-path ()
  "Return the abbreviated file path (or buffer name), truncated on the left."
  (propertize (string-truncate-left
               (if buffer-file-name (abbreviate-file-name buffer-file-name) (buffer-name))
               60)
              'face 'mode-line-buffer-id))
 
(defun my/ml-lsp ()
  "Return \" LSP\" when Eglot is connected in this buffer."
  (when (and (featurep 'eglot) (eglot-managed-p) (eglot-current-server))
    (propertize " LSP" 'face 'success)))
 
(setq-default
 mode-line-format
 '("%e" evil-mode-line-tag mode-line-modified " "
   (:eval (my/ml-branch)) (:eval (my/ml-path)) " %l:%c"
   mode-line-format-right-align
   (:eval (my/ml-lsp))
   (flymake-mode flymake-mode-line-format)
   (my/lang-version (" " my/lang-version) (" " mode-name))
   mode-line-end-spaces))
;; Modeline:1 ends here

;; [[file:readme.org::#h-c21db571][Modeline:2]]
(setopt modus-themes-common-palette-overrides
        '((border-mode-line-active   unspecified)
          (border-mode-line-inactive unspecified)))
;; Modeline:2 ends here

;; [[file:readme.org::#h-ffa8a174][Code and text decoration:1]]
(use-package indent-bars
  :hook (prog-mode . indent-bars-mode)
  :custom
  (indent-bars-treesit-support t)
  (indent-bars-treesit-ignore-blank-lines-prefix nil))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package hl-todo
  :hook (prog-mode . hl-todo-mode)
  :custom
  (hl-todo-keyword-faces
   '(("TODO"   . "#ff6c6b")
     ("FIXME"  . "#ff6c6b")
     ("NOTE"   . "#ecbe7b")
     ("HACK"   . "#da8548")
     ("REVIEW" . "#51afef"))))

(use-package display-fill-column-indicator
  :ensure nil
  :hook (prog-mode . display-fill-column-indicator-mode)
  :custom
  (display-fill-column-indicator-character ?│)
  :config
  (set-face-attribute 'fill-column-indicator nil :foreground "#5B6268"))

(use-package ligature
  :hook (after-init . global-ligature-mode)
  :config
  (ligature-set-ligatures 't '("www"))
  (ligature-set-ligatures
   'prog-mode
   '("www" "**" "***" "**/" "*>" "*/" "\\\\" "\\\\\\"
     "{-" "::" ":::" ":=" "!!" "!=" "!==" "-}" "----"
     "-->" "->" "->>" "-<" "-<<" "-~" "#{" "#[" "##"
     "###" "####" "#(" "#?" "#_" "#_(" ".-" ".=" ".."
     "..<" "..." "?=" "??" ";;" "/*" "/**" "/=" "/=="
     "/>" "//" "///" "&&" "||" "||=" "|=" "|>" "^="
     "$>" "++" "+++" "+>" "=:=" "==" "===" "==>" "=>"
     "=>>" "<=" "=<<" "=/=" ">-" ">=" ">=>" ">>" ">>-"
     ">>=" ">>>" "<*" "<*>" "<|" "<|>" "<$" "<$>"
     "<!--" "<-" "<--" "<->" "<+" "<+>" "<=="
     "<=>" "<=<" "<>" "<<" "<<-" "<<=" "<<<" "<~"
     "<~~" "</" "</>" "~@" "~-" "~>" "~~" "~~>" "%%")))
;; Code and text decoration:1 ends here

;; [[file:readme.org::#h-23c730da][Visual feedback:1]]
(use-package beacon
  :hook (after-init . beacon-mode)
  :custom (beacon-size 20))

(use-package volatile-highlights
  :hook (after-init . volatile-highlights-mode))

(use-package diff-hl
  :hook ((after-init         . global-diff-hl-mode)
         (magit-post-refresh . diff-hl-magit-post-refresh)))

(use-package smooth-scrolling
  :hook (after-init . smooth-scrolling-mode))

(use-package emojify
  :hook (after-init . global-emojify-mode))

(use-package minimap
  :commands minimap-mode
  :custom
  (minimap-window-location 'right)
  (minimap-update-delay 0.1))

(pixel-scroll-precision-mode 1)
;; Visual feedback:1 ends here

;; [[file:readme.org::#h-979a5beb][Tabs, workspaces, popups:1]]
(use-package tab-bar
  :ensure nil
  :custom
  (tab-bar-show 1)
  (tab-bar-close-button-show nil)
  (tab-bar-new-button-show nil)
  :config
  (tab-bar-mode 1))

(use-package tabspaces
  :hook (after-init . tabspaces-mode)
  :custom
  (tabspaces-use-vc t)
  (tabspaces-initialize-project-with-todo nil))

(use-package popper
  :bind (("C-`"   . popper-toggle)
         ("M-`"   . popper-cycle)
         ("C-M-`" . popper-toggle-type))
  :hook ((after-init . popper-mode)
         (after-init . popper-echo-mode))
  :custom
  (popper-reference-buffers
   '("\\*Messages\\*"
     "Output\\*$"
     "\\*Async Shell Command\\*"
     help-mode
     compilation-mode
     "^\\*eshell.*\\*$" eshell-mode
     "^\\*shell.*\\*$"  shell-mode
     "^\\*term.*\\*$"   term-mode
     "^\\*vterm.*\\*$"  vterm-mode)))
;; Tabs, workspaces, popups:1 ends here

;; [[file:readme.org::#h-f7b48e5c][Minibuffer:1]]
(use-package vertico
  :hook (after-init . vertico-mode)
  :custom
  (vertico-cycle t)
  (vertico-resize t)
  (vertico-count 15))

;; Extension shipped inside the vertico package.
(use-package vertico-directory
  :ensure nil
  :after vertico
  :bind (:map vertico-map
              ("RET"   . vertico-directory-enter)
              ("DEL"   . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word))
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides
   '((file (styles basic partial-completion)))))

(use-package marginalia
  :hook (after-init . marginalia-mode))

(use-package consult
  :bind (("C-c M-x" . consult-mode-command)
         ("C-c h"   . consult-history)
         ("C-c k"   . consult-kmacro)
         ("C-c m"   . consult-man)
         ("C-c i"   . consult-info)
         ("C-x M-:" . consult-complex-command)
         ("C-x b"   . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("C-x 5 b" . consult-buffer-other-frame)
         ("C-x t b" . consult-buffer-other-tab)
         ("C-x r b" . consult-bookmark)
         ("C-x p b" . consult-project-buffer)
         ("M-y"     . consult-yank-pop)
         ("M-g g"   . consult-goto-line)
         ("M-g M-g" . consult-goto-line)
         ("M-g o"   . consult-outline)
         ("M-g m"   . consult-mark)
         ("M-g k"   . consult-global-mark)
         ("M-g i"   . consult-imenu)
         ("M-g I"   . consult-imenu-multi)
         ("M-s d"   . consult-find)
         ("M-s c"   . consult-locate)
         ("M-s g"   . consult-grep)
         ("M-s G"   . consult-git-grep)
         ("M-s r"   . consult-ripgrep)
         ("M-s l"   . consult-line)
         ("M-s L"   . consult-line-multi)
         ("M-s k"   . consult-keep-lines)
         ("M-s u"   . consult-focus-lines)
         ("M-s e"   . consult-isearch-history)
         :map isearch-mode-map
         ("M-e"     . consult-isearch-history)
         ("M-s e"   . consult-isearch-history)
         ("M-s l"   . consult-line)
         ("M-s L"   . consult-line-multi)
         :map minibuffer-local-map
         ("M-s"     . consult-history)
         ("M-r"     . consult-history))
  :custom
  (consult-narrow-key "<")
  (consult-line-start-from-top t)
  :config
  (setq xref-show-xrefs-function       #'consult-xref
        xref-show-definitions-function #'consult-xref))
;; Minibuffer:1 ends here

;; [[file:readme.org::#h-fix-esc][Fix ESC to Exit Minibuffer:1]]
;; Make ESC quit the minibuffer in both Insert and Normal states
(with-eval-after-load 'evil-maps
  (dolist (map (list minibuffer-local-map
                     minibuffer-local-ns-map
                     minibuffer-local-completion-map
                     minibuffer-local-must-match-map
                     minibuffer-local-isearch-map))
    (evil-define-key 'insert map (kbd "ESC") #'abort-minibuffers)
    (evil-define-key 'normal map (kbd "ESC") #'abort-minibuffers)))
;; Fix ESC to Exit Minibuffer:1 ends here

;; [[file:readme.org::#h-d36788ba][In-buffer completion:1]]
(use-package corfu
  :hook (after-init . global-corfu-mode)
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-prefix 2)
  (corfu-auto-delay 0.15)
  (corfu-quit-no-match 'separator)
  (corfu-preselect 'prompt)
  (corfu-on-exact-match nil)
  :bind (:map corfu-map
              ("TAB"     . corfu-next)
              ([tab]     . corfu-next)
              ("S-TAB"   . corfu-previous)
              ([backtab] . corfu-previous))
  :config
  (defun my/corfu-enable-in-minibuffer ()
    "Enable Corfu in the minibuffer when `completion-at-point' is bound."
    (when (where-is-internal #'completion-at-point (list (current-local-map)))
      (setq-local corfu-auto nil)
      (corfu-mode 1)))
  (add-hook 'minibuffer-setup-hook #'my/corfu-enable-in-minibuffer))

(use-package cape
  :demand t
  :after corfu
  :config
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-elisp-block)
  (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-silent)
  (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-purify))
;; In-buffer completion:1 ends here

;; [[file:readme.org::#h-43faf67a][Discoverability and help:1]]
;; which-key is built in since Emacs 30.
(use-package which-key
  :ensure nil
  :hook (after-init . which-key-mode)
  :custom
  (which-key-idle-delay 0.4)
  (which-key-max-description-length 40))

(use-package helpful
  :bind (("C-h f" . helpful-callable)
         ("C-h v" . helpful-variable)
         ("C-h k" . helpful-key)
         ("C-h x" . helpful-command)))
;; Discoverability and help:1 ends here

;; [[file:readme.org::#h-327a966c][Evil core:1]]
(use-package evil
  :ensure t
  :demand t
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-want-C-i-jump nil
        evil-want-Y-yank-to-eol t
        evil-undo-system 'undo-redo
        evil-respect-visual-line-mode t
        ;; Doom-like window splitting behavior
        evil-split-window-below t
        evil-vsplit-window-right t)
  :config
  (evil-mode 1)
  (setq evil-symbol-word-search t)
  (define-key evil-insert-state-map (kbd "C-w") #'evil-window-map)
  
  ;; Doom-like "j k" to escape insert mode rapidly
  (define-key evil-insert-state-map (kbd "j")
    (lambda () (interactive)
      (let ((prev-char (char-before)))
        (if (and prev-char (eq prev-char ?j))
            (progn (delete-char -1) (evil-normal-state))
          (self-insert-command 1))))))
;; Evil core:1 ends here

;; [[file:readme.org::#h-a9503d9a][Git, shell, files, projects:1]]
(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

(use-package projectile
  :ensure t
  :demand t
  :config
  (projectile-mode 1)
  ;; Tell Projectile where your code lives (adjust paths as needed)
  (setq projectile-project-search-path '("~/w/" "~/Documents"))
  :bind-keymap ("C-c p" . projectile-command-map))

(use-package project
  :ensure nil
  :custom
  (project-switch-commands
   '((project-find-file "Find file")
     (project-dired "Dired")
     (project-eshell "Eshell"))))
;; Git, shell, files, projects:1 ends here

;; [[file:readme.org::#h-3d0b4f1b][Evil extras:1]]
(use-package evil-collection
    :demand t
    :after evil
    :custom
    (evil-collection-setup-minibuffer t)
    (evil-collection-want-unimpaired-p t)
    :config
    ;; Make sure dired is NOT in the removal list
    (setq evil-collection-mode-list (remove 'telega evil-collection-mode-list))
    (evil-collection-init))
    (use-package evil-commentary           ; gcc / gc
      :demand t :after evil
      :config (evil-commentary-mode 1))

    (use-package evil-surround             ; ys / cs / ds
      :demand t :after evil
      :config (global-evil-surround-mode 1))

    (use-package evil-exchange             ; gx
      :demand t :after evil
      :config (evil-exchange-install))

    (use-package evil-matchit              ; better %
      :demand t :after evil
      :config (global-evil-matchit-mode 1))

    (use-package evil-visualstar           ; * and # in visual state
      :demand t :after evil
      :config (global-evil-visualstar-mode 1))

    (use-package evil-numbers              ; increment / decrement number at point
      :after evil
      :bind (:map evil-normal-state-map
                  ("C-c +" . evil-numbers/inc-at-pt)
                  ("C-c -" . evil-numbers/dec-at-pt)
             :map evil-visual-state-map
                  ("C-c +" . evil-numbers/inc-at-pt)
                  ("C-c -" . evil-numbers/dec-at-pt)))

(defun my/evil-shift-visual (dir)
  "Shift the visual selection by DIR (1 = right, -1 = left) and keep it selected."
  (funcall (if (> dir 0) #'evil-shift-right #'evil-shift-left)
           (region-beginning) (region-end))
  (evil-normal-state)
  (evil-visual-restore))
 
(defun my/evil-shift-right-visual () (interactive) (my/evil-shift-visual 1))
(defun my/evil-shift-left-visual  () (interactive) (my/evil-shift-visual -1))
 
(with-eval-after-load 'evil
  (define-key evil-visual-state-map ">" #'my/evil-shift-right-visual)
  (define-key evil-visual-state-map "<" #'my/evil-shift-left-visual))
;; Evil extras:1 ends here

;; [[file:readme.org::#h-eda3655a][Leader key (SPC):1]]
(use-package general
  :demand t
  :after evil
  :config
  (general-evil-setup t)

  (general-create-definer my/leader
    :states '(normal visual insert emacs)
    :prefix "SPC"
    :non-normal-prefix "M-SPC")

  (my/leader
    "SPC" '(execute-extended-command :which-key "M-x")
    ":"   '(eval-expression          :which-key "eval")
    ";"   '(pp-eval-expression       :which-key "pp-eval")

    "b"   '(:ignore t                :which-key "buffers")
    "bb"  '(consult-buffer           :which-key "switch buffer")
    "bd"  '(kill-current-buffer      :which-key "kill buffer")
    "bi"  '(ibuffer                  :which-key "ibuffer")

    "c"   '(:ignore t                :which-key "config")
    "cs"  '(my/package-sync          :which-key "sync packages")
    "cb"  '(my/package-rebuild       :which-key "rebuild (compile)")
    "cc"  '(my/package-cleanup       :which-key "remove unused")

    "f"   '(:ignore t                :which-key "files")
    "ff"  '(find-file                :which-key "find file")
    "fr"  '(consult-recent-file      :which-key "recent files")
    "fs"  '(save-buffer              :which-key "save")

    "g"   '(:ignore t                :which-key "git")
    "gg"  '(magit-status             :which-key "status")

    "p"   '(:ignore t                :which-key "project")
    "pp"  '(project-switch-project   :which-key "switch project")
    "pf"  '(project-find-file        :which-key "find file in project")

    "s"   '(:ignore t                :which-key "search")
    "ss"  '(consult-line             :which-key "search buffer")
    "sp"  '(consult-ripgrep          :which-key "search project")

    "t"   '(:ignore t                :which-key "toggle")
    "tt"  '(modus-themes-toggle      :which-key "theme")
    "tz"  '(my/toggle-zen-mode       :which-key "zen")
    "tb"  '(my/toggle-bidi-direction :which-key "bidi")

    "d"   '(my/open-dashboard :which-key "dashboard")

    "w"   '(:ignore t                :which-key "windows")
    "ww"  '(other-window             :which-key "other window")
    "wd"  '(delete-window            :which-key "delete")
    "w/"  '(split-window-right       :which-key "split right")
    "w-"  '(split-window-below       :which-key "split below")))
;; Leader key (SPC):1 ends here

;; [[file:readme.org::#h-2595f812][BIDI (mixed LTR/RTL text):1]]
(setq-default bidi-display-reordering nil
              bidi-paragraph-direction 'left-to-right)

(defun my/toggle-bidi-direction ()
  "Toggle bidirectional reordering and paragraph direction in this buffer."
  (interactive)
  (setq-local bidi-display-reordering (not bidi-display-reordering))
  (setq-local bidi-paragraph-direction
              (if (eq bidi-paragraph-direction 'left-to-right)
                  'right-to-left
                'left-to-right))
  (message "BIDI reordering: %s | paragraph direction: %s"
           (if bidi-display-reordering "ON" "OFF")
           bidi-paragraph-direction)
  (force-mode-line-update)
  (redraw-display))
;; BIDI (mixed LTR/RTL text):1 ends here

;; [[file:readme.org::#h-c7a5c469][Olivetti (Zen mode):1]]
(defun my/toggle-zen-mode ()
  "Toggle Olivetti (distraction-free) mode."
  (interactive)
  (olivetti-mode 'toggle))

(use-package olivetti
  :commands olivetti-mode
  :custom
  (olivetti-body-width 84)
  (olivetti-minimum-body-width 40)
  (olivetti-recall-visual-line-mode-entry-state t)
  :config
  (defun my/zen-enable ()
    "Hide visual noise while Olivetti is on."
    (display-line-numbers-mode -1)
    (display-fill-column-indicator-mode -1)
    (setq-local indicate-empty-lines nil
                indicate-buffer-boundaries nil))

  (defun my/zen-disable ()
    "Restore programming-buffer decoration when Olivetti is turned off."
    (when (derived-mode-p 'prog-mode)
      (display-line-numbers-mode 1)
      (display-fill-column-indicator-mode 1)))

  (add-hook 'olivetti-mode-on-hook  #'my/zen-enable)
  (add-hook 'olivetti-mode-off-hook #'my/zen-disable))
;; Olivetti (Zen mode):1 ends here

;; [[file:readme.org::#h-29f35118][Core settings:1]]
(use-package org
  :ensure nil
  :hook (org-mode . variable-pitch-mode)   
  :custom
  (org-startup-indented t)
  (org-startup-with-inline-images t)
  (org-hide-emphasis-markers t)
  (org-pretty-entities t)
  (org-list-allow-alphabetical t)
  (org-html-validation-link nil)
  (org-html-link-org-files-as-html t)
  (org-fontify-quote-and-verse-blocks t)
  (org-fontify-whole-heading-line t)
  (org-src-fontify-natively t)
  (org-src-tab-acts-natively t)
  (org-auto-align-tags nil)   
  (org-startup-with-latex-preview nil)       ; Set to 't' if you want math rendered immediately on open
  (org-preview-latex-default-process 'dvisvgm) ; Crisp, scalable SVG previews (no ugly white boxes)
  (org-preview-latex-image-directory "/tmp/ltximg/")
  (org-format-latex-options
   '(:foreground default :background default
     :scale 1.5 :html-foreground "Black" :html-background "Transparent"
     :html-scale 1.5 :matchers ("begin" "$1" "$" "$$" "\\(" "\\["))))
;; Core settings:1 ends here

;; [[file:readme.org::#h-ba7986cb][Org Roam:1]]
(use-package org-roam
  :after org
  :ensure t
  :custom
  (org-roam-directory (expand-file-name "notes" org-directory))
  (org-roam-db-location (expand-file-name ".org-roam.db" user-emacs-directory))
  (org-roam-completion-everywhere t)
  (org-roam-capture-templates
   '(("d" "default" plain "%?"
      :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n")
      :unnarrowed t)))
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture)
         ("C-c n g" . org-roam-graph))
  :config
  (org-roam-db-autosync-mode 1))

(use-package org-roam-ui
  :ensure t
  :after org-roam
  :commands org-roam-ui-mode
  :custom
  (org-roam-ui-sync-theme t)
  (org-roam-ui-follow t)
  (org-roam-ui-update-on-save t)
  (org-roam-ui-open-on-start nil))
;; Org Roam:1 ends here

;; [[file:readme.org::#h-b50b64bd][Automatic CUSTOM_IDs:1]]
(with-eval-after-load 'org
  (require 'org-id)
  (setq org-id-locations-file (expand-file-name ".org-id-locations" user-emacs-directory)
        org-id-link-to-org-use-id 'create-if-interactive-and-no-custom-id)

  (defun my/org-custom-id-get (&optional pom create)
    "Return the CUSTOM_ID of the heading at POM.
When CREATE is non-nil and there is none, create an `h-xxxxxxxx' one."
    (org-with-point-at pom
      (or (org-entry-get nil "CUSTOM_ID")
          (when create
            (let ((id (concat "h-" (substring (md5 (org-id-new)) 0 8))))
              (org-entry-put nil "CUSTOM_ID" id)
              id)))))

  ;; Backwards-compatible name from the previous configuration.
  (defalias 'eos/org-custom-id-get #'my/org-custom-id-get)

  (defun my/org-add-ids-to-headlines ()
    "Add CUSTOM_IDs to all headlines when the file sets `auto-id:t'."
    (when (derived-mode-p 'org-mode)
      (save-excursion
        (save-restriction
          (widen)
          (goto-char (point-min))
          (when (re-search-forward "^#\\+OPTIONS:.*auto-id:t" nil t)
            (org-map-entries (lambda () (my/org-custom-id-get (point) t))))))))

  (add-hook 'org-mode-hook
            (lambda () (add-hook 'before-save-hook #'my/org-add-ids-to-headlines nil t)))

  (add-hook 'org-capture-before-finalize-hook
            (lambda ()
              (when (org-at-heading-p)
                (my/org-custom-id-get (point) t)))))
;; Automatic CUSTOM_IDs:1 ends here

;; [[file:readme.org::#h-d8ec6da9][Export to a mirrored export/ directory, with Tufte CSS:1]]
(defun my/org-export-to-export-dir (orig-fun extension &optional subtreep pub-dir)
  "Mirror the Org source tree under `org-directory'/export/."
  (let* ((org-root    (expand-file-name org-directory))
         (export-root (expand-file-name "export" org-root))
         (file        (buffer-file-name (buffer-base-buffer)))
         (rel         (and file
                           (string-prefix-p org-root (expand-file-name file))
                           (file-relative-name (expand-file-name file) org-root)))
         (pub-dir     (or pub-dir
                          (and rel
                               (expand-file-name (or (file-name-directory rel) "")
                                                 export-root)))))
    (when pub-dir (make-directory pub-dir t))
    (funcall orig-fun extension subtreep pub-dir)))

(advice-add 'org-export-output-file-name :around #'my/org-export-to-export-dir)

(use-package ox-tufte
  :after ox
  :ensure t
  :config
  (defun my/org-html-embed-tufte-css ()
    "Embed tufte.css, ox-tufte.css and IBM Plex overrides in one <style> block."
    (let* ((css-dir (expand-file-name "static/css" org-directory))
           (tufte   (expand-file-name "tufte.css" css-dir))
           (ox      (expand-file-name "ox-tufte.css" css-dir)))
      (concat
       "<link href=\"https://fonts.googleapis.com/css?family=IBM+Plex+Mono\" rel=\"stylesheet\">\n"
       "<link href=\"https://fonts.googleapis.com/css?family=IBM+Plex+Sans\" rel=\"stylesheet\">\n"
       "<link href=\"https://fonts.googleapis.com/css?family=IBM+Plex+Serif\" rel=\"stylesheet\">\n"
       "<style type=\"text/css\">\n"
       "/* ===== tufte.css ===== */\n"
       (if (file-exists-p tufte)
           (with-temp-buffer (insert-file-contents tufte) (buffer-string))
         "/* WARNING: tufte.css not found */\n")
       "\n\n/* ===== ox-tufte.css ===== */\n"
       (if (file-exists-p ox)
           (with-temp-buffer (insert-file-contents ox) (buffer-string))
         "/* WARNING: ox-tufte.css not found */\n")
       "\n\n/* ===== IBM Plex overrides ===== */\n"
       "body, article { font-family: \"IBM Plex Serif\", et-book, Georgia, serif !important; background-color: #fffff8; color: #111; }\n"
       "h1, h2, h3, h4, h5, .sans { font-family: \"IBM Plex Sans\", system-ui, sans-serif !important; font-weight: 500; }\n"
       "code, pre, .org-src-container pre { font-family: \"IBM Plex Mono\", ui-monospace, monospace !important; }\n"
       ".sidenote, .marginnote { font-family: \"IBM Plex Serif\", Georgia, serif; }\n"
       "mjx-container, .MathJax, .katex { margin: 0.6em 0; }\n"
       "/* ===== Math Rendering Fixes ===== */\n"
       "mjx-container, .MathJax, .katex { margin: 0.6em 0; overflow-x: auto;\n"
       "overflow-y: hidden; max-width: 100%; }\n"
       ".org-latex-preview { max-width: 100%; height: auto; }\n"
        "</style>")))

  (setq org-html-head-include-default-style nil
        org-html-head (my/org-html-embed-tufte-css)))
;; Export to a mirrored export/ directory, with Tufte CSS:1 ends here

;; [[file:readme.org::#h-3a8f9c21][LaTeX Export & Compilation:1]]
(use-package ox-latex
  :ensure nil
  :after org
  :custom
  ;; Use latexmk for robust, multi-pass compilation (handles bibtex, glossaries, etc. automatically)
  (org-latex-pdf-process
   '("latexmk -f -pdf -%latex -interaction=nonstopmode -output-directory=%o %f"))
  
  ;; Always use the modern listings/minted setup, or just standard listings
  (org-latex-listings 'minted) ; Requires 'python-pygments' installed on your system
  (org-latex-minted-options
   '(("frame" "lines")
     ("fontsize" "\\footnotesize")
     ("breaklines" "true")
     ("linenos" "true")))

  ;; Essential LaTeX packages to inject into every exported document
  (org-latex-packages-alist
   '(("AUTO" "inputenc" t)
     ("T1" "fontenc" t)
     ("" "amsmath" t)
     ("" "amssymb" t)
     ("" "mathtools" t)
     ("" "mathrsfs" t)
     ("" "braket" t)
     ("" "csquotes" t)
     ("" "microtype" t)))
  
  :config
  ;; Optional: Set a default LaTeX class if you have a custom one, otherwise 'article' is fine
  ;; (setq org-latex-default-class "article")
  )
;; LaTeX Export & Compilation:1 ends here

;; [[file:readme.org::#h-1d8acf37][Tree-sitter, LSP, diagnostics, formatting:1]]
(use-package treesit-auto
  :demand t
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode 1))

(use-package eglot
  :ensure nil
  :hook (((python-base-mode
           c-mode c-ts-mode c++-mode c++-ts-mode
           go-mode go-ts-mode
           rustic-mode rust-ts-mode
           js-mode js-ts-mode typescript-ts-mode tsx-ts-mode
           clojure-mode elixir-mode erlang-mode elm-mode tuareg-mode
           LaTeX-mode)
          . eglot-ensure))
  :custom
  (eglot-autoshutdown t)
  (eglot-extend-to-xref t))

(use-package flymake
  :ensure nil
  :hook (prog-mode . flymake-mode))

(use-package apheleia
  :hook (after-init . apheleia-global-mode)
  :custom
  (apheleia-formatters-respect-indent-level nil))

(use-package flyspell
  :ensure nil
  :hook ((text-mode . flyspell-mode)
         (prog-mode . flyspell-prog-mode)))

(use-package langtool
  :commands (langtool-check langtool-check-buffer)
  :custom
  (langtool-default-language "en-US"))

(use-package yasnippet
  :hook (prog-mode . yas-minor-mode)
  :config
  (yas-reload-all))

(use-package yasnippet-snippets
  :after yasnippet)

(use-package outline
  :ensure nil
  :hook (prog-mode . outline-minor-mode))

(use-package ws-butler
  :hook (prog-mode . ws-butler-mode))

(use-package editorconfig
  :hook (after-init . editorconfig-mode)
  :config
  (defun my/editorconfig-fill-column-minus-10 (props)
    "Set `fill-column' to about 90% of the EditorConfig max_line_length."
    (when-let* ((raw (gethash 'max_line_length props))
                (n   (and (stringp raw)
                          (not (member raw '("off" "unset")))
                          (string-to-number raw)))
                ((> n 10)))
      (setq-local fill-column (- n (/ n 10)))))
  (add-hook 'editorconfig-after-apply-functions
            #'my/editorconfig-fill-column-minus-10))
;; Tree-sitter, LSP, diagnostics, formatting:1 ends here

;; [[file:readme.org::#h-72850ea5][Python:1]]
(defun my/python-uv-activate ()
  "Use the nearest .venv for this buffer (interpreter, PATH, VIRTUAL_ENV)."
  (let* ((root (or (locate-dominating-file default-directory ".venv")
                   (when-let* ((proj (project-current))) (project-root proj))))
         (venv (and root (expand-file-name ".venv" root)))
         (bin  (and venv (expand-file-name
                          (if (eq system-type 'windows-nt) "Scripts" "bin")
                          venv)))
         (python (and bin (expand-file-name
                           (if (eq system-type 'windows-nt) "python.exe" "python")
                           bin))))
    (when (and python (file-exists-p python))
      (setq-local python-shell-interpreter python
                  exec-path (cons bin (remove bin exec-path))
                  process-environment
                  (append (list (concat "VIRTUAL_ENV=" venv)
                                (concat "PATH=" bin path-separator (getenv "PATH"))
                                "PYTHONHOME")      ; no "=": unsets the variable
                          process-environment))
      (message "Activated venv: %s" venv))))

(use-package python
  :ensure nil
  :hook (python-base-mode . my/python-uv-activate)
  :config
  (with-eval-after-load 'eglot
    (when-let* ((exe (or (executable-find "pyrefly")
                         (let ((p (expand-file-name "~/.local/bin/pyrefly")))
                           (and (file-executable-p p) p)))))
      (add-to-list 'eglot-server-programs
                   `((python-mode python-ts-mode) . (,exe "lsp"))))))
;; Python:1 ends here

;; [[file:readme.org::#h-72850ea5][Python:1]]
(defun my/python-uv-activate ()
  "Use the nearest .venv for this buffer (interpreter, PATH, VIRTUAL_ENV)."
  (let* ((root (or (locate-dominating-file default-directory ".venv")
                   (when-let* ((proj (project-current))) (project-root proj))))
         (venv (and root (expand-file-name ".venv" root)))
         (bin  (and venv (expand-file-name
                          (if (eq system-type 'windows-nt) "Scripts" "bin")
                          venv)))
         (python (and bin (expand-file-name
                           (if (eq system-type 'windows-nt) "python.exe" "python")
                           bin))))
    (when (and python (file-exists-p python))
      (setq-local python-shell-interpreter python
                  exec-path (cons bin (remove bin exec-path))
                  process-environment
                  (append (list (concat "VIRTUAL_ENV=" venv)
                                (concat "PATH=" bin path-separator (getenv "PATH"))
                                "PYTHONHOME")
                          process-environment))
      (message "Activated venv: %s" venv))))

(use-package python
  :ensure nil
  :hook (python-base-mode . my/python-uv-activate)
  :config
  (with-eval-after-load 'eglot
    (when-let* ((exe (or (executable-find "pyrefly")
                         (let ((p (expand-file-name "~/.local/bin/pyrefly")))
                           (and (file-executable-p p) p)))))
      (add-to-list 'eglot-server-programs
                   `((python-mode python-ts-mode) . (,exe "lsp"))))))
;; Python:1 ends here

;; [[file:readme.org::#h-7693f750][Languages:1]]
;; C / C++ : handled by treesit-auto + Eglot (clangd).  Keep .h as C.
(add-to-list 'auto-mode-alist '("\\.h\\'" . c-or-c++-mode))

(use-package go-mode
  :defer t)

(use-package rustic
  :mode ("\\.rs\\'" . rustic-mode)
  :custom
  (rustic-lsp-client 'eglot)
  (rustic-format-on-save nil))          ; Apheleia formats on save

(use-package markdown-mode
  :mode (("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :custom (markdown-fontify-code-blocks-natively t))

(use-package yaml-mode
  :mode "\\.ya?ml\\'")

(use-package clojure-mode
  :mode (("\\.clj\\'"  . clojure-mode)
         ("\\.cljs\\'" . clojurescript-mode)
         ("\\.cljc\\'" . clojurec-mode)))

(use-package cider
  :after clojure-mode
  :commands (cider-jack-in cider-connect))

(use-package elixir-mode
  :mode "\\.exs?\\'")

(use-package erlang
  :mode "\\.erl\\'")

(use-package elm-mode
  :mode "\\.elm\\'")

(use-package tuareg
  :mode (("\\.ml\\'"  . tuareg-mode)
         ("\\.mli\\'" . tuareg-mode)))

;; Lean 4 is not on an ELPA: install it from its repository with :vc.
(use-package lean4-mode
  :ensure nil
  :vc (:url "https://github.com/leanprover-community/lean4-mode" :rev :newest)
  :mode "\\.lean\\'")

(use-package geiser-guile
  :defer t
  :custom
  (geiser-guile-binary "guile"))

(use-package auctex
  :mode ("\\.tex\\'" . LaTeX-mode)
  :custom
  (TeX-auto-save t)
  (TeX-parse-self t)
  (TeX-PDF-mode t))

(use-package graphviz-dot-mode
  :mode "\\.dot\\'"
  :custom (graphviz-dot-indent-width 2))

;; Templates and Vue/Svelte.  Declared after treesit-auto so these patterns
;; are pushed in front of its auto-mode entries.
(use-package web-mode
  :mode (("\\.html?\\'"    . web-mode)
         ("\\.vue\\'"      . web-mode)
         ("\\.svelte\\'"   . web-mode)
         ("\\.erb\\'"      . web-mode)
         ("\\.jinja2?\\'"  . web-mode)))
;; Languages:1 ends here

;; [[file:readme.org::#h-a9503d9a][Git, shell, files, projects:1]]
(use-package magit
  :bind ("C-x g" . magit-status))

(use-package vterm
  :commands vterm
  :config
  ;; Keep `shell-file-name' POSIX (fish breaks `&&', `$(...)', ...).
  ;; Use fish only for interactive vterm sessions.
  (when-let* ((fish (executable-find "fish")))
    (setq vterm-shell fish)))

(use-package project
  :ensure nil
  :custom
  (project-switch-commands
   '((project-find-file "Find file")
     (project-find-regexp "Find regexp")
     (project-dired "Dired")
     (project-vc-dir "VC-Dir")
     (project-eshell "Eshell")
     (magit-project-status "Magit"))))

(use-package dired
  :ensure nil
  :custom
  (dired-listing-switches "-agho --group-directories-first")
  (dired-kill-when-opening-new-dired-buffer t))

(use-package diredfl
  :hook (dired-mode . diredfl-mode))

(use-package nerd-icons-dired
  :hook (dired-mode . nerd-icons-dired-mode))

(use-package ibuffer
  :ensure nil
  :bind ("C-x C-b" . ibuffer))

(use-package ibuffer-vc
  :hook (ibuffer-mode . ibuffer-vc-set-filter-groups-by-vc-root))

(use-package tramp
  :ensure nil
  :custom (tramp-default-method "ssh"))

(use-package vundo
  :commands vundo)
;; Git, shell, files, projects:1 ends here

;; [[file:readme.org::#h-82980190][Lookup, run, containers, passwords, notes, citations:1]]
(use-package quickrun
  :commands quickrun)

(use-package docker
  :commands docker)

(use-package pass
  :commands pass)

(use-package citar
  :commands (citar-insert-citation citar-open)
  :custom
  (citar-bibliography (list (expand-file-name "refs.bib" org-directory))))

(use-package deft
  :commands deft
  :custom
  (deft-directory org-directory)
  (deft-extensions '("org" "md" "txt"))
  (deft-recursive t))
;; Lookup, run, containers, passwords, notes, citations:1 ends here

;; [[file:readme.org::#h-a8e094c8][Telegram (via the local SOCKS5 proxy):1]]
(use-package telega
  :commands telega
  :custom
  (telega-use-images '(scale rotate90))
  (telega-server-libs-prefix "/usr")         ; adjust if needed
  (telega-chat-bidi-display-reordering t)
  (telega-proxies
   '((:server "127.0.0.1" :port 10808 :enable t
      :type (:@type "proxyTypeSocks5"))))
  :hook ((telega-chat-mode telega-root-mode) .
         (lambda () (display-line-numbers-mode -1))))
;; Telegram (via the local SOCKS5 proxy):1 ends here

;; [[file:readme.org::#h-b68e630a][IRC (Circe) with passwords from =pass=:1]]
(use-package circe
  :commands circe
  :config
  (require 'auth-source-pass)
  (setq circe-network-options
        `(("Libera"
           :host "irc.libera.chat"
           :port 6697
           :tls t
           :nick "komeil"
           :user "komeil"
           :nickserv-password
           ,(lambda (&rest _) (auth-source-pass-get 'secret "irc/libera"))
           :channels ("#gnu" "#guix" "#voidlinux" "#xbps" "#org-mode")))))
;; IRC (Circe) with passwords from =pass=:1 ends here

;; [[file:readme.org::#h-9796e496][RSS (Elfeed):1]]
(use-package elfeed
  :ensure t
  :commands (elfeed elfeed-update)
  :custom
  ;; Keep the database inside .emacs.d instead of cluttering ~/.elfeed
  (elfeed-db-directory (expand-file-name "elfeed" user-emacs-directory))
  :config
  (setq elfeed-search-filter "@6-months-ago +unread"))

(use-package elfeed-org
  :ensure t
  :demand t
  :after elfeed
  :custom
  ;; Tell elfeed-org where your feeds file is
  (rmh-elfeed-org-files (list (expand-file-name "elfeed.org" org-directory)))
  :config
  (elfeed-org))
;; RSS (Elfeed):1 ends here

;; [[file:readme.org::#h-5275da7d][Package helpers:1]]
(defun my/package-sync ()
  "Refresh the archives and install every selected package that is missing."
  (interactive)
  (package-refresh-contents)
  (package-install-selected-packages 'noconfirm)
  (message "Package sync finished."))

(defun my/package-rebuild ()
  "Byte-compile installed packages and queue native compilation quietly."
  (interactive)
  (message "Rebuilding packages...")
  ;; The 't' at the end means "no error on failure", keeping it quiet
  (byte-recompile-directory package-user-dir 0 t) 
  
  (when (and (fboundp 'native-compile-async) (native-comp-available-p))
    (native-compile-async package-user-dir 'recursively))
  (message "Rebuild finished."))

(defun my/package-cleanup ()
  "Remove packages that are no longer selected (asks for confirmation)."
  (interactive)
  (package-autoremove))
;; Package helpers:1 ends here

;; [[file:readme.org::#h-04bc138f][Local scripts (load.d):1]]
(let ((load-d (expand-file-name "load.d" user-emacs-directory)))
  (when (file-directory-p load-d)
    (dolist (file (directory-files load-d t "\\.el\\'"))
      (condition-case err
          (load file nil 'nomessage)
        (error (message "load.d: failed to load %s: %s" file err))))))
;; Local scripts (load.d):1 ends here

;; [[file:readme.org::#h-716fea55][Tangle on save:1]]
(defun my/tangle-config-on-save ()
  "Tangle the configuration when the buffer is `my/config-org'."
  (when (and buffer-file-name (file-equal-p buffer-file-name my/config-org))
    (org-babel-tangle)
    (message "Tangled early-init.el and init.el")))

(add-hook 'org-mode-hook
          (lambda () (add-hook 'after-save-hook #'my/tangle-config-on-save nil t)))
;; Tangle on save:1 ends here
