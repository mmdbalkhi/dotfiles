;;; early-init.el --- Early init -*- lexical-binding: t; no-byte-compile: t -*-
;; Generated from readme.org – edit the Org file, not this one.

;; ---------------------------------------------------------------------------
;; 1. Garbage collection
;; ---------------------------------------------------------------------------
;; Raise the GC threshold so that loading ~200 packages does not trigger
;; hundreds of collections.  Restored to a sane value on `emacs-startup-hook'.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; ---------------------------------------------------------------------------
;; 2. Cheap global defaults
;; ---------------------------------------------------------------------------
;; `vc-follow-symlinks' avoids the "symbolic link to a VC file" question when
;; the dotfiles repository is symlinked into ~/.config/emacs.
(setq vc-follow-symlinks t
      read-process-output-max (* 8 1024 1024) ; 8MB: fewer reads from LSP servers
      eval-expression-print-length 50
      eval-expression-print-level 10)

;; ---------------------------------------------------------------------------
;; 3. First-boot detection
;; ---------------------------------------------------------------------------
;; On the very first start no packages exist yet, so hide the frame instead of
;; showing a half-configured Emacs.  The frame is made visible again at the end
;; of startup (see init.el).
(defvar my/first-boot
  (not (file-directory-p (expand-file-name "straight/repos" user-emacs-directory)))
  "Non-nil when straight has never cloned anything on this machine.")

(when my/first-boot
  (push '(visibility . nil) initial-frame-alist))

;; ---------------------------------------------------------------------------
;; 4. PATH
;; ---------------------------------------------------------------------------
;; Emacs inherits PATH from whatever launched it, which is often not the
;; interactive shell.  Append our own directories to both `exec-path' and the
;; PATH environment variable so that subprocesses see the same thing.
(dolist (dir '("~/.local/bin"
               "~/.opam/default/bin"
               "~/.cargo/bin"
               "/usr/local/bin"
               "/usr/bin"))
  (let ((dir (expand-file-name dir)))
    (when (and (file-directory-p dir) (not (member dir exec-path)))
      (setq exec-path (append exec-path (list dir)))
      (setenv "PATH" (concat (getenv "PATH") path-separator dir)))))

;; ---------------------------------------------------------------------------
;; 5. File-name handlers
;; ---------------------------------------------------------------------------
;; Every `load' and `expand-file-name' consults this alist.  Emptying it during
;; startup is a large win; it MUST be restored, otherwise TRAMP, encryption and
;; compression stop working.
(defvar my--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist
                  (delete-dups (append file-name-handler-alist
                                       my--file-name-handler-alist))
                  ;; 32MB is a good steady-state threshold: large enough to
                  ;; avoid stutter, small enough to keep pauses short.
                  gc-cons-threshold (* 32 1024 1024)
                  gc-cons-percentage 0.1))
          90)

