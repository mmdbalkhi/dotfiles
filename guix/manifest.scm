(use-modules (guix profiles)
             (guix packages)
             (gnu packages)
             (ice-9 ftw)
             (ice-9 match))
(define %manifest-dir
  (let ((this-file (or (current-filename)
                       (error "Cannot determine current filename"))))
    (string-append (dirname this-file) "/manifests")))

(define (load-group name)
  (load (string-append %manifest-dir "/" name ".scm")))

(load-group "core")
(load-group "python")
(load-group "go")
(load-group "rust")
(load-group "c")
(load-group "web")
(load-group "scheme")
(load-group "ocaml")
(load-group "treesitter")
(load-group "tags")
(load-group "emacs")
(load-group "dev")
(load-group "tools")

(define %all-packages
  (append %core-packages
          %devel-packages
          %python-packages
          %go-packages
          %rust-packages
          %c-packages
          %web-packages
          %scheme-packages
          %ocaml-packages
          %treesitter-packages
          %tags-packages
          %emacs-packages
          %tools-packages))

;;; Default: install everything
(specifications->manifest %all-packages)
