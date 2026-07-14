;;; init.el -*- lexical-binding: t; -*-
;;
;;; ---------------------------------------------------------------------
;;; Bootstrap (straight.el and use-package)
;;; ---------------------------------------------------------------------


(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)
(setq straight-use-package-by-default t)
(require 'use-package)
(setq use-package-always-defer nil
      use-package-expand-minimally t
      use-package-verbose nil)

(use-package exec-path-from-shell
  :if (memq window-system '(mac ns))
  :config
  (setq exec-path-from-shell-arguments '("-l"))
  (exec-path-from-shell-initialize))

;;; ---------------------------------------------------------------------
;;; 1. Performance
;;; ---------------------------------------------------------------------

;; Restore file-name-handler-alist and set a sane long-term GC threshold
;; once startup is finished, then use gcmh to manage GC during idle time
;; (this is exactly what Doom does).
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist rd/file-name-handler-alist-original)
            (setq gc-cons-threshold (* 16 1024 1024)  ; 16mb
                  gc-cons-percentage 0.1)
            (message "Emacs ready in %s with %d garbage collections."
                     (format "%.2f seconds"
                             (float-time (time-subtract after-init-time before-init-time)))
                     gcs-done)))

(use-package gcmh
  :hook (emacs-startup . gcmh-mode)
  :config
  (setq gcmh-idle-delay 5
        gcmh-high-cons-threshold (* 16 1024 1024)))

;; Increase process output chunk size (helps LSP / eglot throughput a lot).
(setq read-process-output-max (* 1024 1024))
(setq process-adaptive-read-buffering nil)

;; Reduce I/O and UI churn
(setq idle-update-delay 1.0)
(setq redisplay-skip-fontification-on-input t)
(setq inhibit-compacting-font-caches t)

;; Custom-file: keep customize-generated cruft out of init.el
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file nil 'nomessage))

