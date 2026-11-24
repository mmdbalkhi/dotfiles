;;; init.el --- Personal configuration -*- lexical-binding: t; no-byte-compile: t -*-
;; Generated from readme.org – edit the Org file, not this one.

(require 'cl-lib)   ; cl-incf, cl-subseq, cl-remove-if, ...
(require 'seq)      ; seq-take, seq-filter, ...
(require 'subr-x)   ; string-trim, when-let*, if-let*, ...

;; Prefer the .el over a stale .elc.  Costs a stat() per load, saves hours of
;; debugging "why is my change not taking effect".
(setq load-prefer-newer t)

;; ---------------------------------------------------------------------------
;; Literate config location + tangle on save
;; ---------------------------------------------------------------------------
(defvar my/config-org
  (expand-file-name "readme.org"
                    (file-name-directory (file-truename user-init-file)))
  "This literate configuration file.")

(defun my/tangle-config-maybe ()
  "Re-tangle `my/config-org' when it is the file being saved."
  (when (and buffer-file-name
             (string= (file-truename buffer-file-name)
                      (file-truename my/config-org)))
    (require 'ob-tangle)
    (let ((org-confirm-babel-evaluate nil))
      (org-babel-tangle-file my/config-org))))

;; The variable above always promised tangle-on-save; actually wire it up.
(add-hook 'after-save-hook #'my/tangle-config-maybe)

;; ---------------------------------------------------------------------------
;; First-boot progress reporting
;; ---------------------------------------------------------------------------
(defvar my/install-count 0
  "Number of packages installed during this session.")

(when my/first-boot
  (message "First boot: installing packages, this may take a while...")
  ;; Only advise on first boot: no per-call overhead on normal startups.
  (advice-add 'straight-use-package :around
              (lambda (orig-fun &rest args)
                (cl-incf my/install-count)
                (message "[%d] Building %s ..." my/install-count (car args))
                (apply orig-fun args))))

(add-hook 'emacs-startup-hook
          (lambda ()
            (when my/first-boot
              (message "First boot complete: %d package(s). Restart Emacs."
                       my/install-count)
              ;; The initial frame was hidden in early-init.el.
              (unless (daemonp)
                (set-frame-parameter (selected-frame) 'visibility t)))))

;; ---------------------------------------------------------------------------
;; Customize file
;; ---------------------------------------------------------------------------
;; Set it before anything can call `customize-set-variable', so Emacs never
;; appends a custom block to init.el.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file 'noerror 'nomessage)

;; ---------------------------------------------------------------------------
;; use-package
;; ---------------------------------------------------------------------------
(setq straight-use-package-by-default t)
(straight-use-package 'use-package)
(require 'use-package)

;; NOTE: `use-package-expand-minimally' used to be t here.  It strips the
;; `with-demoted-errors' wrappers and several sanity checks, which turns a
;; single broken package into an aborted init.  Leave it off.
(setq use-package-always-ensure nil
      use-package-enable-imenu-support t
      use-package-expand-minimally nil
      use-package-verbose nil)

;; ---------------------------------------------------------------------------
;; Pin Org to the built-in copy
;; ---------------------------------------------------------------------------
;; Must happen before any package that depends on Org (org-roam, elfeed-org,
;; ox-tufte, dashboard's agenda section), otherwise straight pulls a second Org
;; and you get a mixed installation with broken autoloads.
(straight-use-package '(org :type built-in))

;; [[file:readme.org::#h-fad8804a][Identity and paths:1]]
(defun my/git-config (key)
  "Return the git config value for KEY, or nil when git/key is missing."
  (when (executable-find "git")
    (let ((out (with-temp-buffer
                 (when (zerop (call-process "git" nil t nil "config" "--get" key))
                   (string-trim (buffer-string))))))
      (and out (not (string-empty-p out)) out))))

(setq user-full-name    (or (my/git-config "user.name")  (getenv "USER")  "user")
      user-mail-address (or (my/git-config "user.email") (getenv "EMAIL")
                            "user@example.com"))

;; `expand-file-name' resolves "~"; the trailing slash in the argument is
;; preserved, so `org-directory' is already a proper directory name.
(setq org-directory (expand-file-name "~/Documents/org/"))

(defun my/normalise-dir (dir)
  "Return DIR as an absolute directory name with exactly one trailing slash.
Every root used by project.el, Projectile or Dired must go through this:
a root without a trailing slash is what produces `dirfile' concatenations."
  (file-name-as-directory (expand-file-name dir)))
;; Identity and paths:1 ends here

;; [[file:readme.org::#h-1c7e3d14][Server:1]]
(defvar my/start-server t
  "Non-nil means a plain (non-daemon) Emacs also starts the server.")

(add-hook 'after-init-hook
          (lambda ()
            (require 'server)
            ;; `server-running-p' returns non-nil for a foreign server too,
            ;; which is exactly what we want: do not steal the socket.
            (when (and my/start-server (not (daemonp)) (not (server-running-p)))
              (server-start))))
;; Server:1 ends here

;; [[file:readme.org::#h-e951091c][GC and idle housekeeping:1]]
;; Collect when Emacs has been idle for five minutes.  `t' means repeat.
(run-with-idle-timer 300 t #'garbage-collect)

;; Reap file buffers that have not been displayed for 24h.  Runs every 12h.
(run-with-idle-timer
 (* 12 3600) t
 (lambda ()
   (dolist (buf (buffer-list))
     (let ((shown (buffer-local-value 'buffer-display-time buf)))
       (when (and (buffer-live-p buf)
                  (not (buffer-modified-p buf))
                  (not (minibufferp buf))
                  (buffer-file-name buf)          ; only file buffers
                  (not (string-prefix-p " " (buffer-name buf)))
                  ;; `buffer-display-time' is nil for never-displayed buffers;
                  ;; calling `time-since' on nil used to signal an error here.
                  shown
                  (> (float-time (time-since shown)) 86400))
         (kill-buffer buf))))))
;; GC and idle housekeeping:1 ends here

;; [[file:readme.org::#h-107368dc][Editing defaults:1]]
(electric-indent-mode 1)
(electric-pair-mode 1)      ; the only auto-pairing package; puni handles structure
(save-place-mode 1)         ; remember point per file (the modern API)
(savehist-mode 1)
(recentf-mode 1)
(global-auto-revert-mode 1)
(global-so-long-mode 1)     ; protects against minified/one-line files
(delete-selection-mode 1)   ; typing replaces the region
(repeat-mode 1)             ; C-x z z z ...
(blink-cursor-mode -1)

;; Wrap at word boundaries everywhere; `visual-line-mode' rebinds C-a/C-e/C-k
;; to operate on screen lines, which is what Evil's `evil-respect-visual-line-mode'
;; expects.
(setq-default word-wrap t truncate-lines nil)
(global-visual-line-mode 1)

(setq ring-bell-function 'ignore
      global-auto-revert-non-file-buffers t
      auto-revert-verbose nil
      auto-revert-avoid-polling t      ; use file notifications where available
      recentf-max-saved-items 200
      ;; `auto-insert-mode' with a nil query silently inserts templates; keep
      ;; the mode off until you actually define `auto-insert-alist' entries.
      auto-insert-query nil)

;; Hippie expand: dabbrev + file names + Lisp symbols.
(global-set-key (kbd "M-/") #'hippie-expand)
;; Duplicate line or region.
(global-set-key (kbd "C-c d") #'duplicate-dwim)
;; Editing defaults:1 ends here

;; [[file:readme.org::#h-backups][History, backups and auto-save:1]]
(defvar my/backup-dir (expand-file-name "backups/" user-emacs-directory))
(defvar my/autosave-dir (expand-file-name "autosaves/" user-emacs-directory))
(make-directory my/backup-dir t)
(make-directory my/autosave-dir t)

(setq backup-directory-alist `(("." . ,my/backup-dir))
      auto-save-file-name-transforms `((".*" ,my/autosave-dir t))
      backup-by-copying t         ; do not break hard links / symlinks
      delete-old-versions t
      kept-new-versions 6
      kept-old-versions 2
      version-control t
      create-lockfiles nil)       ; .#foo files break some file watchers

;; Persist the search rings and the kill ring across sessions.
(setq savehist-additional-variables '(search-ring regexp-search-ring kill-ring)
      savehist-autosave-interval 60)
;; History, backups and auto-save:1 ends here

;; [[file:readme.org::#h-1269dbae][Large, remote and symlinked files:1]]
(defvar my/large-file-threshold (* 1024 1024)
  "Buffers larger than this many characters get heavy features disabled.")

(defun my/large-file-setup ()
  "Disable expensive features in very large buffers."
  (when (> (buffer-size) my/large-file-threshold)
    (display-line-numbers-mode -1)
    (font-lock-mode -1)
    (when (bound-and-true-p flymake-mode)  (flymake-mode -1))
    ;; Flycheck was previously left running on multi-megabyte buffers.
    (when (bound-and-true-p flycheck-mode) (flycheck-mode -1))
    (when (bound-and-true-p indent-bars-mode) (indent-bars-mode -1))
    (setq-local undo-fu-session-inhibit t)
    (message "Large file: heavy features disabled.")))

(defun my/heavy-features-off-maybe ()
  "Turn off costly integrations for REMOTE files only.
Symlinks are normal (dotfiles, straight build trees); they must NOT disable
LSP.  Previously this shut Eglot down for symlinks too, which is why
`flycheck-eglot-mode' appeared to do nothing."
  (when (and buffer-file-name (file-remote-p buffer-file-name))
    (when (bound-and-true-p diff-hl-mode) (diff-hl-mode -1))
    (auto-revert-mode -1)))

;; Depth 90 so these run after the major mode and its own hooks.
(add-hook 'find-file-hook #'my/large-file-setup 90)
(add-hook 'find-file-hook #'my/heavy-features-off-maybe 90)

;; Line numbers everywhere else.
(global-display-line-numbers-mode 1)
(setq display-line-numbers-type 'relative)  ; pairs naturally with Evil counts
;; Large, remote and symlinked files:1 ends here

;; [[file:readme.org::#h-b86876f7][Clipboard (Wayland):1]]
(setq select-enable-clipboard t
      select-enable-primary t)

(when (and (executable-find "wl-copy") (executable-find "wl-paste"))
  (defun my/wl-copy (text &optional _push)
    "Copy TEXT to the Wayland clipboard using wl-copy."
    (with-temp-buffer
      (insert text)
      ;; -n: do not append a newline that was not in the region.
      (call-process-region (point-min) (point-max) "wl-copy" nil nil nil "-n")))

  (defun my/wl-paste ()
    "Return the Wayland clipboard contents, or nil when empty."
    (let ((text (shell-command-to-string "wl-paste --no-newline")))
      (and (> (length text) 0) text)))

  (setq interprogram-cut-function   #'my/wl-copy
        interprogram-paste-function #'my/wl-paste))
;; Clipboard (Wayland):1 ends here

;; [[file:readme.org::#h-5182d5ed][Fonts:1]]
;; Rendering knobs.  `inhibit-compacting-font-caches' matters a lot with Nerd
;; Font icon ranges: without it Emacs periodically stalls to compact the cache.
(setq x-underline-at-descent-line t
      x-use-underline-position-properties t
      font-lock-maximum-decoration t
      inhibit-compacting-font-caches t)

(setopt line-spacing 0.15)
(setq-default line-spacing 0.15)

;; Fontsets are global, not per frame, so they can be set once here.
(when (fboundp 'set-fontset-font)
  ;; Emoji fallback.
  (set-fontset-font t 'unicode "Noto Color Emoji" nil 'append)
  ;; Persian/Arabic: Vazirmatn first, Noto Sans Arabic as fallback.
  ;; `append' keeps the default font for characters these fonts lack.
  (dolist (charset '(arabic))
    (set-fontset-font t charset "Vazirmatn" nil 'append)
    (set-fontset-font t charset "Noto Sans Arabic" nil 'append)))

(defvar my/font-family "BlexMono Nerd Font Mono"
  "Monospace font used for code and the default face.")
(defvar my/variable-font-family "IBM Plex Sans"
  "Proportional font used for Org and other prose.")

(defun my/apply-fonts (&optional frame)
  "Set the default, fixed-pitch and variable-pitch faces on FRAME."
  (with-selected-frame (or frame (selected-frame))
    (when (display-graphic-p)
      (when (find-font (font-spec :family my/font-family))
        (set-face-attribute 'default nil :family my/font-family
                            :height 180 :weight 'semi-light)
        (set-face-attribute 'fixed-pitch nil :family my/font-family :height 1.0))
      (when (find-font (font-spec :family my/variable-font-family))
        (set-face-attribute 'variable-pitch nil :family my/variable-font-family
                            :height 190)))))

;; Every new emacsclient frame gets the fonts too.
(add-hook 'after-make-frame-functions #'my/apply-fonts)
(unless (daemonp) (my/apply-fonts))
;; Fonts:1 ends here

;; [[file:readme.org::#h-a33332db][Theme:1]]
;; Mixed fonts: `fixed-pitch' inside tables/source blocks even when the buffer
;; is in `variable-pitch-mode'.
(setopt modus-themes-mixed-fonts t
        modus-themes-headings '((t . (variable-pitch)))
        modus-themes-italic-constructs t)

;; Mode-line borders: remove them for a flat look.  Must precede `load-theme'.
(setopt modus-themes-common-palette-overrides
        '((border-mode-line-active   unspecified)
          (border-mode-line-inactive unspecified)))

;; The theme itself lives in a Git repository, not on an ELPA.
(use-package persian-landscapes-themes
  :straight (persian-landscapes-themes
             :type git :host github :repo "mmdbalkhi/persian-landscapes")
  :demand t
  :config
  ;; NOERROR = t: do not abort init if the theme file is missing.
  (load-theme 'goy-dark t))
;; Theme:1 ends here

;; [[file:readme.org::#h-c21db571][Mode-line:1]]
;; ── 1. Language version ────────────────────────────────────────────────────
;; Probed once per (executable, directory) pair, on idle, never synchronously
;; inside `after-change-major-mode-hook'.
(defvar-local my/lang-version nil
  "Propertized language version string, e.g. \"Py 3.12.3\".")

(defvar my/lang-version-cache (make-hash-table :test 'equal)
  "Cache of (EXECUTABLE . DIRECTORY) -> version string.")

(defun my/lang-version--spec ()
  "Return (LABEL EXECUTABLE ARG...) for this buffer's language, or nil."
  (cond ((derived-mode-p 'python-base-mode)
         (list "Py" (or (and (boundp 'python-shell-interpreter)
                             (executable-find python-shell-interpreter))
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
  (when exe
    (with-temp-buffer
      (when (zerop (apply #'call-process exe nil t nil args))
        (goto-char (point-min))
        (when (re-search-forward "[0-9]+\\(?:\\.[0-9]+\\)+" nil t)
          (match-string 0))))))

(defun my/lang-version-update ()
  "Fill `my/lang-version' for the current buffer, using the cache."
  (setq my/lang-version nil)
  (when-let* (((not (file-remote-p default-directory)))
              (spec (my/lang-version--spec))
              (exe  (cadr spec))
              (key  (cons exe default-directory)))
    (let ((ver (gethash key my/lang-version-cache 'unset)))
      (when (eq ver 'unset)
        (setq ver (my/lang-version--run exe (cddr spec)))
        (puthash key ver my/lang-version-cache))
      (when ver
        (setq my/lang-version
              (propertize (format "%s %s" (car spec) ver)
                          'face 'font-lock-type-face))
        (force-mode-line-update)))))

(defun my/lang-version-schedule ()
  "Defer the version probe so opening a file never blocks on a subprocess."
  (let ((buf (current-buffer)))
    (run-with-idle-timer
     0.5 nil (lambda () (when (buffer-live-p buf)
                          (with-current-buffer buf (my/lang-version-update)))))))

(add-hook 'after-change-major-mode-hook #'my/lang-version-schedule)

;; ── 2. Flycheck status ─────────────────────────────────────────────────────
(defvar-local my/flycheck-status nil
  "Propertized Flycheck summary, e.g. \"E:2 W:1\" or a check mark.")

(defun my/flycheck-update (&rest _)
  "Recompute `my/flycheck-status' from the last Flycheck result."
  (setq my/flycheck-status
        (when (bound-and-true-p flycheck-mode)
          (pcase flycheck-last-status-change
            ((or 'running 'no-checker 'not-checked) nil)
            (_ (let* ((counts (flycheck-count-errors flycheck-current-errors))
                      (err  (or (alist-get 'error counts) 0))
                      (warn (or (alist-get 'warning counts) 0)))
                 (if (or (> err 0) (> warn 0))
                     (propertize (format "E:%d W:%d" err warn)
                                 'face 'font-lock-warning-face)
                   (propertize "✓" 'face 'success)))))))
  (force-mode-line-update))

(with-eval-after-load 'flycheck
  (add-hook 'flycheck-after-syntax-check-hook #'my/flycheck-update)
  (add-hook 'flycheck-status-changed-functions #'my/flycheck-update)
  (add-hook 'flycheck-mode-hook #'my/flycheck-update))

;; ── 3. VC branch + file state (cached) ─────────────────────────────────────
;; `vc-mode' is a buffer-local string maintained by VC itself.  We only call
;; `vc-state' when that string changes, not on every redraw.
(defvar-local my/ml--vc-cache nil
  "Cons of (VC-MODE-VALUE . rendered string).")

(defun my/ml--vc-state-prefix (file backend)
  "Return a one-character state marker for FILE under BACKEND."
  (pcase (ignore-errors (vc-state file backend))
    ((or 'up-to-date 'edited 'nil) "")
    ((or 'removed 'conflict 'unregistered) "!")
    ((or 'needs-update 'needs-merge) "^")
    ('added "+")
    (_ "")))

(defun my/ml-branch ()
  "Return the VC branch plus a compact file-state marker, or nil."
  (when (stringp vc-mode)
    (if (equal (car my/ml--vc-cache) vc-mode)
        (cdr my/ml--vc-cache)
      (let* ((clean (string-trim
                     (replace-regexp-in-string
                      "\\` *[[:alpha:]]+[-:@!?\\^]" ""
                      (substring-no-properties vc-mode))))
             (backend (and buffer-file-name
                           (ignore-errors
                             (vc-responsible-backend buffer-file-name))))
             (state (if (and buffer-file-name backend)
                        (my/ml--vc-state-prefix buffer-file-name backend)
                      ""))
             (rendered (unless (string-empty-p clean)
                         (propertize (concat state clean " ")
                                     'face 'font-lock-doc-face))))
        (setq my/ml--vc-cache (cons vc-mode rendered))
        rendered))))

;; Invalidate the cache when the file is written or reverted.
(defun my/ml-vc-invalidate () (setq my/ml--vc-cache nil))
(add-hook 'after-save-hook #'my/ml-vc-invalidate)
(add-hook 'after-revert-hook #'my/ml-vc-invalidate)

;; ── 4. Path truncation ─────────────────────────────────────────────────────
(defvar my/ml-path-keep-tail 2
  "Number of trailing path components (including the file name) to keep.")

(defun my/ml--shrink-segment (seg)
  "Shrink directory segment SEG to its first character (two if it is dotted)."
  (if (string-empty-p seg)
      seg
    (substring seg 0 (if (string-prefix-p "." seg) (min (length seg) 2) 1))))

(defun my/ml-path ()
  "Return a compact path: ~/p/…/tail/dir/file."
  (let* ((raw (if buffer-file-name
                  (abbreviate-file-name buffer-file-name)
                (buffer-name)))
         (parts (split-string raw "/" t))
         (n (length parts)))
    (propertize
     (cond
      ((not buffer-file-name) raw)
      ((<= n (1+ my/ml-path-keep-tail)) raw)
      (t (let* ((idx  (max 0 (- n my/ml-path-keep-tail)))
                (head (mapcar #'my/ml--shrink-segment (cl-subseq parts 0 idx)))
                (tail (cl-subseq parts idx)))
           (concat (if (string-prefix-p "~" raw) "~/" "/")
                   (string-join head "/") "/…/" (string-join tail "/")))))
     'face 'mode-line-buffer-id)))

;; ── 5. Eglot indicator ─────────────────────────────────────────────────────
(defun my/ml-lsp ()
  "Return \" LSP\" when Eglot manages this buffer and a server is live."
  (when (and (featurep 'eglot)
             (eglot-managed-p)
             (eglot-current-server))
    (propertize " LSP" 'face 'success)))

;; ── 6. Format ──────────────────────────────────────────────────────────────
;; `evil-mode-line-tag' is a variable, not a function; it is nil until Evil
;; loads, which is harmless.  `mode-line-format-right-align' right-aligns
;; everything that follows it.
(setq-default
 mode-line-format
 '("%e" evil-mode-line-tag mode-line-modified " "
   (:eval (my/ml-branch))
   (:eval (my/ml-path))
   " %l:%c"
   mode-line-format-right-align
   (my/flycheck-status (" " my/flycheck-status))
   (:eval (my/ml-lsp))
   (my/lang-version (" " my/lang-version) (" " mode-name))
   mode-line-end-spaces))

(set-face-attribute 'mode-line nil :height 1.0 :box nil)
(set-face-attribute 'mode-line-inactive nil :height 1.0 :box nil)
;; Mode-line:1 ends here

;; [[file:readme.org::#h-d7822f7c][Dashboard:1]]
(defvar my/reading-list
  '(("Category Theory in Context"      . "Riehl")
    ("Software Foundations, Vol. 1"    . "Pierce et al.")
    ("Types and Programming Languages" . "Pierce")
    ("Practical Foundations for PL"    . "Harper"))
  "Books shown in the dashboard reading section.")

(use-package dashboard
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
  ;; project.el, not Projectile: one project backend for the whole config.
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
  ;; A custom section generator must be registered before `dashboard-items'
  ;; is rendered; `:config' runs after `:custom', which is the right order.
  (defun my/dashboard-reading (list-size)
    "Insert up to LIST-SIZE entries of `my/reading-list'."
    (dashboard-insert-heading "Currently Reading")
    (insert "\n")
    (dolist (book (seq-take my/reading-list list-size))
      (insert "    " (car book)
              (propertize (format "  (%s)" (cdr book)) 'face 'shadow)
              "\n")))
  (add-to-list 'dashboard-item-generators '(reading . my/dashboard-reading))

  ;; Under a daemon there is no initial frame to show the dashboard on.
  (unless (daemonp)
    (dashboard-setup-startup-hook)))

(defun my/open-dashboard ()
  "Show the dashboard in the current window, creating it if needed."
  (interactive)
  (require 'dashboard)
  (if (get-buffer dashboard-buffer-name)
      (progn (switch-to-buffer dashboard-buffer-name)
             (dashboard-refresh-buffer))
    (dashboard-open)))
;; Dashboard:1 ends here

;; [[file:readme.org::#h-ffa8a174][Code and text decoration:1]]
;; Vertical indentation guides; tree-sitter aware when a grammar is present.
(use-package indent-bars
  :hook (prog-mode . indent-bars-mode)
  :custom
  (indent-bars-treesit-support t)
  (indent-bars-treesit-ignore-blank-lines-prefix nil))

;; Colour nested parentheses by depth.
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; Highlight TODO/FIXME/... in comments and strings.
(use-package hl-todo
  :hook (prog-mode . hl-todo-mode)
  :custom
  (hl-todo-keyword-faces
   '(("TODO"   . "#ff6c6b") ("FIXME" . "#ff6c6b") ("NOTE" . "#ecbe7b")
     ("HACK"   . "#da8548") ("REVIEW" . "#51afef"))))

;; A thin vertical rule at `fill-column'.  Built into Emacs since 27.
(use-package display-fill-column-indicator
  :ensure nil :straight (:type built-in)
  :hook (prog-mode . display-fill-column-indicator-mode)
  :custom (display-fill-column-indicator-character ?│)
  :config (set-face-attribute 'fill-column-indicator nil :foreground "#5B6268"))

;; Font ligatures.  The prog-mode list is deliberately conservative: it only
;; contains sequences that are unambiguous in the languages used here.
(use-package ligature
  :hook (after-init . global-ligature-mode)
  :config
  (ligature-set-ligatures 't '("www"))
  (ligature-set-ligatures
   'prog-mode
   '("**" "***" "**/" "*>" "*/" "\\\\" "\\\\\\" "{-" "::" ":::" ":="
     "!!" "!=" "!==" "-}" "----" "-->" "->" "->>" "-<" "-<<" "-~"
     "#{" "#[" "##" "###" "####" "#(" "#?" "#_" "#_(" ".-" ".=" ".."
     "..<" "..." "?=" "??" ";;" "/*" "/**" "/=" "/==" "/>" "//" "///"
     "&&" "||" "||=" "|=" "|>" "^=" "$>" "++" "+++" "+>" "=:=" "=="
     "===" "==>" "=>" "=>>" "<=" "=<<" "=/=" ">-" ">=" ">=>" ">>"
     ">>-" ">>=" ">>>" "<*" "<*>" "<|" "<|>" "<$" "<$>" "<!--" "<-"
     "<--" "<->" "<+" "<+>" "<==" "<=>" "<=<" "<>" "<<" "<<-" "<<="
     "<<<" "<~" "<~~" "</" "</>" "~@" "~-" "~>" "~~" "~~>" "%%")))
;; Code and text decoration:1 ends here

;; [[file:readme.org::#h-23c730da][Visual feedback:1]]
;; silence beacon warnings
;; Warning: the function ‘beacon--seq-mapn’ is not known to be defined.

(add-to-list 'native-comp-jit-compilation-deny-list "/beacon\\.el")
;; Flash the cursor line after a big jump.
(use-package beacon
  :hook (after-init . beacon-mode)
  :custom (beacon-size 20))

;; Briefly highlight yanked/changed regions.
(use-package volatile-highlights
  :hook (after-init . volatile-highlights-mode))

;; Git change indicators in the fringe.  The Dired integration lives in
;; `diff-hl-dired.el', so we require it explicitly instead of relying on an
;; autoload from the `diff-hl' feature (that is the same class of bug as the
;; dired-subtree one).
(use-package diff-hl
  :hook ((after-init         . global-diff-hl-mode)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :config
  (require 'diff-hl-dired)
  (add-hook 'dired-mode-hook #'diff-hl-dired-mode))

;; Emoji rendering.  Note this competes with the Noto Color Emoji fontset for
;; the same code points; emojify wins where it has an image.
(use-package emojify
  :hook (after-init . global-emojify-mode))

;; Sub-line precision scrolling (Emacs 29+).  Replaces smooth-scrolling.
(when (fboundp 'pixel-scroll-precision-mode)
  (pixel-scroll-precision-mode 1))
;; Visual feedback:1 ends here

;; [[file:readme.org::#h-979a5beb][Tabs, workspaces and popups:1]]
(use-package tab-bar
  :ensure nil :straight (:type built-in)
  :demand t
  :custom
  (tab-bar-show 1)                  ; hide the bar when there is only one tab
  (tab-bar-close-button-show nil)
  (tab-bar-new-button-show nil)
  :config (tab-bar-mode 1))

;; Project-scoped workspaces on top of tab-bar.
(use-package tabspaces
  :after tab-bar
  :hook (after-init . tabspaces-mode)
  :custom
  (tabspaces-use-vc t)
  (tabspaces-initialize-project-with-todo nil))

;; Treat shells, help and compilation buffers as dismissible popups.
(use-package popper
  :bind (("C-`"   . popper-toggle)
         ("M-`"   . popper-cycle)
         ("C-M-`" . popper-toggle-type))
  :hook ((after-init . popper-mode)
         (after-init . popper-echo-mode))
  :custom
  (popper-reference-buffers
   '("\\*Messages\\*" "Output\\*$" "\\*Async Shell Command\\*"
     help-mode compilation-mode
     "^\\*eshell.*\\*$" eshell-mode
     "^\\*shell.*\\*$"  shell-mode
     "^\\*term.*\\*$"   term-mode
     "^\\*vterm.*\\*$"  vterm-mode)))
;; Tabs, workspaces and popups:1 ends here

;; [[file:readme.org::#h-f7b48e5c][Minibuffer UI:1]]
(use-package vertico
  :hook (after-init . vertico-mode)
  :custom
  (vertico-cycle t)
  (vertico-resize t)
  (vertico-count 15))

;; IMPORTANT: `vertico-directory' ships *inside* the vertico package.
;; It is NOT an Emacs built-in.  Declaring it (:type built-in) makes straight
;; register a phantom package and can shadow the real file.
(use-package vertico-directory
  :ensure nil :straight nil
  :after vertico
  :bind (:map vertico-map
              ("RET"   . vertico-directory-enter)
              ("DEL"   . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word))
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

(use-package orderless
  :demand t
  :custom
  (completion-styles '(orderless basic))
  ;; `file' keeps partial-completion so that /h/u/l/b expands to /home/user/...
  ;; `project-file' is a SEPARATE category used by project.el; without this
  ;; entry the file settings above simply did not apply to `SPC p f'.
  (completion-category-overrides
   '((file         (styles basic partial-completion))
     (project-file (styles orderless basic))
     (buffer       (styles orderless basic))
     (command      (styles orderless basic))))
  ;; SPC separates components; & / ! / = are orderless affix operators.
  (orderless-component-separator #'orderless-escapable-split-on-space))

(use-package marginalia
  :hook (after-init . marginalia-mode))
;; Minibuffer UI:1 ends here

;; [[file:readme.org::#h-consult][Consult:1]]
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
  ;; Route xref through consult so references get live preview.
  (setq xref-show-xrefs-function       #'consult-xref
        xref-show-definitions-function #'consult-xref))
(use-package consult-dir
  :bind (("C-x C-d" . consult-dir)
         :map minibuffer-local-completion-map
         ("C-x C-d" . consult-dir)
         ("C-x C-j" . consult-dir-jump-file)))
;; Editable grep/occur buffers.  The command is `wgrep-change-to-wgrep-mode';
;; there is no command called `wgrep', so `:commands wgrep' never loaded it.
(use-package wgrep
  :commands (wgrep-change-to-wgrep-mode wgrep-setup)
  :hook (grep-mode . wgrep-setup)
  :custom (wgrep-auto-save-buffer t))

;; Symbol outline in a side window.  The real command is
;; `imenu-list-smart-toggle'; `imenu-list-toggle' does not exist.
(use-package imenu-list
  :bind ("M-s i" . imenu-list-smart-toggle)
  :custom
  (imenu-list-auto-resize t)
  (imenu-list-position 'right)
  (imenu-list-focus-after-activation t))
;; Consult:1 ends here

;; [[file:readme.org::#h-15642158][Embark:1]]
;; Context actions on minibuffer candidates and on the thing at point.
(use-package embark
  :bind (("C-."   . embark-act)
         ("C-;"   . embark-dwim)      ; avy moved to C-' to free this key
         ("C-h B" . embark-bindings))
  :init (setq prefix-help-command #'embark-prefix-help-command))

;; Export a consult-ripgrep session into an editable grep buffer, etc.
(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))
;; Embark:1 ends here

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
  ;; Persist candidate history across sessions.
  (corfu-history-mode 1)
  ;; Documentation popup next to the candidate list.
  (corfu-popupinfo-mode 1)

  ;; Corfu in the minibuffer only where `completion-at-point' is actually
  ;; bound (M-:, eval-expression, ...).  Elsewhere Vertico owns completion.
  (defun my/corfu-enable-in-minibuffer ()
    "Enable Corfu in the minibuffer when `completion-at-point' is bound."
    (when (where-is-internal #'completion-at-point (list (current-local-map)))
      (setq-local corfu-auto nil)
      (corfu-mode 1)))
  (add-hook 'minibuffer-setup-hook #'my/corfu-enable-in-minibuffer))

;; Extra completion-at-point sources.
(use-package cape
  :after corfu
  :demand t
  :config
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-elisp-block)
  ;; pcomplete is noisy and impure; wrap it so it cannot break other capfs.
  (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-silent)
  (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-purify))

;; Ghost-text preview of the top candidate (Emacs 30+).
(use-package completion-preview
  :ensure nil :straight (:type built-in)
  :hook (after-init . global-completion-preview-mode))
;; In-buffer completion:1 ends here

;; [[file:readme.org::#h-43faf67a][Discoverability:1]]
;; Built in since Emacs 30.
(use-package which-key
  :ensure nil :straight (:type built-in)
  :hook (after-init . which-key-mode)
  :custom
  (which-key-idle-delay 0.4)
  (which-key-max-description-length 40))

;; Richer *Help* buffers with source links and real examples.
(use-package helpful
  :bind (("C-h f" . helpful-callable)
         ("C-h v" . helpful-variable)
         ("C-h k" . helpful-key)
         ("C-h x" . helpful-command)))

;; Hide uninteresting minor-mode lighters.  Names must be real mode symbols:
;; `eldoc-box-mode' does not exist, the mode is `eldoc-box-hover-mode'.
(use-package diminish
  :demand t
  :config
  (dolist (mode '(editorconfig-mode eldoc-mode eldoc-box-hover-mode
                  super-save-mode rainbow-mode auto-revert-mode))
    (diminish mode)))
;; Discoverability:1 ends here

;; [[file:readme.org::#h-327a966c][Evil core:1]]
(use-package evil
  :demand t
  :init
  (setq evil-want-integration t
        ;; Must be nil: evil-collection provides the per-mode bindings.
        evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-want-C-i-jump nil
        evil-want-Y-yank-to-eol t
        ;; Emacs 28+ has a native undo-redo ring; no undo-fu needed for Evil.
        evil-undo-system 'undo-redo
        evil-respect-visual-line-mode t
        evil-split-window-below t
        evil-vsplit-window-right t)
  :config
  (evil-mode 1)
  (setq evil-symbol-word-search t)

  ;; Window commands from insert state.
  (define-key evil-insert-state-map (kbd "C-w") #'evil-window-map)

  ;; ── "jj" to leave insert state ───────────────────────────────────────────
  ;; Only treat the second j as an escape when it arrives within
  ;; `my/evil-escape-delay' seconds of the first one.  Anything slower is a
  ;; literal "jj".  `self-insert-command' is called with the actual character
  ;; so that abbrev expansion and Evil's repeat info stay correct.
  (defvar my/evil-escape-delay 0.15
    "Maximum seconds between the two keys of the insert-state escape chord.")
  (defvar my/evil--last-j-time 0)

  (defun my/evil-insert-j ()
    "Insert `j', or escape insert state on a fast double `j'."
    (interactive)
    (let ((now (float-time)))
      (if (and (eq (char-before) ?j)
               (< (- now my/evil--last-j-time) my/evil-escape-delay))
          (progn
            (delete-char -1)
            (setq my/evil--last-j-time 0)
            ;; Record the deletion so `.' repeats it correctly.
            (evil-normal-state))
        (setq my/evil--last-j-time now)
        (self-insert-command 1 ?j))))

  (define-key evil-insert-state-map (kbd "j") #'my/evil-insert-j))
;; Evil core:1 ends here

;; [[file:readme.org::#h-3d0b4f1b][Evil extras:1]]
(use-package evil-collection
  :after evil
  :demand t
  :custom
  (evil-collection-setup-minibuffer t)
  (evil-collection-want-unimpaired-p t)
  :config
  ;; Explicit list = predictable load order and no surprise eager loads.
  ;; `dired' is included; its extra keys are installed later, from a hook,
  ;; so that they win over evil-collection's defaults.
  (evil-collection-init '(dired ibuffer info help helpful magit
                          compile grep xref calendar ediff
                          eshell shell term vterm
                          minibuffer which-key vertico corfu
                          flycheck flymake outline imenu-list
                          doc-view image eldoc)))

(use-package evil-commentary            ; gcc / gc
  :after evil :demand t
  :config (evil-commentary-mode 1))

(use-package evil-surround              ; ys / cs / ds
  :after evil :demand t
  :config (global-evil-surround-mode 1))

(use-package evil-exchange              ; gx
  :after evil :demand t
  :config (evil-exchange-install))

(use-package evil-matchit               ; better %
  :after evil :demand t
  :config (global-evil-matchit-mode 1))

(use-package evil-visualstar            ; * and # in visual state
  :after evil :demand t
  :config (global-evil-visualstar-mode 1))

(use-package evil-numbers               ; C-c + / C-c -
  :after evil
  :bind (:map evil-normal-state-map
              ("C-c +" . evil-numbers/inc-at-pt)
              ("C-c -" . evil-numbers/dec-at-pt)
              :map evil-visual-state-map
              ("C-c +" . evil-numbers/inc-at-pt)
              ("C-c -" . evil-numbers/dec-at-pt)))

;; ── Keep the visual selection after > and < ────────────────────────────────
(defun my/evil-shift-visual (dir)
  "Shift the visual selection by DIR (1 right, -1 left) and reselect it."
  (funcall (if (> dir 0) #'evil-shift-right #'evil-shift-left)
           (region-beginning) (region-end))
  (evil-normal-state)
  (evil-visual-restore))

(defun my/evil-shift-right-visual () (interactive) (my/evil-shift-visual 1))
(defun my/evil-shift-left-visual  () (interactive) (my/evil-shift-visual -1))

(with-eval-after-load 'evil
  (define-key evil-visual-state-map ">" #'my/evil-shift-right-visual)
  (define-key evil-visual-state-map "<" #'my/evil-shift-left-visual))

;; ── ESC quits the minibuffer in every Evil state ───────────────────────────
(with-eval-after-load 'evil-maps
  (dolist (map (list minibuffer-local-map
                     minibuffer-local-ns-map
                     minibuffer-local-completion-map
                     minibuffer-local-must-match-map
                     minibuffer-local-isearch-map))
    (evil-define-key 'insert map (kbd "ESC") #'abort-minibuffers)
    (evil-define-key 'normal map (kbd "ESC") #'abort-minibuffers)))
;; Evil extras:1 ends here

;; [[file:readme.org::#h-eda3655a][Leader key (SPC):1]]
(use-package general
  :after evil
  :demand t
  :config
  (general-evil-setup t)

  (general-create-definer my/leader
    :states '(normal visual motion emacs)
    :keymaps 'override
    :prefix "SPC"
    :non-normal-prefix "M-SPC")

  (my/leader
    "SPC" '(execute-extended-command   :which-key "M-x")
    ":"   '(eval-expression            :which-key "eval")
    ";"   '(pp-eval-expression         :which-key "pp-eval")

    "b"   '(:ignore t                  :which-key "buffers")
    "bb"  '(consult-buffer             :which-key "switch buffer")
    "bd"  '(kill-current-buffer        :which-key "kill buffer")
    "bi"  '(ibuffer                    :which-key "ibuffer")

    "c"   '(:ignore t                  :which-key "config/packages")
    "cs"  '(my/package-sync            :which-key "sync packages")
    "cb"  '(my/package-rebuild         :which-key "rebuild all")
    "cc"  '(my/package-cleanup         :which-key "remove unused repos")

    "f"   '(:ignore t                  :which-key "files")
    "ff"  '(find-file                  :which-key "find file")
    "fr"  '(consult-recent-file        :which-key "recent files")
    "fs"  '(save-buffer                :which-key "save")
    "fd"  '(dired-jump                 :which-key "dired here")

    "g"   '(:ignore t                  :which-key "git")
    "gg"  '(magit-status               :which-key "status")
    "gt"  '(git-timemachine            :which-key "time machine")

    "p"   '(:ignore t                  :which-key "project")
    "pp"  '(project-switch-project     :which-key "switch project")
    "pf"  '(project-find-file          :which-key "find file in project")
    "pd"  '(project-dired              :which-key "dired project root")
    "pr"  '(project-find-regexp        :which-key "find regexp")
    "pb"  '(consult-project-buffer     :which-key "project buffers")

    "s"   '(:ignore t                  :which-key "search")
    "ss"  '(consult-line               :which-key "search buffer")
    "sp"  '(consult-ripgrep            :which-key "search project")
    "sr"  '(wgrep-change-to-wgrep-mode :which-key "editable grep (wgrep)")

    "t"   '(:ignore t                  :which-key "toggle")
    "tt"  '(modus-themes-toggle        :which-key "theme")
    "tz"  '(my/toggle-zen-mode         :which-key "zen")
    "tb"  '(my/toggle-bidi-direction   :which-key "bidi")

    "d"   '(my/open-dashboard          :which-key "dashboard")

    "w"   '(:ignore t                  :which-key "windows")
    "ww"  '(other-window               :which-key "other window")
    "wd"  '(delete-window              :which-key "delete")
    "w/"  '(split-window-right         :which-key "split right")
    "w-"  '(split-window-below         :which-key "split below")))
;; Leader key (SPC):1 ends here

;; [[file:readme.org::#h-project-el][project.el:1]]
(use-package project
  :ensure nil :straight (:type built-in)
  :demand t
  :bind-keymap ("C-x p" . project-prefix-map)
  :custom
  ;; Absolute candidates: no prefix stripping, no re-expansion, no path bugs.
  (project-read-file-name-function #'project--read-file-absolute)
  ;; Show history entries relative to the project root, which is nicer, while
  ;; the candidates themselves stay absolute.
  (project-file-history-behavior 'relativize)
  (project-switch-commands
   '((project-find-file   "Find file")
     (project-find-regexp "Find regexp")
     (project-dired       "Dired")
     (project-vc-dir      "VC-Dir")
     (project-eshell      "Eshell")
     (magit-status        "Magit")))
  :config
  ;; Normalise EVERY root: absolute + exactly one trailing slash.
  ;; This replaces the old `expand-file-name'-only advice.
  (defun my/project-root-normalise (root)
    "Return ROOT as an absolute directory name with a trailing slash."
    (if (stringp root) (my/normalise-dir root) root))
  (advice-add 'project-root :filter-return #'my/project-root-normalise)

  ;; Treat every direct subdirectory of ~/w as a project even without a VCS
  ;; build the root from the first path component.
  (defun my/project-try-w (dir)
    "Return a transient project rooted at ~/w/<first-component> for DIR."
    (let* ((w (my/normalise-dir "~/w"))
           (d (my/normalise-dir dir)))
      (when (and (string-prefix-p w d) (not (string= w d)))
        (let ((first (car (split-string (substring d (length w)) "/" t))))
          (when first
            (cons 'transient (expand-file-name (file-name-as-directory first) w)))))))

  ;; Run after the VC backend so real repositories still win.
  (add-hook 'project-find-functions #'my/project-try-w 50))
;; project.el:1 ends here

;; [[file:readme.org::#h-projectile][Projectile:1]]
(use-package projectile
  :hook (after-init . projectile-mode)
  :bind-keymap ("C-c p" . projectile-command-map)
  :custom
  (projectile-project-search-path
   (mapcar #'my/normalise-dir '("~/w/" "~/Documents")))
  (projectile-completion-system 'default)   ; use Vertico/orderless, not ido
  (projectile-indexing-method 'alien)       ; respect .gitignore via git/fd
  :config
  (defun my/projectile-w-subdir-root (dir)
    "Treat immediate subdirectories of ~/w/ as Projectile roots.
The result MUST end in a slash; returning a bare path is what caused
`dirfile' concatenations."
    (let* ((w (my/normalise-dir "~/w"))
           (d (my/normalise-dir dir)))
      (when (and (string-prefix-p w d) (not (string= w d)))
        (let ((first (car (split-string (substring d (length w)) "/" t))))
          (when first
            (expand-file-name (file-name-as-directory first) w))))))

  (add-to-list 'projectile-project-root-functions #'my/projectile-w-subdir-root))
;; Projectile:1 ends here

;; [[file:readme.org::#h-dired][Dired:1]]
;; ── Core Dired (built in) ──────────────────────────────────────────────────
(use-package dired
  :ensure nil :straight (:type built-in)
  :commands (dired dired-jump dired-other-window dired-do-copy dired-do-rename)
  :custom
  ;; GNU ls switches: -a all, -g no owner, -h human sizes, -o no group.
  ;; `--group-directories-first' is GNU-only; see the guard below.
  (dired-listing-switches "-agho --group-directories-first")
  ;; Reuse the current Dired buffer when descending, instead of accumulating.
  (dired-kill-when-opening-new-dired-buffer t)
  ;; With two Dired windows, default copy/move target to the other one.
  (dired-dwim-target t)
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'top)
  (delete-by-moving-to-trash t)
  :config
  ;; On BSD/macOS `ls' has no --group-directories-first; fall back gracefully.
  (unless (eq system-type 'gnu/linux)
    (setq dired-listing-switches "-agho"))
  ;; `dired-x' gives `dired-jump' (C-x C-j) and omitting uninteresting files.
  (require 'dired-x))

;; ── Dired keybindings ──────────────────────────────────────────────────────
;; Installed from `dired-mode-hook' at depth 90 so they run AFTER
;; evil-collection has set up its own map, and therefore win.
;; All symbols below are real interactive commands.  `dired-copy',
;; `dired-delete-file' and `dired-rename-file' are not.
(defun my/dired-keys ()
  "Install single-key Dired bindings for Evil normal state."
  (when (featurep 'evil)
    (evil-define-key 'normal dired-mode-map
      (kbd "d")   #'dired-flag-file-deletion   ; mark for deletion
      (kbd "D")   #'dired-do-delete            ; delete now
      (kbd "c")   #'dired-do-copy
      (kbd "r")   #'dired-do-rename
      (kbd "m")   #'dired-mark
      (kbd "u")   #'dired-unmark
      (kbd "x")   #'dired-do-flagged-delete
      (kbd "q")   #'quit-window
      (kbd "+")   #'dired-create-directory
      ;; dired-subtree: the real commands, not a nonexistent mode.
      (kbd "TAB")     #'dired-subtree-toggle
      (kbd "<backtab>") #'dired-subtree-cycle
      (kbd "M-RET")   #'dired-subtree-insert
      (kbd "M-DEL")   #'dired-subtree-remove)))

(add-hook 'dired-mode-hook #'my/dired-keys 90)

;; ── Subtree rendering ──────────────────────────────────────────────────────
;; No :hook here on purpose.  `:commands' generates correct autoloads for the
;; functions that actually exist.
(use-package dired-subtree
  :after dired
  :commands (dired-subtree-toggle dired-subtree-cycle
             dired-subtree-insert dired-subtree-remove)
  :custom
  (dired-subtree-line-prefix "  ")
  (dired-subtree-use-backgrounds nil))   ; let the theme own the colours

;; ── Font lock ──────────────────────────────────────────────────────────────
(use-package diredfl
  :after dired
  :hook (dired-mode . diredfl-mode))

;; ── Icons ──────────────────────────────────────────────────────────────────
;; nerd-icons must be present before nerd-icons-dired; declaring it explicitly
;; avoids a half-initialised icon cache on the first Dired buffer.
(use-package nerd-icons
  :defer t)

(use-package nerd-icons-dired
  :after (dired nerd-icons)
  :hook (dired-mode . nerd-icons-dired-mode))
;; Dired:1 ends here

;; [[file:readme.org::#h-buffers-remote][Buffers, remote files and terminals:1]]
(use-package ibuffer
  :ensure nil :straight (:type built-in)
  :bind ("C-x C-b" . ibuffer)
  :custom (ibuffer-expert t))

;; Group ibuffer entries by VC root.
(use-package ibuffer-vc
  :after ibuffer
  :hook (ibuffer-mode . ibuffer-vc-set-filter-groups-by-vc-root))

(use-package tramp
  :ensure nil :straight (:type built-in)
  :defer t
  :custom
  (tramp-default-method "ssh")
  ;; Keep TRAMP's own backups out of the remote tree.
  (tramp-backup-directory-alist `(("." . ,my/backup-dir))))

(use-package vterm
  :commands vterm
  :custom (vterm-max-scrollback 10000)
  :config
  ;; `shell-file-name' stays POSIX so that Elisp subprocess code keeps working;
  ;; fish is used only for interactive vterm sessions.
  (when-let* ((fish (executable-find "fish")))
    (setq vterm-shell fish)))

;; Visual undo tree.
(use-package vundo
  :commands vundo)
;; Buffers, remote files and terminals:1 ends here

;; [[file:readme.org::#h-motion][Motion and selection:1]]
;; Jump to any visible character.  C-; belongs to embark-dwim.
(use-package avy
  :bind ("C-'" . avy-goto-char))

;; Structural (tree-sitter / syntax aware) region expansion.
(use-package expreg
  :straight (:host github :repo "casouri/expreg")
  :after evil
  :bind (:map evil-normal-state-map
              ("C-=" . expreg-expand)
              ("C--" . expreg-contract)
              :map evil-visual-state-map
              ("v" . expreg-expand)
              ("V" . expreg-contract)))

;; tells which func we are.
(use-package breadcrumb
  :hook (prog-mode . breadcrumb-local-mode))

;; Window jumping with labels.  Owns M-o.
(use-package ace-window
  :bind ("M-o" . ace-window)
  :custom (aw-scope 'frame))

;; Follow links in help/org/markdown buffers.  Moved off M-l (puni owns it).
(use-package ace-link
  :bind ("M-g l" . ace-link))

;; Move the current line or region.
(use-package move-text
  :bind (([(meta shift up)]   . move-text-up)
         ([(meta shift down)] . move-text-down)))

;; Match counter (3/17) in the echo area during search.
(use-package anzu
  :hook (after-init . global-anzu-mode))

;; M-w picks the thing at point when there is no region.
(use-package easy-kill
  :bind ([remap kill-ring-save] . easy-kill))
;; Motion and selection:1 ends here

;; [[file:readme.org::#h-fd9a57bc][Structural editing:1]]
(use-package puni
  :straight (:host github :repo "AmaiKinono/puni")
  :hook (prog-mode . puni-mode)
  :bind (:map puni-mode-map
              ("M-l"   . puni-slurp-forward)
              ("M-h"   . puni-barf-forward)
              ("M-L"   . puni-slurp-backward)
              ("M-H"   . puni-barf-backward)
              ("M-r"   . puni-raise)
              ("C-c M-s" . puni-splice))   ; was M-s, which broke consult
  :config
  (with-eval-after-load 'evil
    (evil-define-key 'normal puni-mode-map
      (kbd "D") #'puni-kill-line
      (kbd "C") (lambda () (interactive)
                  (puni-kill-line)
                  (evil-insert-state)))))
;; Structural editing:1 ends here

;; [[file:readme.org::#h-persistence][Persistence and automatic saving:1]]
;; Undo history survives restarts.  Large files are excluded by
;; `my/large-file-setup' via `undo-fu-session-inhibit'.
(use-package undo-fu-session
  :hook (after-init . undo-fu-session-global-mode)
  :custom
  (undo-fu-session-directory (expand-file-name "undo/" user-emacs-directory))
  (undo-fu-session-compression 'gz))

;; Save on focus loss / window switch.  This replaces the old
;; `focus-out-hook' lambda that also triggered a full GC.
(use-package super-save
  :hook (after-init . super-save-mode)
  :custom
  (super-save-auto-save-when-idle t)
  (super-save-idle-duration 5)
  (super-save-remote-files nil))     ; never write over TRAMP implicitly
;; Persistence and automatic saving:1 ends here

;; [[file:readme.org::#h-env][Environment and project conventions:1]]
;; .editorconfig support.  Declared once; it used to appear twice.
(use-package editorconfig
  :hook (after-init . editorconfig-mode)
  :config
  (defun my/editorconfig-fill-column (props)
    "Set `fill-column' to ~90% of the EditorConfig max_line_length."
    (when-let* ((raw (gethash 'max_line_length props))
                (n   (and (stringp raw)
                          (not (member raw '("off" "unset")))
                          (string-to-number raw)))
                ((> n 10)))
      (setq-local fill-column (- n (/ n 10)))))
  (add-hook 'editorconfig-after-apply-functions #'my/editorconfig-fill-column))

;; direnv.  `envrc-mode' is buffer-local, so (+1) only ever enabled it in
;; *scratch*.  The global mode is what actually propagates .envrc per buffer.
(use-package envrc
  :hook (after-init . envrc-global-mode))
;; Environment and project conventions:1 ends here

;; [[file:readme.org::#h-misc-editing][Snippets, docs and misc commands:1]]
;; Eldoc in programming buffers, plus a childframe instead of the echo area.
  (use-package eldoc
    :ensure nil :straight (:type built-in)
    :hook (prog-mode . eldoc-mode))

  (use-package eldoc-box
    :after eldoc
    :hook (eldoc-mode . eldoc-box-hover-mode))

  (setq eldoc-echo-area-use-multiline-p nil)
  (setq eldoc-idle-delay 1.5)

  (with-eval-after-load 'eldoc-box
   (remove-hook 'eglot-managed-mode-hook #'eldoc-box-hover-mode)
   (remove-hook 'eglot-managed-mode-hook #'eldoc-box-hover-at-point-mode)) 
  (setq eglot-send-changes-idle-time 1.0)

 (use-package tempel
  :commands (tempel-insert tempel-complete))

;; Colourise #rrggbb and rgb(...) literals.
(use-package rainbow-mode
:hook (prog-mode . rainbow-mode))

;; Outline navigation in programming buffers.
(use-package outline
:ensure nil :straight (:type built-in)
:hook (prog-mode . outline-minor-mode))

;; Assorted interactive commands.  M-o is ace-window, so smart-open-line
;; moved to C-c O.
(use-package crux
:bind (("C-c o" . crux-open-with)
        ("C-c O" . crux-smart-open-line)
        ("C-c u" . crux-cleanup-buffer-or-region)
        ("C-c f" . crux-recentf-find-file)
        ("C-c w" . crux-swap-windows)
        ("C-c D" . crux-delete-file-and-buffer)
        ("C-c r" . crux-rename-buffer-and-file)
        ("s-r"   . crux-recentf-find-file)
        ("s-k"   . crux-kill-whole-line)))
;; Snippets, docs and misc commands:1 ends here

;; [[file:readme.org::#h-2595f812][BIDI:1]]
;; Keep the bidirectional parenthesis algorithm off: it is the expensive part
;; and is rarely needed for prose.
(setq-default bidi-display-reordering t
            bidi-inhibit-bpa t
            bidi-paragraph-direction 'left-to-right)

(defun my/toggle-bidi-direction ()
"Toggle BIDI reordering and paragraph direction in this buffer."
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
;; BIDI:1 ends here

;; [[file:readme.org::#h-c7a5c469][Zen mode:1]]
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
"Restore programming-buffer decoration when Olivetti turns off."
(when (derived-mode-p 'prog-mode)
    (display-line-numbers-mode 1)
    (display-fill-column-indicator-mode 1)))

(add-hook 'olivetti-mode-on-hook  #'my/zen-enable)
(add-hook 'olivetti-mode-off-hook #'my/zen-disable))

(defun my/toggle-zen-mode ()
"Toggle Olivetti (distraction-free) mode."
(interactive)
(require 'olivetti)
(olivetti-mode 'toggle))
;; Zen mode:1 ends here

;; [[file:readme.org::#h-29f35118][Core:1]]
(use-package org
:ensure nil :straight (:type built-in)
:defer t
:commands (org-mode org-agenda org-capture org-store-link org-version)
:mode ("\\.org\\'" . org-mode)
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
(org-startup-with-latex-preview nil)
(org-preview-latex-default-process 'dvisvgm)   ; crisp SVG previews
(org-format-latex-options
'(:foreground default :background default :scale 1.5
    :html-foreground "Black" :html-background "Transparent"
    :html-scale 1.5 :matchers ("begin" "$1" "$" "$$" "\\(" "\\["))))
;; Core:1 ends here

;; [[file:readme.org::#h-ba7986cb][Org Roam:1]]
(use-package org-roam
:after org
:custom
(org-roam-directory (expand-file-name "notes/" org-directory))
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
:config (org-roam-db-autosync-mode 1))

(use-package org-roam-ui
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
(setq org-id-locations-file
    (expand-file-name ".org-id-locations" user-emacs-directory)
    org-id-link-to-org-use-id 'create-if-interactive-and-no-custom-id)

(defun my/org-custom-id-get (&optional pom create)
"Return the CUSTOM_ID at POM, creating an `h-xxxxxxxx' one when CREATE."
(org-with-point-at pom
    (or (org-entry-get nil "CUSTOM_ID")
        (when create
        (let ((id (concat "h-" (substring (md5 (org-id-new)) 0 8))))
            (org-entry-put nil "CUSTOM_ID" id)
            id)))))

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
        (lambda ()
            (add-hook 'before-save-hook #'my/org-add-ids-to-headlines nil t)))

(add-hook 'org-capture-before-finalize-hook
        (lambda ()
            (when (org-at-heading-p)
            (my/org-custom-id-get (point) t)))))
;; Automatic CUSTOM_IDs:1 ends here

;; [[file:readme.org::#h-d8ec6da9][HTML export with Tufte CSS:1]]
(defun my/org-export-to-export-dir (orig-fun extension &optional subtreep pub-dir)
"Mirror the Org source tree under `org-directory'/export/."
(let* ((org-root    (my/normalise-dir org-directory))
        (export-root (expand-file-name "export/" org-root))
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

(with-eval-after-load 'ox
(advice-add 'org-export-output-file-name :around #'my/org-export-to-export-dir))

;; ── Syntax highlighting for HTML export ────────────────────────────────────
;; `ox-html' fontifies src blocks by running font-lock in a temp buffer and
;; then converting the resulting faces to HTML.  That conversion is done by
;; `htmlize', which is NEITHER built into Emacs NOR a dependency of Org.
;; Without it, `org-html-fontify-code' emits
;;   "Cannot fontify source block (htmlize.el >= 1.34 required)"
;; once PER SOURCE BLOCK and falls back to plain text.
(use-package htmlize
:defer t
:commands (htmlize-buffer htmlize-region htmlize-file))

(with-eval-after-load 'ox-html
;; `inline-css' bakes colours into style="..." attributes: the export is
;; self-contained, no extra stylesheet needed.  This is already the default;
;; set it explicitly so the choice is documented.
(setq org-html-htmlize-output-type 'inline-css)
;; Class-name prefix used when `org-html-htmlize-output-type' is `css'.
(setq org-html-htmlize-font-prefix "org-"))

(use-package ox-tufte
:after ox
:config
(defun my/org-html-embed-tufte-css ()
"Read tufte.css + ox-tufte.css from disk and wrap them in a <style> block."
(let* ((css-dir (expand-file-name "static/css/" org-directory))
        (tufte   (expand-file-name "tufte.css" css-dir))
        (ox      (expand-file-name "ox-tufte.css" css-dir)))
    (concat
    "<link href=\"https://fonts.googleapis.com/css?family=IBM+Plex+Mono\" rel=\"stylesheet\">\n"
    "<link href=\"https://fonts.googleapis.com/css?family=IBM+Plex+Sans\" rel=\"stylesheet\">\n"
    "<link href=\"https://fonts.googleapis.com/css?family=IBM+Plex+Serif\" rel=\"stylesheet\">\n"
    "<style type=\"text/css\">\n"
    (if (file-readable-p tufte)
        (with-temp-buffer (insert-file-contents tufte) (buffer-string))
        "/* WARNING: tufte.css not found */\n")
    "\n/* ===== ox-tufte.css ===== */\n"
    (if (file-readable-p ox)
        (with-temp-buffer (insert-file-contents ox) (buffer-string))
        "/* WARNING: ox-tufte.css not found */\n")
    "\n/* ===== IBM Plex overrides ===== */\n"
    "body, article { font-family: \"IBM Plex Serif\", et-book, Georgia, serif !important;"
    " background-color: #fffff8; color: #111; }\n"
    "h1, h2, h3, h4, h5, .sans { font-family: \"IBM Plex Sans\", system-ui, sans-serif !important;"
    " font-weight: 500; }\n"
    "code, pre, .org-src-container pre { font-family: \"IBM Plex Mono\", ui-monospace, monospace !important; }\n"
    ".sidenote, .marginnote { font-family: \"IBM Plex Serif\", Georgia, serif; }\n"
    "mjx-container, .MathJax, .katex { margin: 0.6em 0; overflow-x: auto;"
    " overflow-y: hidden; max-width: 100%; }\n"
    ".org-latex-preview { max-width: 100%; height: auto; }\n"
    "</style>")))

(setq org-html-head-include-default-style nil)

;; Compute the head at export time, not at load time.
(defun my/org-html-head-refresh (&rest _)
"Rebuild `org-html-head' from the CSS files on disk."
(setq org-html-head (my/org-html-embed-tufte-css)))
(advice-add 'org-html-export-to-html :before #'my/org-html-head-refresh)
(advice-add 'org-html-export-as-html :before #'my/org-html-head-refresh))
;; HTML export with Tufte CSS:1 ends here

;; [[file:readme.org::#h-3a8f9c21][LaTeX export:1]]
(use-package ox-latex
:ensure nil :straight (:type built-in)
:after org
:custom
;; -shell-escape is REQUIRED by minted.  latexmk handles the multiple passes,
;; bibtex/biber and glossaries automatically.
(org-latex-pdf-process
'("latexmk -f -pdf -%latex -shell-escape -interaction=nonstopmode -output-directory=%o %f"))
(org-latex-listings 'minted)          ; needs python-pygments on PATH
(org-latex-minted-options
'(("frame" "lines") ("fontsize" "\\footnotesize")
    ("breaklines" "true") ("linenos" "true")))
;; NOTE: inputenc/fontenc are pdflatex-only.  The third element of each entry
;; is SNIPPET-P, not "pdflatex only"; the compiler list is the fourth.
(org-latex-packages-alist
'(("AUTO" "inputenc"  t ("pdflatex"))
    ("T1"   "fontenc"   t ("pdflatex"))
    (""     "amsmath"   t)
    (""     "amssymb"   t)
    (""     "mathtools" t)
    (""     "mathrsfs"  t)
    (""     "braket"    t)
    (""     "csquotes"  t)
    (""     "microtype" t))))
;; LaTeX export:1 ends here

;; [[file:readme.org::#h-treesit][Tree-sitter:1]]
;; Emacs 31: switch every mode that has a tree-sitter variant to it.
(when (boundp 'treesit-enabled-modes)
(setq treesit-enabled-modes t))

;; Emacs 31: ask before downloading/building a missing grammar.
;; (`treesit-auto-install' is the older, now obsolete name.)
(cond ((boundp 'treesit-auto-install-grammar)
    (setq treesit-auto-install-grammar 'ask))
    ((boundp 'treesit-auto-install)
    (setq treesit-auto-install 'ask)))
;; Tree-sitter:1 ends here

;; [[file:readme.org::#h-eglot][Eglot (LSP):1]]
(use-package eglot
:ensure nil :straight (:type built-in)
:hook (((python-base-mode
        c-mode c-ts-mode c++-mode c++-ts-mode
        go-mode go-ts-mode
        rustic-mode rust-ts-mode
        js-mode js-ts-mode typescript-ts-mode tsx-ts-mode
        clojure-mode elixir-mode erlang-mode elm-mode
        LaTeX-mode typst-ts-mode)
        . eglot-ensure))
:custom
;; Shut the server down when the last managed buffer is killed.
(eglot-autoshutdown t)
;; Do not log every JSONRPC event: chatty servers make this expensive.
;; Set :size back to nil temporarily when debugging a session.
(eglot-events-buffer-config '(:size 0 :format full))
:config
;; Eglot renders diagnostics through Flymake by default.  Flycheck's bridge
  ;; (below) turns Flymake off per buffer and takes over.  If you ever want
  ;; Eglot to keep Flymake and let Flycheck run only its own checkers, add
  ;; `flymake' here — but do NOT do that while `flycheck-eglot-mode' is on,
  ;; because the bridge manages Flymake itself.
  ;; (add-to-list 'eglot-stay-out-of 'flymake)
  )
;; Eglot (LSP):1 ends here

;; [[file:readme.org::#h-12ce19fc][Diagnostics: Flycheck:1]]
(use-package flycheck
  ;; Everything (annotate mode, eglot bridge, lsp bridge) lives in flycheck.el
  ;; itself since v38.  There is NO flycheck-eglot.el to require.
  :demand t
  :hook (after-init . global-flycheck-mode)
  :custom
  (flycheck-disabled-checkers '(markdown-markdownlint-cli))
  (flycheck-check-syntax-automatically '(save mode-enabled idle-change))
  (flycheck-idle-change-delay 0.8)
  ;; t (default) = ONLY the LSP server's diagnostics in Eglot buffers.
  ;; nil = chain eglot-check -> flycheck-lsp -> a command checker.
  (flycheck-eglot-exclusive t)
  :config
  ;; Report loudly instead of silently skipping, so a version mismatch is
  ;; visible rather than looking like "the bridge does not work".
  (if (fboundp 'global-flycheck-annotate-mode)
      (global-flycheck-annotate-mode 1)
    (message "Flycheck %s: no annotate mode (needs >= 38)" (flycheck-version)))
  (if (fboundp 'global-flycheck-eglot-mode)
      (global-flycheck-eglot-mode 1)
    (message "Flycheck %s: no eglot bridge (needs >= 38)" (flycheck-version))))

;; Popup frame for the error at point.  Only meaningful on a graphical frame;
;; on a TTY it would fail, so keep the echo-area default there.
(use-package flycheck-posframe
  :after flycheck
  :hook (flycheck-mode . flycheck-posframe-mode)
  :config
  (when (fboundp 'flycheck-posframe-configure-pretty-defaults)
    (flycheck-posframe-configure-pretty-defaults)))

;; Jump to a diagnostic with consult's live preview.
(use-package consult-flycheck
  :after (consult flycheck)
  :bind ("M-g f" . consult-flycheck))

;; Clojure linting via the Joker interpreter.
(use-package flycheck-joker
  :after flycheck)
;; Diagnostics: Flycheck:1 ends here

;; [[file:readme.org::#h-apheleia][Formatting:1]]
(use-package apheleia
  :hook (after-init . apheleia-global-mode)
  :custom (apheleia-formatters-respect-indent-level nil)
  :config
  ;; Ruff: first sort imports, then format.  Both read from stdin so the
  ;; buffer is never written to disk mid-format.
  (setf (alist-get 'ruff-check apheleia-formatters)
        '("ruff" "check" "--select" "I" "--fix" "--stdin-filename" filepath "-"))
  (setf (alist-get 'ruff-format apheleia-formatters)
        '("ruff" "format" "--stdin-filename" filepath "-"))
  (setf (alist-get 'python-mode    apheleia-mode-alist) '(ruff-check ruff-format))
  (setf (alist-get 'python-ts-mode apheleia-mode-alist) '(ruff-check ruff-format)))
;; Formatting:1 ends here

;; [[file:readme.org::#h-prose][Prose checking:1]]
(use-package jinx
  :hook (emacs-startup . global-jinx-mode)
  :bind (("M-$" . jinx-correct)
         ("C-M-$" . jinx-languages))
  :config
  (setq jinx-languages "en_GB fa_IR"))

  (use-package langtool
    :commands (langtool-check langtool-check-buffer)
    :custom (langtool-default-language "en-GB"))
;; Prose checking:1 ends here

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
    (when (and python (file-executable-p python))
      (setq-local python-shell-interpreter python
                  python-shell-virtualenv-root venv
                  exec-path (cons bin (remove bin exec-path))
                  process-environment
                  (append (list (concat "VIRTUAL_ENV=" venv)
                                (concat "PATH=" bin path-separator (getenv "PATH"))
                                ;; A bare name (no "=") unsets the variable.
                                "PYTHONHOME")
                          process-environment))
      (message "Activated venv: %s" venv))))

(use-package python
  :ensure nil :straight (:type built-in)
  :defer t
  :config
  ;; Depth -90: run BEFORE `eglot-ensure' on the same hook.
  (add-hook 'python-base-mode-hook #'my/python-uv-activate -90)

  (with-eval-after-load 'eglot
    (when-let* ((exe (or (executable-find "pyrefly")
                         (let ((p (expand-file-name "~/.local/bin/pyrefly")))
                           (and (file-executable-p p) p)))))
      (add-to-list 'eglot-server-programs
                   (list '(python-mode python-ts-mode) exe "lsp")))))
;; Python:1 ends here

;; [[file:readme.org::#h-7693f750][Languages:1]]
;; Keep .h as C-or-C++ (Emacs guesses from the contents).
(add-to-list 'auto-mode-alist '("\\.h\\'" . c-or-c++-mode))

(use-package go-mode
  :mode "\\.go\\'")

(use-package rustic
  :mode ("\\.rs\\'" . rustic-mode)
  :custom
  (rustic-lsp-client 'eglot)
  (rustic-format-on-save nil))          ; Apheleia owns format-on-save

(use-package markdown-mode
  :mode (("\\.md\\'"       . markdown-mode)
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

(use-package elixir-mode :mode "\\.exs?\\'")
(use-package erlang      :mode "\\.erl\\'")
(use-package elm-mode    :mode "\\.elm\\'")

;; ── OCaml ──────────────────────────────────────────────────────────────────
;; neocaml registers its own auto-mode-alist entries AND sets the
;; `eglot-language-id' symbol property on its modes ("ocaml" for .ml,
;; "ocaml.interface" for .mli, "ocaml.mlx" for .mlx).  It also handles dune,
;; opam, ocamllex, menhir, cram and .mld files.
;; => Do NOT add your own :mode entries; they are redundant and can shadow
;;    the richer upstream registrations.
(use-package neocaml
  :defer t
  :commands (neocaml-mode neocaml-interface-mode neocaml-base-mode)
  :custom
  ;; Apheleia owns format-on-save in this configuration.
  (neocaml-format-on-save nil))

;; Older neocaml (before ~20260331) did not register itself with Eglot.
;; This is the same guard Prelude ships; it is a no-op on current versions.
(with-eval-after-load 'eglot
  (unless (cl-some (lambda (entry)
                     (and (consp (car entry))
                          (assq 'neocaml-mode (car entry))))
                   eglot-server-programs)
    (add-to-list 'eglot-server-programs
                 '(((neocaml-mode :language-id "ocaml")
                    (neocaml-interface-mode :language-id "ocaml.interface"))
                   "ocamllsp"))))

(use-package ocaml-eglot
  :after neocaml
  :hook ((neocaml-base-mode . ocaml-eglot-mode)
         (ocaml-eglot-mode  . eglot-ensure))
  :custom
  ;; ocaml-eglot has its OWN syntax-checker selector, and it defaults to
  ;; `flymake'.  Left at the default it wires Flymake up in every OCaml
  ;; buffer, fighting `flycheck-eglot-mode'.  That is exactly why the bridge
  ;; appeared to work in Python (which has command-checker fallbacks) and
  ;; do nothing in OCaml (which has none).
  (ocaml-eglot-syntax-checker 'flycheck)
  :config
  ;; Belt and braces.  `ocaml-eglot-mode-hook' fires on BOTH enable and
  ;; disable, so it is the wrong place to decide about diagnostics.
  ;; `eglot-managed-mode-hook' fires when Eglot actually owns the buffer.
  (add-hook 'eglot-managed-mode-hook
            (lambda ()
              (when (and (eglot-managed-p)
                         (derived-mode-p 'neocaml-base-mode)
                         (fboundp 'flycheck-eglot-mode))
                (flycheck-eglot-mode 1)))))
  (with-eval-after-load 'flycheck
      (setq flycheck-check-syntax-automatically '(save idle-change mode-enabled))
      (setq flycheck-idle-change-delay 2.0))
  
(use-package opam-switch-mode
  :hook (neocaml-base-mode . opam-switch-mode))

;; Lean 4 is NOT built in and NOT on an ELPA.  It must be fetched from Git.
;; The previous (:type built-in) + :vc combination was contradictory: straight
;; ignored the repository entirely.
(use-package lean4-mode
  :straight (lean4-mode :type git :host github
                        :repo "leanprover-community/lean4-mode")
  :mode "\\.lean\\'"
  :commands (lean4-mode))

(use-package geiser-guile
  :defer t
  :custom (geiser-guile-binary "guile"))

(use-package auctex
  :defer t
  :mode ("\\.tex\\'" . LaTeX-mode)
  :custom
  (TeX-auto-save t)
  (TeX-parse-self t)
  (TeX-PDF-mode t))

(use-package graphviz-dot-mode
  :mode "\\.dot\\'"
  :custom (graphviz-dot-indent-width 2))

;; Templates.  Declared last so these patterns take precedence over the
;; tree-sitter HTML/JSON entries.
(use-package web-mode
  :mode (("\\.html?\\'"   . web-mode)
         ("\\.vue\\'"     . web-mode)
         ("\\.svelte\\'"  . web-mode)
         ("\\.erb\\'"     . web-mode)
         ("\\.jinja2?\\'" . web-mode)))
;; Languages:1 ends here

;; [[file:readme.org::#h-git][Git:1]]
(use-package magit
  :bind ("C-x g" . magit-status)
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  (magit-save-repository-buffers 'dontask))

;; TODO/FIXME listing inside magit-status.  `magit-todos-mode' is the entry
;; point; `:commands magit-todos' alone never activated it.
(use-package magit-todos
  :after magit
  :hook (magit-mode . magit-todos-mode))

;; Step through a file's git revisions.
(use-package git-timemachine
  :bind ("C-c g" . git-timemachine))

;; Structural diffs via the difftastic CLI.
(use-package difftastic
  :commands (difftastic-magit-show difftastic-magit-diff)
  :after magit
  :config
  (when (fboundp 'difftastic-bindings-mode)
    (difftastic-bindings-mode 1)))
;; Git:1 ends here

;; [[file:readme.org::#h-9796e496][RSS (Elfeed):1]]
(use-package elfeed
  :commands (elfeed elfeed-update)
  :custom
  (elfeed-db-directory (expand-file-name "elfeed/" user-emacs-directory))
  :config
  (setq elfeed-feeds
        '(;; --- emacs ---
          ("https://irreal.org/blog/?feed=rss2"                emacs blog)
          ("https://nullprogram.com/feed/"                     emacs blog)
          ("http://yummymelon.com/devnull/feeds/all.atom.xml"  emacs blog)
          ("https://karthinks.com/index.xml"                   emacs blog)
          ("https://emacsredux.com/atom.xml"                   emacs blog)
          ("https://xania.org/rss/Coding"                      compilers cpp)
          ("https://xania.org/rss/Rust"                        compilers rust)
          ;; --- compilers / LLVM / PLT ---
          ("https://blog.regehr.org/feed"                      compilers undefined-behavior)
          ("https://mcyoung.xyz/index.xml"                     compilers llvm)
          ("https://blog.yossarian.net/feed.xml"               compilers llvm security)
          ("https://eli.thegreenplace.net/feeds/all.atom.xml"  compilers low-level)
          ("https://www.cs.cornell.edu/~asampson/blog/feed.xml" compilers plt)
          ("https://www.jntrnr.com/atom.xml"                   compilers rust)
          ("https://www.philipzucker.com/rss.xml"              plt category-theory)
          ("https://lambdaland.org/index.xml"                  plt scheme)
          ("https://bernsteinbear.com/feed.xml"                compilers plt)
          ("https://wingolog.org/feed/atom"                    compilers plt)
          ("https://lobste.rs/t/compilers.rss"                 compilers aggregator)
          ;; --- rust / systems ---
          ("https://fasterthanli.me/index.xml"                 rust systems)
          ("https://matklad.github.io/feed.xml"                rust ide compilers)
          ("https://without.boats/index.xml"                   rust async)
          ("https://blog.cliffle.com/rss.xml"                  rust embedded systems)
          ("https://blog.rust-lang.org/feed.xml"               rust official)
          ("https://this-week-in-rust.org/rss.xml"             rust news)
          ("https://www.ralfj.de/blog/feed.rss"                rust unsafe semantics)
          ("https://smallcultfollowing.com/babysteps/atom.xml" rust language-design)
          ;; --- low-level / performance ---
          ("https://lemire.me/blog/feed/"                      performance simd)
          ("https://travisdowns.github.io/feed.xml"            performance cpu)
          ("https://easyperf.net/blog/feed.xml"                performance cpu)
          ("https://danluu.com/atom.xml"                       systems performance)
          ;; --- c++ ---
          ("https://www.modernescpp.com/index.php?format=feed&type=rss" cpp)
          ("https://artificial-mind.net/blog/rss.xml"          cpp graphics)
          ("https://herbsutter.com/feed/"                      cpp)
          ("https://devblogs.microsoft.com/cppblog/feed/"      cpp msvc)))

  ;; ── Real pruning ─────────────────────────────────────────────────────────
  (defvar my/elfeed-max-age (* 14 24 3600)
    "Drop unread, unstarred entries older than this many seconds.")

  (defun my/elfeed-prune ()
    "Remove old unread entries from the Elfeed database."
    (when (fboundp 'elfeed-db-visit)
      (let ((cutoff (- (float-time) my/elfeed-max-age))
            (dropped 0))
        (elfeed-db-visit
         (entry _feed)
         (when (and (< (elfeed-entry-date entry) cutoff)
                    (not (memq 'starred (elfeed-entry-tags entry)))
                    (memq 'unread (elfeed-entry-tags entry)))
          (setf (elfeed-entry-content entry) nil)
          (cl-incf dropped)))
        (elfeed-db-gc)
        (when (> dropped 0)
          (message "Elfeed: pruned %d old entries" dropped)))))

  ;; Once a day, on idle — not on every fetched entry.
  (run-with-idle-timer 600 t #'my/elfeed-prune))

(use-package elfeed-org
  :after elfeed
  :custom
  (rmh-elfeed-org-files (list (expand-file-name "elfeed.org" org-directory)))
  :config (elfeed-org))
;; RSS (Elfeed):1 ends here

;; [[file:readme.org::#h-b68e630a][IRC:1]]
(use-package circe
  :commands circe
  :config
  (require 'auth-source-pass)
  (setq circe-network-options
        `(("Libera"
           :host "irc.libera.chat" :port 6697 :tls t
           :nick "komeil" :user "komeil"
           :nickserv-password
           ,(lambda (&rest _) (auth-source-pass-get 'secret "irc/libera"))
           :channels ("#gnu" "#guix" "#voidlinux" "#xbps" "#org-mode")))))
;; IRC:1 ends here

;; [[file:readme.org::#h-82980190][Lookup, notes and containers:1]]
(use-package quickrun :commands quickrun)
(use-package docker   :commands docker)
(use-package pass     :commands pass)

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
;; Lookup, notes and containers:1 ends here

;; [[file:readme.org::#h-5275da7d][Package helpers (straight, not package.el):1]]
(defun my/package-sync ()
  "Refresh recipe repositories and pull every installed package."
  (interactive)
  (straight-pull-recipe-repositories)
  (straight-pull-packages)
  (message "straight: sync finished."))

(defun my/package-rebuild ()
  "Rebuild every straight package from source."
  (interactive)
  (straight-rebuild-all)
  (message "straight: rebuild finished."))

(defun my/package-cleanup ()
  "Remove repository clones that no declared package uses any more."
  (interactive)
  (straight-remove-unused-repos 'force))

(defun my/package-freeze ()
  "Write the current commit hashes to straight's lockfile."
  (interactive)
  (straight-freeze-versions)
  (message "straight: versions frozen."))
;; Package helpers (straight, not package.el):1 ends here

;; [[file:readme.org::#h-04bc138f][Local scripts (load.d):1]]
;; Loaded last so local overrides win.  A failing file is reported, not fatal.
(let ((load-d (expand-file-name "load.d/" user-emacs-directory)))
  (when (file-directory-p load-d)
    (dolist (file (directory-files load-d t "\\.el\\'"))
      (condition-case err
          (load file nil 'nomessage)
        (error (message "load.d: failed to load %s: %s" file err))))))
;; Local scripts (load.d):1 ends here
