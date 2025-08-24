;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-


(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
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

(setq doom-font (font-spec :family "Iosevka NF" :size 18)
      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 15)
      doom-big-font (font-spec :family "Iosevka NF" :size 28)
      doom-symbol-font (font-spec :family "Iosevka NF" :size 24))


(after! doom-themes
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  (doom-themes-visual-bell-config))

(custom-set-faces!
  '(font-lock-comment-face :slant italic)
  '(font-lock-keyword-face :slant italic))
(setq global-prettify-symbols-mode t)

(global-visual-line-mode t)
(setq kill-whole-line t)

(defun rd/year-calendar (&optional year)
  (interactive)
  (require 'calendar)
  (let* (
         ;; (current-year (number-to-string (nth 5 (decode-time (current-time)))))
         (month 0)
         (year (if year year (string-to-number (format-time-string "%y" (current-time))))))
    (switch-to-buffer (get-buffer-create calendar-buffer))
    (when (not (eq major-mode 'calendar-mode))
      (calendar-mode))
    (setq displayed-month month)
    (setq displayed-year year)
    (setq buffer-read-only nil)
    (erase-buffer)
    ;; horizontal rows
    (dotimes (_ 4)
      ;; vertical columns
      (dotimes (i 3)
        (calendar-generate-month
         (setq month (+ month 1))
         year
         ;; indentation / spacing between months
         (+ 5 (* 25 i))))
      (goto-char (point-max))
      (insert (make-string (- 10 (count-lines (point-min) (point-max))) ?\n))
      (widen)
      (goto-char (point-max))
      (narrow-to-region (point-max) (point-max)))
    (widen)
    (goto-char (point-min))
    (setq buffer-read-only t)))

(defun rd/scroll-year-calendar-forward (&optional arg event)
  "scroll the yearly calendar by year in a forward direction."
  (interactive (list (prefix-numeric-value current-prefix-arg)
                     last-nonmenu-event))
  (unless arg (setq arg 0))
  (save-selected-window
    (if (setq event (event-start event)) (select-window (posn-window event)))
    (unless (zerop arg)
      (let* (
             (year (+ displayed-year arg)))
        (rd/year-calendar year)))
    (goto-char (point-min))
    (run-hooks 'calendar-move-hook)))

(defun rd/scroll-year-calendar-backward (&optional arg event)
  "scroll the yearly calendar by year in a backward direction."
  (interactive (list (prefix-numeric-value current-prefix-arg)
                     last-nonmenu-event))
  (rd/scroll-year-calendar-forward (- (or arg 1)) event))

(map! :leader
      :desc "scroll year calendar backward" "<left>" #'rd/scroll-year-calendar-backward
      :desc "scroll year calendar forward" "<right>" #'rd/scroll-year-calendar-forward)

(defalias 'year-calendar 'rd/year-calendar)
(map! :leader
      :desc "Edit doom config"
      "- d c" #'(lambda () (interactive) (find-file "~/.config/doom/config.el"))
      :leader
      :desc "Edit doom packages"
      "- d p" #'(lambda () (interactive) (find-file "~/.config/doom/packages.el"))
      :leader
      :desc "Edit doom init"
      "- d i" #'(lambda () (interactive) (find-file "~/.config/doom/init.el"))
      :leader
      :desc "Edit fish config"
      "- f" #'(lambda () (interactive) (find-file "~/.config/fish/config.fish"))
      :leader
      :desc "Edit agenda"
      "- o" #'(lambda () (interactive) (find-file "~/org/agenda.org"))
      :leader
      :desc "Rust Mode"
      "- r" #'rust-mode
      :leader
      :desc "Autocomplete mode"
      "- a" #'auto-complete-mode
      :leader
      :desc "Format file"
      "- b" #'eglot-format
      :leader
      :desc "Toggle Neotree"
      "o n" #'neotree-toggle
      :leader
      :desc "Insert org heading"
      "- h" #'org-insert-heading
      :leader
      :desc "Open Emacs Keybindings Cheat Sheet"
      "- e" #'(lambda () (interactive) (find-file "~/org-mode/emacs-vs-evil.org")))

(map! :leader
      (:prefix ("c h" . "Help info from clippy")
       :desc "Describe function under pointer" "f"
       #'clippy-describe-function
       :desc "Describe variable under pointer" "v"
       #'clippy-describe-variable))

(map! :leader
      (:prefix ("d" . "dired")
       :desc "Open dired" "d"
       #'dired
       :desc "Dired jump to current" "j"
       #'dired-jump
       :desc "Dired view file" "v"
       #'dired-view-file))


(after! org
  (defun rd/org-font-setup ()
    ;; replace list hyphen with dot
    (font-lock-add-keywords 'org-mode
			    '(("^ *\\([-]\\) "
			       (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))

    ;; set faces for heading levels
    (dolist (face '((org-level-1 . 1.7)
		    (org-level-2 . 1.5)
		    (org-level-3 . 1.4)
		    (org-level-4 . 1.3)
		    (org-level-5 . 1.2)
		    (org-level-6 . 1.1)
		    (org-level-7 . 1.1)
		    (org-level-8 . 1.1)))
      (set-face-attribute (car face) nil :font "fira sans" :weight 'regular :height (cdr face)))

    ;; ensure that anything that should be fixed-pitch in org files appears that way
    (set-face-attribute 'org-block nil :foreground nil :inherit 'fixed-pitch)
    (set-face-attribute 'org-code nil   :inherit '(shadow fixed-pitch))
    (set-face-attribute 'org-table nil   :inherit '(shadow fixed-pitch))
    (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
    (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
    (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
    (set-face-attribute 'org-checkbox nil :inherit 'varible-pitch))
  (setq org-directory "~/org/"
        org-default-notes-file (expand-file-name "notes.org" org-directory)
        org-ellipsis " ▼ "
        org-log-done 'time
        org-hide-emphasis-markers t
        org-todo-keywords
        '((sequence
           "TODO(t)"
           "HOMEWORK(h)"
           "CLASS(C)"
           "DEADLINE(l)"
           "PROJ(p)"
           "TEST(T)"
           "EVENT(e)"
           "EXAM(E)"
           "|"
           "DONE(d)"
           "CANCELLED(c)"
           "ANYTIME(a)")))
  (rd/org-font-setup))

(setq org-agenda-custom-commands
      '(("v" "A better agenda view"
         ((tags "PRIORITY=\"A\""
                ((org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                 (org-agenda-overriding-header "High priority:")))
          (tags "PRIORITY=\"B\""
                ((org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                 (org-agenda-overriding-header "Medium priority:")))
          (tags "PRIORITY=\"C\""
                ((org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                 (org-agenda-overriding-header "Low priority:")))
          (tags "school"
                ((org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                 (org-agenda-overriding-header "School:")))
          (tags "classes"
                ((org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                 (org-agenda-overriding-header "Classes:")))
          (tags "personal"
                ((org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                 (org-agenda-overriding-header "Personal")))
          (agenda "")
          (alltodo "")))))


(setq lsp-auto-guess-root nil)


(setq shell-file-name (executable-find "bash"))
(setq-default vterm-shell (executable-find "fish"))
(setq-default explicit-shell-file-name (executable-find "fish"))

(map! :leader
      :desc "Format buffer" "- -"
      #'+format/buffer)

(setq org-roam-node-display-template "${title:*} ${tags:20}")
(setq org-agenda-files '("~/org/roam/"))
(setq org-agenda-prefix-format
      '((todo . " %i %b %t ")
        (agenda . " %i %t %b")))
(setq org-roam-graph-viewer nil
      org-roam-graph-executable "dot")
(setq org-roam-capture-templates
      '(("d" "default" plain
         "#+filetags: %?"
         :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+date: %U\n")
         :unarrowed t
         :immediate-finish t)))


(defun org-roam-node-insert-immediate (arg &rest args)
  (interactive "P")
  (let ((args (cons arg args))
        (org-roam-capture-templates (list (append (car org-roam-capture-templates)
                                                  '(:immediate-finish t)))))
    (apply #'org-roam-node-insert args)))
(setq org-roam-database-connector 'sqlite-builtin)

(setq visual-fill-column-width 75
      visual-fill-column-center-text t)

(setq confirm-kill-processes nil
      confirm-kill-emacs nil)

(setq +latex-viewers '(pdf-tools))

(setq corfu-auto t
      corfu-auto-delay 0.0)