;; because of lazy loading, every `setq' of a package-defined
;; variable gets flagged, so this is to ignore the resultant
;; warnings.
(dir-locals-set-class-variables
 'no-byte-compile-flymake
 '((emacs-lisp-mode . ((eval . (remove-hook 'flymake-diagnostic-functions
                                            #'elisp-flymake-byte-compile t))))))
(dir-locals-set-directory-class user-emacs-directory 'no-byte-compile-flymake)

;;; ---------------------------------------------------------------------
;;; 2. Sane defaults
;;; ---------------------------------------------------------------------

(setq-default
 delete-by-moving-to-trash t
 tab-width 8
 fill-column 80
 sentence-end-double-space nil
 indent-tabs-mode nil
 x-stretch-cursor nil)

(setq undo-limit 80000000
      truncate-string-ellipsis "…"
      scroll-margin 2
      scroll-conservatively 101
      auto-save-default t
      auto-save-interval 300
      make-backup-files nil
      create-lockfiles nil
      ring-bell-function #'ignore
      visible-bell nil
      confirm-kill-processes nil
      confirm-kill-emacs nil
      use-short-answers t
      kill-whole-line t
      require-final-newline t
      window-combination-resize t)

(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)
(save-place-mode 1)
(recentf-mode 1)
(setq recentf-max-saved-items 200)
(delete-selection-mode 1)
(global-visual-line-mode 1)
(setq-default global-prettify-symbols-mode t)
(electric-pair-mode -1)     ; smartparens takes over this job, see below
(context-menu-mode 1)
(add-hook 'text-mode-hook #'visual-line-mode)

;; UTF-8 everywhere
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(setq ispell-dictionary "british")

;; macOS specifics
(when (eq system-type 'darwin)
  (setq mac-command-modifier 'super
        mac-option-modifier 'meta
        mac-right-option-modifier nil
        ns-use-proxy-icon nil
        frame-title-format nil
        ns-pop-up-frames nil))

;; Native shell: match your Doom fish/bash setup
(setq shell-file-name (or (executable-find "bash") shell-file-name))

;;; ---------------------------------------------------------------------
;;; 3. UI: theme, fonts, modeline, line numbers
;;; ---------------------------------------------------------------------

(menu-bar-mode 1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(blink-cursor-mode -1)
(setq display-line-numbers-type t)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'conf-mode-hook #'display-line-numbers-mode)

;; Fonts (same faces you had in Doom)
(set-face-attribute 'default nil :family "Iosevka NF" :height 180)
(set-face-attribute 'fixed-pitch nil :family "Iosevka NF" :height 180)
(set-face-attribute 'variable-pitch nil :family "Fira Sans" :height 150)

(use-package doom-themes
  :config
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  (load-theme 'doom-tokyo-night t)
  (doom-themes-visual-bell-config)
  (doom-themes-org-config))

(custom-set-faces
 '(font-lock-comment-face ((t (:slant italic))))
 '(font-lock-keyword-face ((t (:slant italic)))))

(use-package doom-modeline
  :hook (emacs-startup . doom-modeline-mode)
  :config
  (setq doom-modeline-height 25
        doom-modeline-icon t
        doom-modeline-buffer-file-name-style 'truncate-upto-project))

(use-package nerd-icons)
(use-package nerd-icons-dired :hook (dired-mode . nerd-icons-dired-mode))
(use-package nerd-icons-ibuffer :hook (ibuffer-mode . nerd-icons-ibuffer-mode))
(use-package nerd-icons-completion
  :after marginalia
  :config (nerd-icons-completion-mode))

;; (use-package dashboard
;;   :hook (emacs-startup . dashboard-setup-startup-hook)
;;   :config
;;   (setq dashboard-banner-logo-title "Welcome back"
;;         dashboard-startup-banner 'logo
;;         dashboard-center-content t
;;         dashboard-vertically-center-content t
;;         dashboard-items '((recents . 5)
;;                           (projects . 5)
;;                           (agenda . 5))
;;         dashboard-set-heading-icons t
;;         dashboard-set-file-icons t
;;         dashboard-icon-type 'nerd-icons))

(use-package hl-todo
  :hook (prog-mode . hl-todo-mode))

(use-package ligature
  :hook (prog-mode . ligature-mode)
  :config
  (ligature-set-ligatures 'prog-mode
                          '("www" "**" "***" "**/" "*>" "*/" "\\\\" "\\\\\\"
                            "{-" "[]" "::" ":::" ":=" "!!" "!=" "!==" "-}"
                            "--" "---" "-->" "->" "->>" "-<" "-<<" "-~"
                            "#{" "#[" "##" "###" "####" "#(" "#?" "#_" "#_("
                            ".." "..<" "..." ".=" ".-" "?=" "??" ";;" "/*"
                            "/**" "/=" "/==" "/>" "//" "///" "&&" "||" "||="
                            "|=" "|>" "^=" "$>" "++" "+++" "+>" "=:=" "=="
                            "===" "==>" "=>" "=>>" "<=" "=<<" "=/=" ">-" ">="
                            ">=>" ">>" ">>-" ">>=" ">>>" "<*" "<*>" "<|" "<|>"
                            "<$" "<$>" "<!--" "<-" "<--" "<->" "<+" "<+>"
                            "<=" "<==" "<=>" "<=<" "<>" "<:" "<~" "<~~" "</"
                            "</>" "~@" "~-" "~=" "~>" "~~" "~~>" "%%")))

(use-package volatile-highlights
  :hook (emacs-startup . volatile-highlights-mode))

;; Workspaces: tab-bar-mode is built in and is a good Doom-workspaces analog
(use-package tabspaces
  :hook (emacs-startup . tabspaces-mode)
  :config
  (setq tabspaces-use-filtered-buffers-as-default t))

(use-package treemacs
  :defer t
  :config
  (setq treemacs-width 35))
(use-package treemacs-nerd-icons
  :after treemacs
  :config (treemacs-load-theme "nerd-icons"))

;;; ---------------------------------------------------------------------
;;; 4. Evil + keybinding framework (leader key, which-key)
;;; ---------------------------------------------------------------------

(use-package evil
  :hook (emacs-startup . evil-mode)
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-want-fine-undo t
        evil-undo-system 'undo-fu
        evil-search-module 'evil-search
        evil-respect-visual-line-mode t
        evil-symbol-word-search t)
  :config
  (evil-set-undo-system 'undo-fu))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

(use-package evil-surround
  :hook (emacs-startup . global-evil-surround-mode))

(use-package evil-commentary
  :hook (emacs-startup . evil-commentary-mode))

(use-package general
  :after evil
  :config
  (general-override-mode 1)
  (general-create-definer rd/leader-def
    :states '(normal visual motion insert emacs)
    :keymaps 'override
    :prefix "SPC"
    :non-normal-prefix "M-SPC")
  (general-create-definer rd/localleader-def
    :states '(normal visual motion insert emacs)
    :keymaps 'override
    :prefix "SPC m"
    :non-normal-prefix "M-SPC m"))

(use-package which-key
  :hook (emacs-startup . which-key-mode)
  :config
  (setq which-key-idle-delay 0.4))

;;; ---------------------------------------------------------------------
;;; 5. Completion: vertico / orderless / corfu / marginalia / consult / embark
;;; ---------------------------------------------------------------------

(use-package vertico
  :hook (emacs-startup . vertico-mode)
  :config
  (setq vertico-cycle t
        vertico-count 20))

(use-package orderless
  :config
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :hook (emacs-startup . marginalia-mode))

(use-package consult
  :general
  (rd/leader-def
    "SPC" #'consult-buffer
    "." #'find-file
    "f r" #'consult-recent-file
    "s s" #'consult-line
    "s p" #'consult-ripgrep
    "b b" #'consult-buffer))

(use-package embark
  :general
  (:states '(normal visual)
           "C-." #'embark-act))
(use-package embark-consult
  :after (embark consult))

(use-package corfu
  :hook (emacs-startup . global-corfu-mode)
  :config
  (setq corfu-auto t
        corfu-auto-delay 0.0
        corfu-auto-prefix 1
        corfu-cycle t
        corfu-preselect 'prompt))

(use-package cape
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block))

(use-package kind-icon
  :after corfu
  :config
  (setq kind-icon-default-face 'corfu-default)
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

;;; ---------------------------------------------------------------------
;;; 6. Project / files: project.el, dirvish, ibuffer
;;; ---------------------------------------------------------------------

(use-package projectile
  :hook (emacs-startup . projectile-mode)
  :config
  (setq projectile-completion-system 'default
        projectile-project-search-path '("~/code"))
  :general
  (rd/leader-def "p" '(:keymap projectile-command-map :package projectile)))

(use-package dirvish
  :hook (emacs-startup . dirvish-override-dired-mode)
  :config
  (setq dirvish-attributes '(nerd-icons file-time file-size collapse subtree-state vc-state)
        dirvish-use-mode-line t
        dirvish-use-header-line t))

(use-package ibuffer
  :straight nil
  :commands ibuffer)

;;; ---------------------------------------------------------------------
;;; 7. Version control: magit, diff-hl
;;; ---------------------------------------------------------------------

(use-package magit
  :commands (magit-status magit-blame)
  :general
  (rd/leader-def "g g" #'magit-status
    "g b" #'magit-blame))

(use-package diff-hl
  :hook ((emacs-startup . global-diff-hl-mode)
         (magit-post-refresh . diff-hl-magit-post-refresh)
         (dired-mode . diff-hl-dired-mode)))

;;; ---------------------------------------------------------------------
;;; 8. Editing: undo, smartparens, multiple-cursors, yasnippet, apheleia
;;; ---------------------------------------------------------------------

(use-package undo-fu)
(use-package undo-fu-session
  :hook (emacs-startup . undo-fu-session-global-mode))

(use-package smartparens
  :hook (prog-mode . smartparens-mode)
  :config
  (require 'smartparens-config))

(use-package multiple-cursors
  :general
  (:states '(normal visual)
           "C->" #'mc/mark-next-like-this
           "C-<" #'mc/mark-previous-like-this
           "C-c C-<" #'mc/mark-all-like-this))

(use-package yasnippet
  :hook (emacs-startup . yas-global-mode))
(use-package yasnippet-snippets :after yasnippet)

(use-package apheleia
  :hook (emacs-startup . apheleia-global-mode))

(use-package rotate-text
  :straight (rotate-text :type git :host github :repo "debug-ito/rotate-text.el")
  :general
  (rd/leader-def "- x" #'rotate-text))

;;; ---------------------------------------------------------------------
;;; 9. Checkers: flycheck, jinx spellcheck
;;; ---------------------------------------------------------------------

(use-package flycheck
  :hook (emacs-startup . global-flycheck-mode)
  :config
  (setq flycheck-indication-mode 'left-margin)
  :general
  (:states 'normal
           "] e" #'flycheck-next-error
           "[ e" #'flycheck-previous-error))
(use-package flycheck-posframe
  :hook (flycheck-mode . flycheck-posframe-mode))

(use-package jinx
  :hook (emacs-startup . global-jinx-mode)
  :general
  (:states '(normal) "z =" #'jinx-correct))

;;; ---------------------------------------------------------------------
;;; 10. Tools: eglot (LSP), tree-sitter, pdf-tools, dape, biblio
;;; ---------------------------------------------------------------------

;; eglot is built into Emacs 29+. This is the vanilla replacement for
;; Doom's (lsp +eglot +booster). "Booster" (emacs-lsp-booster) is an
;; external Rust binary that speeds up JSON-RPC parsing; if you install it
;; (cargo install --git https://github.com/blahgeek/emacs-lsp-booster),
;; the eglot-booster package below will wire it in automatically.
(use-package eglot
  :straight nil
  :hook ((c-mode c++-mode python-mode rust-mode sh-mode
                 web-mode zig-mode) . eglot-ensure)
  :config
  (setq eglot-autoshutdown t
        eglot-sync-connect nil
        eglot-events-buffer-size 0)
  :general
  (rd/localleader-def
    :keymaps 'eglot-mode-map
    "r" #'eglot-rename
    "a" #'eglot-code-actions
    "f" #'eglot-format))

(use-package eglot-booster
  :straight (eglot-booster :type git :host github :repo "jdtsmith/eglot-booster")
  :after eglot
  :config (eglot-booster-mode))

;; Tree-sitter: Emacs 30 has it built in (treesit.el). treesit-auto installs
;; and switches to the right grammars/major-modes automatically — the
;; vanilla analog of Doom's blanket +tree-sitter flags.
(use-package treesit-auto
  :hook (emacs-startup . global-treesit-auto-mode)
  :config
  (setq treesit-auto-install 'prompt))

(use-package pdf-tools
  :magic ("%PDF" . pdf-view-mode)
  :config
  (pdf-tools-install :no-query)
  (setq-default pdf-view-display-size 'fit-width))

(use-package dape
  :commands dape
  :config
  (setq dape-buffer-window-arrangement 'right))

(use-package biblio :commands biblio-lookup)

(use-package clippy :commands (clippy-describe-function clippy-describe-variable))

;;; ---------------------------------------------------------------------
;;; 11. Org: org, org-roam, org-roam-ui, org-alert, calfw, mixed-pitch
;;;     (custom functions/agenda views ported directly from your Doom config)
;;; ---------------------------------------------------------------------

(setq org-directory "~/org/")

(use-package org
  :straight nil
  :commands (org-mode org-agenda)
  :hook (org-mode . (lambda ()
                      (setq-local tab-width 8)
                      (advice-add 'org-check-tab-width :override #'ignore)))
  :config
  (advice-add 'org-check-tab-width :override #'ignore)
  (setq org-default-notes-file (expand-file-name "notes.org" org-directory)
        org-log-done t
        org-log-into-drawer nil
        org-hide-emphasis-markers t
        org-startup-indented t
        org-pretty-entities t
        org-todo-keywords
        '((sequence
           "TODO(t!)" "HW(h)" "CLASS(C)" "DEADLINE(l)" "PROJ(p)" "TEST(T)"
           "EVENT(e)" "EXAM(E)" "DOING(i)" "TODAY(o)"
           "|"
           "DONE(d!)" "CANCELLED(c)" "ANYTIME(a)")))

  (setq org-agenda-prefix-format
        '((todo . " %i %t %b ")
          (agenda . " %i %t %b ")
          (tags . " %i %t %b ")))

  (setq org-clock-persist 'history
        org-clock-in-resume t
        org-clock-out-remove-zero-time-clocks t)
  (org-clock-persistence-insinuate)

  (add-to-list 'org-modules 'org-habit t)
  (setq org-habit-preceding-days 7
        org-habit-following-days 3
        org-agenda-columns-add-appointments-to-effort-sum t)

  ;; --- org font setup (ported from rd/org-font-setup) ---
  (defun rd/org-font-setup ()
    (font-lock-add-keywords
     'org-mode
     '(("^ *\\([-]\\) "
        (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))
    (dolist (face '((org-level-1 . 1.4) (org-level-2 . 1.35) (org-level-3 . 1.3)
                    (org-level-4 . 1.25) (org-level-5 . 1.2) (org-level-6 . 1.1)
                    (org-level-7 . 1.1) (org-level-8 . 1.1)))
      (set-face-attribute (car face) nil :font "Iosevka NF" :weight 'regular :height (cdr face)))
    (set-face-attribute 'org-document-title nil :font "Fira Sans" :weight 'bold :height 1.5)
    (set-face-attribute 'org-block nil :foreground nil :inherit 'fixed-pitch)
    (set-face-attribute 'org-code nil :inherit '(shadow fixed-pitch))
    (set-face-attribute 'org-table nil :inherit '(shadow fixed-pitch))
    (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
    (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
    (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
    (set-face-attribute 'org-checkbox nil :inherit 'variable-pitch))
  (rd/org-font-setup)

  (defvar rd/org-heading-heights
    '((org-level-1 . 1.4) (org-level-2 . 1.35) (org-level-3 . 1.3)
      (org-level-4 . 1.25) (org-level-5 . 1.2) (org-level-6 . 1.1)
      (org-level-7 . 1.1) (org-level-8 . 1.1)))
  (defun rd/org-use-large-headings ()
    (interactive)
    (dolist (face rd/org-heading-heights) (set-face-attribute (car face) nil :height (cdr face))))
  (defun rd/org-use-normal-headings ()
    (interactive)
    (dolist (face rd/org-heading-heights) (set-face-attribute (car face) nil :height 1.0)))

  ;; --- year calendar (ported verbatim) ---
  (defun rd/year-calendar (&optional year)
    (interactive)
    (require 'calendar)
    (let* ((month 0)
           (year (if year year (string-to-number (format-time-string "%y" (current-time))))))
      (switch-to-buffer (get-buffer-create calendar-buffer))
      (when (not (eq major-mode 'calendar-mode)) (calendar-mode))
      (setq displayed-month month displayed-year year)
      (setq buffer-read-only nil)
      (erase-buffer)
      (dotimes (_ 4)
        (dotimes (i 3)
          (calendar-generate-month (setq month (+ month 1)) year (+ 5 (* 25 i))))
        (goto-char (point-max))
        (insert (make-string (- 10 (count-lines (point-min) (point-max))) ?\n))
        (widen)
        (goto-char (point-max))
        (narrow-to-region (point-max) (point-max)))
      (widen)
      (goto-char (point-min))
      (setq buffer-read-only t)))
  (defalias 'year-calendar 'rd/year-calendar)

  (defun rd/scroll-year-calendar-forward (&optional arg event)
    (interactive (list (prefix-numeric-value current-prefix-arg) last-nonmenu-event))
    (unless arg (setq arg 0))
    (save-selected-window
      (if (setq event (event-start event)) (select-window (posn-window event)))
      (unless (zerop arg) (rd/year-calendar (+ displayed-year arg)))
      (goto-char (point-min))
      (run-hooks 'calendar-move-hook)))
  (defun rd/scroll-year-calendar-backward (&optional arg event)
    (interactive (list (prefix-numeric-value current-prefix-arg) last-nonmenu-event))
    (rd/scroll-year-calendar-forward (- (or arg 1)) event))

  ;; --- agenda file discovery (ported verbatim) ---
  (defun rd/org-files-with-tag (dir tag)
    (let ((files (directory-files-recursively dir "\\.org$")) result)
      (dolist (f files result)
        (with-temp-buffer
          (insert-file-contents f nil 0 1000)
          (goto-char (point-min))
          (when (re-search-forward (concat ":" tag ":") nil t) (push f result))))))

  (defun rd/org-files-with-tag-filter (dir tag)
    (let* ((files (directory-files-recursively dir "\\.org$"))
           (filtered (seq-remove (lambda (f)
                                   (or (string-match-p "/logseq/" f)
                                       (string-match-p "/\\.git/" f)))
                                 files))
           result)
      (dolist (f filtered result)
        (with-temp-buffer
          (insert-file-contents f nil 0 1000)
          (goto-char (point-min))
          (when (re-search-forward (concat ":" tag ":") nil t) (push f result))))))

  (defun rd/refresh-org-agenda-files-advice (&rest _)
    (interactive)
    (setq org-agenda-files (rd/org-files-with-tag "~/org" "tasks")))

  (setq org-agenda-files (rd/org-files-with-tag-filter "~/org" "tasks"))

  (defun rd/org-roam-copy-todo-to-today ()
    "Copy completed TODOs into today's daily note."
    (interactive)
    (let ((org-refile-keep t)
          (org-roam-dailies-capture-templates
           '(("t" "tasks" entry "%?"
              :if-new (file+head+olp "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n"
                                     ("\nTasks")))))
          (org-after-refile-insert-hook #'save-buffer)
          today-file pos)
      (save-window-excursion
        (org-roam-dailies--capture (current-time) t)
        (setq today-file (buffer-file-name))
        (setq pos (point)))
      (unless (equal (file-truename today-file) (file-truename (buffer-file-name)))
        (org-refile nil nil (list "Tasks" today-file nil pos)))))
  (add-hook 'org-after-todo-state-change-hook
            (lambda () (when (equal org-state "DONE") (rd/org-roam-copy-todo-to-today))))

  (defun rd/org-toggle-variable-pitch ()
    (interactive)
    (if (bound-and-true-p mixed-pitch-mode) (mixed-pitch-mode -1) (mixed-pitch-mode 1)))

  (setq org-agenda-custom-commands
        '(("v" "A better agenda view"
           ((tags "PRIORITY=\"A\""
                  ((org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                   (org-agenda-overriding-header "High priority:")))
            (tags "PRIORITY=\"B\""
                  ((org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                   (org-agenda-overriding-header "Medium priority:")))
            (tags-todo "+STYLE=\"habit\"" ((org-agenda-overriding-header "Habits:")))
            (tags "school"
                  ((org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                   (org-agenda-overriding-header "School:")))
            (tags "personal"
                  ((org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                   (org-agenda-overriding-header "Personal:")))
            (tags "project"
                  ((org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                   (org-agenda-overriding-header "Projects:")))
            (agenda "" ((org-agenda-span 14)))
            (alltodo "")
            (tags-todo "EVENT" ((org-agenda-overriding-header "Events:")))
            (tags-todo "ANYTIME" ((org-agenda-overriding-header "Anytime:")))))
          ("h" "Agenda 2"
           ((agenda "" ((org-agenda-skip-scheduled-if-done t)
                        (org-agenda-time-leading-zero t)
                        (org-agenda-timegrid-use-ampm nil)
                        (org-agenda-skip-timestamp-if-done t)
                        (org-agenda-skip-deadline-if-done t)
                        (org-agenda-start-day "+0d")
                        (org-agenda-span 7)
                        (org-agenda-overriding-header "Calendar")
                        (org-agenda-remove-tags t)
                        (org-agenda-prefix-format "   %i %?-2 t%s")
                        (org-agenda-todo-keyword-format "")
                        (org-agenda-current-time-string "ᐊ┈┈┈┈┈┈┈ Now")
                        (org-agenda-scheduled-leaders '("Scheduled: " "In %2d d.: "))
                        (org-agenda-deadline-leaders '("Deadline:  " "In %3d d.: " "%2d d. ago: "))
                        (org-agenda-time-grid (quote ((today require-timed remove-match) () "      " "┈┈┈┈┈┈┈┈┈┈┈┈┈")))))
            (tags "+TODO=\"TODO\""
                  ((org-agenda-overriding-header "\nToday")
                   (org-agenda-sorting-strategy '(priority-down))
                   (org-agenda-remove-tags t)
                   (org-agenda-skip-function '(org-agenda-skip-entry-if 'timestamp 'scheduled))
                   (org-agenda-prefix-format "   %-2i ")))
            (tags "TODO=\"PROJ\""
                  ((org-agenda-overriding-header "\n Projects")
                   (org-agenda-remove-tags t)
                   (org-tags-match-list-sublevels nil)
                   (org-agenda-show-inherited-tags nil)
                   (org-agenda-prefix-format "   %-2i %?b")
                   (org-agenda-todo-keyword-format "")))))
          ("d" "Daily Dashboard"
           ((agenda "" ((org-agenda-span 'day)
                        (org-agenda-start-on-weekday nil)
                        (org-agenda-overriding-header "Today's Schedule")
                        (org-agenda-use-time-grid t)
                        (org-agenda-time-grid '((daily today require-timed)
                                                (480 600 720 840 960 1080 1200)
                                                "......" "----------------"))))
            (todo "TODO" ((org-agenda-overriding-header "Tasks")))))
          ("u" "Upcoming Deadlines"
           ((agenda "" ((org-agenda-span 14) (org-agenda-entry-types '(:deadline))))))
          ("f" "Agenda + TODO"
           ((agenda "" ((org-agenda-prefix-format "     ")
                        (org-agenda-scheduled-leaders '("Scheduled: " "In %2d d.: "))
                        (org-agenda-deadline-leaders '("Deadline:  " "In %3d d.: " "%2d d. ago: "))))
            (todo "TODO" ((org-agenda-overriding-header "TODOs")
                          (org-agenda-prefix-format "     ")
                          (org-agenda-show-inherited-tags t)
                          (org-agenda-sorting-strategy '(deadline-up priority-down))
                          (org-agenda-todo-ignore-deadlines nil)))
            (todo "DOING" ((org-agenda-overriding-header "Doing")
                           (org-agenda-prefix-format "     ")
                           (org-agenda-show-inherited-tags t)
                           (org-agenda-sorting-strategy '(deadline-up priority-down))
                           (org-agenda-todo-ignore-deadlines nil)))
            (todo "TODAY" ((org-agenda-overriding-header "Today")
                           (org-agenda-prefix-format "     ")
                           (org-agenda-show-inherited-tags t)
                           (org-agenda-sorting-strategy '(deadline-up priority-down))
                           (org-agenda-todo-ignore-deadlines nil)))))
          ("c" "School Dashboard"
           ((agenda "" ((org-agenda-span 14)
                        (org-agenda-overriding-header "Agenda")
                        (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                        (org-agenda-tag-filter-preset '("+sch"))))
            (tags "sch+eng" ((org-agenda-overriding-header "English")
                             (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))))
            (tags "sch+math" ((org-agenda-overriding-header "Mathematics")
                              (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))))
            (tags "sch+esp" ((org-agenda-overriding-header "Spanish")
                             (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))))
            (tags "sch+phy" ((org-agenda-overriding-header "Physics")
                             (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))))
            (tags "sch+chem" ((org-agenda-overriding-header "Chemistry")
                              (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))))
            (tags "sch+eco" ((org-agenda-overriding-header "Economics")
                             (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))))
            (tags "sch+ee" ((org-agenda-overriding-header "Extended Essay")
                            (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))))
            (tags "sch+tok" ((org-agenda-overriding-header "Theory of Knowledge")
                             (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))))
            (tags "sch+cas" ((org-agenda-overriding-header "CAS")
                             (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))))
            (tags "sch-eng-math-esp-phy-chem-eco-ee-tok-cas"
                  ((org-agenda-overriding-header "Other School Tasks")
                   (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done)))))
           ((org-agenda-sticky t))))))

(use-package org-superstar
  :hook (org-mode . org-superstar-mode))

(use-package mixed-pitch
  :hook (org-mode . mixed-pitch-mode)
  :config
  (setq mixed-pitch-set-height t
        mixed-pitch-variable-pitch-cursor nil))

(use-package org-roam
  :after org
  :init (setq org-roam-v2-ack t)
  :config
  (setq org-roam-directory (file-truename "~/org/roam")
        org-roam-node-annotation-function (lambda (_node) "")
        org-roam-node-display-template "${title:*} ${tags:20}"
        org-roam-dailies-directory "journals/"
        org-roam-file-exclude-regexp "\\.git\\|/logseq/"
        org-roam-database-connector 'sqlite-builtin
        org-attach-id-dir "~/org/roam/assets"
        org-roam-capture-templates
        '(("d" "default" plain "#+filetags: %?"
           :target (file+head "pages/%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+date: %U\n")
           :unarrowed t :immediate-finish t))
        org-roam-dailies-capture-templates
        '(("d" "default" entry "* %?"
           :target (file+head "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n"))))
  (org-roam-db-autosync-mode)

  (defun org-roam-node-insert-immediate (arg &rest args)
    (interactive "P")
    (let ((args (cons arg args))
          (org-roam-capture-templates
           (list (append (car org-roam-capture-templates) '(:immediate-finish t)))))
      (apply #'org-roam-node-insert args)))

  (require 'org-roam)
  (defun rd/open-current-agenda ()
    "Open this month's agenda note."
    (interactive)
    (let* ((title (format-time-string "%Y %B Agenda"))
           (node (seq-find (lambda (node) (string= (org-roam-node-title node) title))
                           (org-roam-node-list))))
      (if node (org-roam-node-visit node)
        (user-error "No agenda found with title: %s" title))))

  (defun rd/open-monthly-agenda ()
    "Open one of the monthly agenda files."
    (interactive)
    (let* ((nodes (seq-filter (lambda (node) (member "monthly" (org-roam-node-tags node)))
                              (org-roam-node-list)))
           (choices (mapcar (lambda (node) (cons (org-roam-node-title node) node))
                            (sort nodes (lambda (a b) (string< (org-roam-node-title a)
                                                               (org-roam-node-title b)))))))
      (if-let ((choice (completing-read "Monthly agenda: " (mapcar #'car choices) nil t)))
          (org-roam-node-visit (cdr (assoc choice choices)))
        (user-error "No monthly agenda selected")))))

(use-package org-roam-ui
  :after org-roam
  :commands org-roam-ui-open
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start nil))

(use-package org-hyperscheduler
  :straight (org-hyperscheduler :type git :host github :repo "dmitrym0/org-hyperscheduler")
  :commands org-hyperscheduler-open)

(use-package org-alert
  :after org
  :custom (alert-default-style 'osx-notifier)
  :config
  (setq org-alert-interval 600
        org-alert-notify-cutoff 10
        org-alert-notify-after-event-cutoff 0
        org-alert-notification-title "Org Reminder")
  (org-alert-enable)
  (advice-add 'org-alert--deadline-items :filter-return
              (lambda (items)
                (cl-remove-if
                 (lambda (item)
                   (with-current-buffer (marker-buffer (car item))
                     (save-excursion
                       (goto-char (car item))
                       (member "n" (org-get-tags)))))
                 items))))

;; (use-package ht)

;; (use-package calfw :commands cfw:open-org-calendar)
;; (use-package calfw-org :after calfw :commands cfw:open-org-calendar)

(use-package visual-fill-column
  :hook (org-mode . visual-fill-column-mode)
  :config
  (setq visual-fill-column-width 75
        visual-fill-column-center-text t))

;;; ---------------------------------------------------------------------
;;;  Languages
;;; ---------------------------------------------------------------------


(use-package auctex
  :defer t
  :hook ((LaTeX-mode . auctex-latexmk-setup)
         (LaTeX-mode . eglot-ensure))
  :config
  (setq TeX-source-correlate-method 'synctex
        TeX-view-program-list
        '(("Skim" "/Applications/Skim.app/Contents/SharedSupport/displayline -g -b %n %o %b"))
        TeX-view-program-selection '((output-pdf "Skim"))
        TeX-auto-save t
        TeX-parse-self t
        TeX-save-query nil
        TeX-master 'dwim)
  :general
  (rd/localleader-def :keymaps 'LaTeX-mode-map "p" #'+latex/live-preview))
(use-package auctex-latexmk :after auctex)
(use-package cdlatex :hook (LaTeX-mode . cdlatex-mode))

;; Python
(use-package python
  :straight nil
  :defer t
  :config (setq python-indent-guess-indent-offset-verbose nil))
(use-package pyvenv :hook (python-mode . pyvenv-mode))

;; Rust
(use-package rust-mode
  :mode "\\.rs\\'"
  :config (setq rust-format-on-save nil))


;; Web
(use-package web-mode
  :mode ("\\.html?\\'" "\\.css\\'" "\\.jsx?\\'" "\\.tsx?\\'"))

;; YAML
(use-package yaml-mode :mode "\\.ya?ml\\'")

;; Zig
;; (use-package zig-mode :mode "\\.zig\\'")

;; Markdown
;; (use-package markdown-mode
;;   :mode ("README\\.md\\'" . gfm-mode)
;;   :init (setq markdown-command "multimarkdown"))

;; Typst
;; (use-package typst-ts-mode
;;   :straight (typst-ts-mode :type git :host github :repo "Ziqi-Yang/typst-ts-mode")
;;   :mode "\\.typ\\'"
;;   :config
;;   (setq typst-ts-mode-enable-raw-blocks-highlight t))

;; PlatformIO
(use-package platformio-mode
  :hook (c++-mode . platformio-conditionally-enable))

(use-package rainbow-delimiters
  :hook ((emacs-lisp-mode lisp-interaction-mode) . rainbow-delimiters-mode))
(use-package highlight-quoted
  :hook ((emacs-lisp-mode lisp-interaction-mode) . highlight-quoted-mode))
(use-package highlight-numbers
  :hook (prog-mode . highlight-numbers-mode))
(use-package highlight-defined
  :hook ((emacs-lisp-mode lisp-interaction-mode) . highlight-defined-mode))
(use-package paren-face
  :hook ((emacs-lisp-mode lisp-interaction-mode) . paren-face-mode))
(use-package lisp-extra-font-lock
  :hook ((emacs-lisp-mode lisp-interaction-mode) . lisp-extra-font-lock-mode))

(defun rd/evil-escape ()
  "Clear evil search highlighting if applicable."
  (interactive)
  (if (evil-ex-hl-active-p 'evil-ex-search)
      (evil-ex-nohighlight)))

(rd/leader-def
  "<left>"  #'rd/scroll-year-calendar-backward
  "<right>" #'rd/scroll-year-calendar-forward

  "- d c" (lambda () (interactive) (find-file "~/.config/rdemacs/init.el"))
  "- d i" (lambda () (interactive) (find-file "~/.emacs.d/early-init.el"))
  "- a"   #'auto-complete-mode
  "- b"   #'apheleia-format-buffer
  "- h"   #'org-insert-heading
  "- g"   #'rd/open-current-agenda
  "- m"   #'rd/open-monthly-agenda
  "- t"   (lambda () (interactive) (find-file "~/org/roam/pages/tasks.org"))
  "- x"   #'rotate-text

  "o n"   #'treemacs

  "n r u" #'org-roam-ui-open
  "n r h" #'org-hyperscheduler-open
  "n r s" #'org-roam-db-sync
  "n r f" #'org-roam-node-find
  "n r i" #'org-roam-node-insert
  "n r d t" #'org-roam-dailies-goto-today
  "n r d y" #'org-roam-dailies-goto-yesterday
  "n r d o" #'org-roam-dailies-goto-tomorrow

  "m c i" #'org-clock-in
  "m c i" #'org-clock-out
  "t p"   #'rd/org-toggle-variable-pitch


  "c h f" #'clippy-describe-function
  "c h v" #'clippy-describe-variable

  "d d"   #'dired
  "d j"   #'dired-jump
  "d v"   #'dired-view-file

  "m e b" #'eval-buffer
  "m e r" #'eval-region
  "m e d" #'eval-defun)

(provide 'init)
;;; init.el ends here