;; ---------------------------------------------------------------------------
;; ---------------------------------------------------------------------------
;; Native compilation: bounded, quiet, and cached
;; ---------------------------------------------------------------------------
(when (fboundp 'native-comp-available-p)
  (when (native-comp-available-p)
    ;; The current name is `native-comp-jit-compilation'; the old
    ;; `native-comp-deferred-compilation' is an obsolete alias.
    (setq native-comp-jit-compilation t)

    ;; DEFAULT IS 0 = HALF OF ALL CPU UNITS.  That is what saturates the
    ;; machine.  Pin it to a small number so background compilation is
    ;; noticeable but never dominant.
    (setq native-comp-async-jobs-number 2)

    ;; nil = do not even write the warnings log ('silent only hides the popup).
    (setq native-comp-async-report-warnings-errors nil)

    ;; Speed 2 is the default; 3 makes gcc much slower for little gain.
    (setq native-comp-speed 2)

    ;; Packages that are pointless or harmful to native-compile.
    (setq native-comp-jit-compilation-deny-list
          '("/beacon\\.el"          ; upstream defalias-in-if warning
            "/\\.dir-locals\\.el"
            "-autoloads\\.el\\'"
            "-pkg\\.el\\'"))))

;; ---------------------------------------------------------------------------
;; 7. Proxy
;; ---------------------------------------------------------------------------
;; Honour the usual environment variables so package cloning works behind a
;; corporate/ISP proxy.
(when-let* ((proxy (or (getenv "HTTPS_PROXY") (getenv "https_proxy")
                       (getenv "HTTP_PROXY")  (getenv "http_proxy"))))
  (setq url-proxy-services
        `(("no_proxy" . "localhost\\|127\\.0\\.0\\.1")
          (http  . ,proxy)
          (https . ,proxy))))

;; package.el must not initialise itself: straight.el owns the load path.
(setq package-enable-at-startup nil
      package-quickstart t)

;; ---------------------------------------------------------------------------
;; 8. Frame suppression
;; ---------------------------------------------------------------------------
;; Disable chrome before the first frame exists, so there is no flash of an
;; unstyled menu/tool bar.
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)
(setq frame-inhibit-implied-resize t
      use-file-dialog nil
      inhibit-startup-screen t
      inhibit-startup-message t
      inhibit-startup-echo-area-message user-login-name)

;; ---------------------------------------------------------------------------
;; 9. straight.el bootstrap
;; ---------------------------------------------------------------------------
(defvar bootstrap-version)
(let ((bootstrap-file (expand-file-name
                       "straight/repos/straight.el/bootstrap.el"
                       user-emacs-directory))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         t 'silent)
      (goto-char (point-min))
      (re-search-forward "^;;$" nil t)
      (eval (read (current-buffer)) 0)))
  (load bootstrap-file nil 'nomessage))

(require 'straight)

(setq straight-recipe-repositories '(melpa gnu-elpa-mirror emacsmirror-mirror)
      straight-git-shallow-clone t
      straight-pool-size 4
      straight-build-dir (expand-file-name "straight/build" user-emacs-directory)
      straight-use-package-by-default t)

;; ---------------------------------------------------------------------------
;; 10. Built-in pseudo-packages  (IMPORTANT)
;; ---------------------------------------------------------------------------
;; Many third-party packages declare a dependency on libraries that ship with
;; Emacs (`dired', `dired-x', `org', `project', ...).  If straight does not know
;; they are built in, it tries to clone them from a recipe repository, which
;; produces a second, stale copy that shadows the real one and breaks
;; autoloads.  Declaring them here makes straight treat them as always present.
(setq straight-built-in-pseudo-packages
      '(emacs nadvice cl-lib cl-generic seq subr-x map let-alist
        org ox ox-latex ox-html org-id
        project xref flymake eglot eldoc
        dired dired-x dired-aux ls-lisp
        python tramp ibuffer saveplace savehist recentf autorevert
        outline which-key tab-bar tab-line completion-preview
        display-fill-column-indicator pixel-scroll
        uniquify auth-source auth-source-pass jsonrpc))

(straight-use-package 'use-package)

;; ---------------------------------------------------------------------------
;; 11. First-boot package fetch
;; ---------------------------------------------------------------------------
(defvar my/straight-first-boot my/first-boot
  "Remember the first-boot state before any package is cloned.")

(defun my/straight-first-boot-fetch ()
  "Fetch straight.el recipe repositories once, on the very first boot."
  ;; Never do this in a daemon: a synchronous pull blocks emacsclient
  ;; connections until it finishes.
  (when (and my/straight-first-boot (not (daemonp)))
    (unless (or noninteractive (input-pending-p) current-prefix-arg)
      (message "First boot: fetching straight.el recipes (this may take a moment)...")
      (run-with-timer
       5 nil
       (lambda ()
         (condition-case err
             (straight-pull-recipe-repositories)
           (error (message "First boot: recipe fetch failed: %s"
                           (error-message-string err)))))))))

(add-hook 'after-init-hook #'my/straight-first-boot-fetch)
