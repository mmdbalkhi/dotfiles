;;; early-init.el --- Early init -*- lexical-binding: t; no-byte-compile: t -*-
;; Generated from readme.org – edit the Org file, not this one.

;; GC: push the threshold up for startup.  It is restored on
;; `emacs-startup-hook', which also runs under --daemon.
(setq gc-cons-threshold  most-positive-fixnum
      gc-cons-percentage 0.6)

;; An empty `file-name-handler-alist' speeds up every load during startup.
(defvar my--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist
                  (delete-dups (append file-name-handler-alist
                                       my--file-name-handler-alist))
                  gc-cons-threshold  (* 16 1024 1024)
                  gc-cons-percentage 0.1))
          90)

;; Native compilation: keep JIT enabled, but do not pop up warning buffers.
(setq native-comp-async-report-warnings-errors 'silent)
(when (and (fboundp 'startup-redirect-eln-cache)
           (boundp 'native-comp-eln-load-path))
  (startup-redirect-eln-cache
   (expand-file-name "eln-cache/" user-emacs-directory)))

;; package.el is initialised by hand in init.el.
(setq package-enable-at-startup nil)

;; Enable package quickstart - creates a cache that skips package checks
(setq package-quickstart t)

;; No flash of an unstyled frame.
(push '(menu-bar-lines . 0)          default-frame-alist)
(push '(tool-bar-lines . 0)          default-frame-alist)
(push '(vertical-scroll-bars . nil)  default-frame-alist)
(setq frame-inhibit-implied-resize t
      use-file-dialog              nil
      inhibit-startup-screen       t
      inhibit-startup-message      t
      inhibit-startup-echo-area-message user-login-name)
