;; customize settings go in seperate file
(setq custom-file "~/.emacs.d/custom.el")
(load custom-file)

; Package setup
(require 'package)
(add-to-list 'package-archives
	     '("melpa-stable" . "https://stable.melpa.org/packages/"))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))
(require 'diminish)
(require 'bind-key)


;; any site specific information
(add-to-list 'load-path "~/.emacs.d/conf/")
(setq site-file "~/.emacs.d/site-specific.el")
(when (file-exists-p site-file)
  (load site-file)
  )

;;;------------------------------------------------------------------------------
;;; setup completion

;; == yasnippet ==
(use-package yasnippet
  :ensure t
  :defer t
  :init
  (yas-reload-all)
  (add-hook 'prog-mode-hook #'yas-minor-mode)
  )
  

;; == irony-mode ==
(use-package irony
  :ensure t
  :defer t
  :init
  (add-hook 'c++-mode-hook 'irony-mode)
  (add-hook 'c-mode-hook 'irony-mode)
  (add-hook 'objc-mode-hook 'irony-mode)
  :config
  ;; replace the `completion-at-point' and `complete-symbol' bindings in
  ;; irony-mode's buffers by irony-mode's function
  (defun my-irony-mode-hook ()
    (define-key irony-mode-map [remap completion-at-point]
      'irony-completion-at-point-async)
    (define-key irony-mode-map [remap complete-symbol]
      'irony-completion-at-point-async))
  (add-hook 'irony-mode-hook 'my-irony-mode-hook)
  (add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)
  )

;; == company-mode ==
(use-package company
  :ensure t
  :defer t
  :init (add-hook 'after-init-hook 'global-company-mode)
  :config
  (use-package company-irony :ensure t :defer t)
  (setq company-idle-delay              nil
	company-minimum-prefix-length   2
	company-show-numbers            t
	company-tooltip-limit           20
	company-dabbrev-downcase        nil
	company-backends                '((company-irony company-gtags))
	)
  :bind ("C-;" . company-complete-common)
  )

;; == magit ==
(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status)
  )

;; == misc one liners ==
; doesn't seem to be working...
(setq backup-directory-alist '((".*" . "~/.emacs.d/autosaves/")))

;; == theme ==
(use-package zenburn-theme
  :ensure t
  )

;;------------------------------------------------------------------------------
;; mode overrides in order of precedence
;;------------------------------------------------------------------------------
;; magic-mode-alist (regex on first line) is highest precedence
(add-to-list 'magic-mode-alist '("#%Module" . tcl-mode)) ;modulefiles are tcl code
;; auto-mode-alist (regex on file-name) is next
;; magic-fallback-mode-alist is last


;;------------------------------------------------------------------------------
;;; misc one liners
;;------------------------------------------------------------------------------
;; always highlight current line
;;(global-hl-line-mode 1)
;; allow syntax highlighting 
;;(set-face-foreground 'highlight nil)

(show-paren-mode 1) ;; always show matching parenthesis
(setq column-number-mode t) ; shows column number at point // TODO - add visual line at some point
(setq-default indent-tabs-mode nil) ;; no tabs

(require 'rainbow-delimiters)
(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)

(which-function-mode 1) ; shows current function in mode-line

;;------------------------------------------------------------------------------
;;; org-mode
;;------------------------------------------------------------------------------
(add-hook 'org-mode-hook 'turn-on-visual-line-mode)

(setq org-src-fontify-natively t) ; fontify code in code blocks

;;------------------------------------------------------------------------------
;;; helm
;;------------------------------------------------------------------------------
(require 'helm-config)

(global-set-key (kbd "M-x") 'helm-M-x) ; use helm-M-x instead of M-x
(global-set-key (kbd "C-x b") 'helm-mini)
(helm-mode 1)

(projectile-global-mode)
(setq projectile-completion-system 'helm)
(setq projectile-enable-caching t)
(add-to-list 'projectile-other-file-alist '("cc" "h")) ; .cc -> .h
(add-to-list 'projectile-other-file-alist '("h" "cc")) ; .h -> .cc
(setq helm-projectile-fuzzy-match nil)
(helm-projectile-on) ;; must turn on helm-projectile-on after other settings

;;fuzzy
(setq helm-semantic-fuzzy-match t
      helm-imenu-fuzzy-match    t
      helm-M-x-fuzzy-match      t
      helm-recentf-fuzzy-match  t
      helm-buffers-fuzzy-matching t)

;;------------------------------------------------------------------------------
;;; verilog-mode 
;;------------------------------------------------------------------------------
;; Load verilog mode only when needed
(autoload 'verilog-mode "verilog-mode" "Verilog mode" t )
;; Any files that end in .v, .dv or .sv should be in verilog mode
(add-to-list 'auto-mode-alist '("\\.[ds]?v\\'" . verilog-mode))
(add-to-list 'auto-mode-alist '("\\.x\\'" . verilog-mode)) ; also the .x templates

;; Any files in verilog mode should have their keywords colorized
(add-hook 'verilog-mode-hook '(lambda () (font-lock-mode 1)))

;; Don't use tabs, set indentation width to 2
(add-hook 'verilog-mode-hook '(lambda () (setq verilog-indent-level 2)
                                         (setq verilog-indent-level-declaration 2)
                                         (setq verilog-indent-level-module 2)
                                         (setq indent-tabs-mode nil)
                                         (setq tab-width 2)))

;;------------------------------------------------------------------------------
;;; Custom functions
;;------------------------------------------------------------------------------
;; Toggle window split
(defun toggle-window-split ()
  "If the frame is split vertically, split it horizontally or vice versa.
Assumes that the frame is only split into two."
  (interactive)
  (if (= (count-windows) 2)
      (let* ((this-win-buffer (window-buffer))
	     (next-win-buffer (window-buffer (next-window)))
	     (this-win-edges (window-edges (selected-window)))
	     (next-win-edges (window-edges (next-window)))
	     (this-win-2nd (not (and (<= (car this-win-edges)
					 (car next-win-edges))
				     (<= (cadr this-win-edges)
					 (cadr next-win-edges)))))
	     (splitter
	      (if (= (car this-win-edges)
		     (car (window-edges (next-window))))
		  'split-window-horizontally
		'split-window-vertically)))
	(delete-other-windows)
	(let ((first-win (selected-window)))
	  (funcall splitter)
	  (if this-win-2nd (other-window 1))
	  (set-window-buffer (selected-window) this-win-buffer)
	  (set-window-buffer (next-window) next-win-buffer)
	  (select-window first-win)
	  (if this-win-2nd (other-window 1))))))

;; assign above function to keybinding C-x t 
(define-key ctl-x-map "t" 'toggle-window-split)

;; use C-c o to jump between header and impl in c-mode
(add-hook 'c-mode-common-hook
  (lambda() 
    (local-set-key  (kbd "C-c o") 'ff-find-other-file)))
