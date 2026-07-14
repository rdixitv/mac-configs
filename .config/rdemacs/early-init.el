;;; early-init.el -*- lexical-binding: t; -*-
;; Loaded before init.el, before package.el, before the frame is created.
;; Keep this file minimal and fast — anything here delays the first frame.

;; --- Garbage collection ------------------------------------------------
;; Doom does this too: make GC nearly free during startup, restore a sane
;; (but still generous) threshold once we're idle after startup.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; --- Don't use package.el; straight.el will manage everything ----------
(setq package-enable-at-startup nil)

;; --- Skip UI redraws / feature probing during startup -------------------
(setq frame-inhibit-implied-resize t
      inhibit-startup-screen t
      inhibit-startup-echo-area-message user-login-name
      inhibit-default-init t
      initial-scratch-message nil
      ;; Redisplay is a big cost pre-init; don't waste cycles on it.
      inhibit-compacting-font-caches t)

;; --- Strip chrome before frame creation (cheaper than doing it in init) -
(push '(menu-bar-lines . 1) default-frame-alist)   ; macOS: keep native menu bar
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(undecorated . t) default-frame-alist)      ; matches your Doom config
(setq tool-bar-mode nil
      scroll-bar-mode nil)

;; --- Native compilation --------------------------------------------------
(when (featurep 'native-compile)
  (setq native-comp-async-report-warnings-errors 'silent
        native-comp-deferred-compilation t
        native-comp-jit-compilation t))
;; Silence bytecomp/native-comp warnings from arriving as popups
(setq warning-minimum-level :error)

;; --- File-name-handler-alist trick ---------------------------------------
;; Temporarily unset it (it's consulted on every `require', `load'); restore
;; after startup. This is the single biggest classic startup-speed win.
(defvar rd/file-name-handler-alist-original file-name-handler-alist)
(setq file-name-handler-alist nil)

;; --- straight.el wants this off during bootstrap -------------------------
(setq straight-check-for-modifications '(check-on-save find-when-checking))

;; Avoid loading outdated compiled files
(setq load-prefer-newer noninteractive)

(setq frame-resize-pixelwise t
      window-resize-pixelwise t)

(provide 'early-init)
;;; early-init.el ends here
