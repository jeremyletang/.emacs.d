(require 'package)
(add-to-list 'load-path "~/.emacs.d/pkg")
(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
                    (not (gnutls-available-p))))
       (proto (if no-ssl "http" "https")))
  ;; Comment/uncomment these two lines to enable/disable MELPA and MELPA Stable as desired
  (add-to-list 'package-archives (cons "melpa" (concat proto "://melpa.org/packages/")) t)
  ;;(add-to-list 'package-archives (cons "melpa-stable" (concat proto "://stable.melpa.org/packages/")) t)
  (when (< emacs-major-version 24)
    ;; For important compatibility libraries like cl-lib
    (add-to-list 'package-archives (cons "gnu" (concat proto "://elpa.gnu.org/packages/")))))
(package-initialize)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   (quote
    (yaml-mode toml-mode rust-mode terraform-mode cmake-mode irony go-add-tags linum-off go-guru go-rename go-mode))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; backup files
(setq backup-directory-alist `(("." . "~/.emacs.d/.backup")))
(setq backup-by-copying t)

;; disable linum for a given list of major modes
(require 'linum-off)

(require 'linum-highlight-current-line-number)
(setq linum-format 'linum-highlight-current-line-number)

;; enable line numbe mode
(global-linum-mode t)
(global-visual-line-mode t)

;; enable column number mode display
(column-number-mode t)

;; remove whitespace before save
(add-hook 'before-save-hook 'delete-trailing-whitespace)

;; move lines faster
(global-set-key (kbd "C-n")
		(lambda () (interactive) (forward-line 10)))
(global-set-key (kbd "C-p")
		(lambda () (interactive) (forward-line -10)))


(setq tab-width 2)
(setq default-tab-width 2)

;; go-mode

(add-hook 'go-mode-hook #'go-guru-hl-identifier-mode)

(setq exec-path (cons "/usr/local/go/bin" exec-path))
(add-to-list 'exec-path "/Users/jeremy/work/go/bin")

(defun gomode-on-save-hook ()
  ;; goimports as gofmt
  (setq gofmt-command "goimports")
  (add-hook 'before-save-hook 'gofmt-before-save)

  ;; custom compile
  (if (not (string-match "go" compile-command))
      (set (make-local-variable 'compile-command)
	   "go generate && go build -v && go test -v && go vet"))

  )

(add-hook 'go-mode-hook 'gomode-on-save-hook)

(require 'go-autocomplete)
(require 'auto-complete-config)
(ac-config-default)
(add-hook 'completion-at-point-functions 'go-complete-at-point)

;; c++ autocompletion

;; =============
;; irony-mode
;; =============
(add-hook 'c++-mode-hook 'irony-mode)
(add-hook 'c-mode-hook 'irony-mode)
(add-hook 'objc-mode-hook 'irony-mode)
(add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)

;; =============
;; company mode
;; =============
(add-hook 'c++-mode-hook 'company-mode)
(add-hook 'c-mode-hook 'company-mode)
;; replace the `completion-at-point' and `complete-symbol' bindings in
;; irony-mode's buffers by irony-mode's function
(defun my-irony-mode-hook ()
  (define-key irony-mode-map [remap completion-at-point]
    'irony-completion-at-point-async)
  (define-key irony-mode-map [remap complete-symbol]
    'irony-completion-at-point-async))
(add-hook 'irony-mode-hook 'my-irony-mode-hook)
(add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)
(eval-after-load 'company
  '(add-to-list 'company-backends 'company-irony))
;; (optional) adds CC special commands to `company-begin-commands' in order to
;; trigger completion at interesting places, such as after scope operator
;;     std::|
(add-hook 'irony-mode-hook 'company-irony-setup-begin-commands)
;; =============
;; flycheck-mode
;; =============
(add-hook 'c++-mode-hook 'flycheck-mode)
(add-hook 'c-mode-hook 'flycheck-mode)
(eval-after-load 'flycheck
  '(add-hook 'flycheck-mode-hook #'flycheck-irony-setup))
;; =============
;; eldoc-mode
;; =============
(add-hook 'irony-mode-hook 'irony-eldoc)

(setq irony-additional-clang-options
      '("-isystem" "/usr/local/Cellar/llvm/7.0.0/include/c++/v1"))
(setq irony-additional-clang-options
      (append '("-I" "/usr/local/Cellar/llvm/7.0.0/include/c++/v1") irony-additional-clang-options))
(setq irony-additional-clang-options
      (append '("-I" "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include") irony-additional-clang-options))
(setq irony-additional-clang-options
      (append '("-std=c++17") irony-additional-clang-options))

;; project specific includes
(setq irony-additional-clang-options
      (append '("-I" "/Users/jeremy/work/cpp/elk/") irony-additional-clang-options))

;; ==========================================
;; (optional) bind TAB for indent-or-complete
;; ==========================================
(defun irony--check-expansion ()
  (save-excursion
    (if (looking-at "\\_>") t
      (backward-char 1)
      (if (looking-at "\\.") t
        (backward-char 1)
        (if (looking-at "->") t nil)))))
(defun irony--indent-or-complete ()
  "Indent or Complete"
  (interactive)
  (cond ((and (not (use-region-p))
              (irony--check-expansion))
         (message "complete")
         (company-complete-common))
        (t
         (message "indent")
         (call-interactively 'c-indent-line-or-region))))
(defun irony-mode-keys ()
  "Modify keymaps used by `irony-mode'."
  (local-set-key (kbd "TAB") 'irony--indent-or-complete)
  (local-set-key [tab] 'irony--indent-or-complete))
(add-hook 'c-mode-common-hook 'irony-mode-keys)
