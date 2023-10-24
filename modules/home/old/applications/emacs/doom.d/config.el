;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "Thong Pham"
      user-mail-address "thongpv87@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))


(setq ;; doom-font (font-spec :family "FiraCode Nerd Font Mono" :size 12 :weight 'regular)
      ;;  doom-font (font-spec :family "SauceCodePro Nerd Font Mono" :size 15 :weight 'regular)
      doom-font (font-spec :family "DejaVuSansMono Nerd Font Mono" :size 15 :weight 'regular)
      doom-font (font-spec :family "Iosevka Nerd Font Mono" :size 15 :weight 'regular)
      ;; doom-variable-pitch-font (font-spec :family "Fira Sans")
      ;; doom-unicode-font (font-spec :family "FiraCode Nerd Font Mono" )
      ;; doom-big-font (font-spec :family "FiraCode Nerd Font Mono" :size 19)
      doom-themes-enable-bold t
      doom-themes-enable-italic t)

;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-gruvbox-light)
(setq doom-themes-treemacs-theme "doom-colors")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/Documents/org/")


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

;; input-method

;; (set-input-method "Agda")

;; keychain environment
(use-package! keychain-environment
  :config
  (keychain-refresh-environment))

(when noninteractive
  (add-to-list 'doom-env-whitelist "^SSH_"))

(setenv "SSH_AUTH_SOCK" "/run/user/1000/gnupg/S.gpg-agent.ssh")

;; email
(setq +mu4e-backend 'offlineimap
      mu4e-index-cleanup nil
      ;; because gmail uses labels as folders we can use lazy check since
      ;; messages don't really "move"
      mu4e-index-lazy-check t
      mu4e-drafts-folder "/[Gmail].Drafts"
      mu4e-sent-folder   "/[Gmail].Sent Mail"
      mu4e-trash-folder  "/[Gmail].Trash"
      )
(setq mu4e-maildir-shortcuts
    '( (:maildir "/INBOX"              :key ?i)
       (:maildir "/[Gmail].Sent Mail"  :key ?s)
       (:maildir "/[Gmail].Trash"      :key ?t)
       (:maildir "/[Gmail].All Mail"   :key ?a)))

(setq +mu4e-gmail-accounts '(("thongpv87@gmail.com" . "/thongpv87"))
      user-mail-address "thongpv87@gmail.com"
      user-full-name "Thong Pham"
      )

(use-package! smtpmail
  :config
  (setq send-mail-function    'smtpmail-send-it
        message-send-mail-function 'message-smtpmail-send-it
        smtpmail-smtp-server  "smtp.gmail.com"
        smtpmail-stream-type  'ssl
        smtpmail-smtp-service 465))

;; Configure desktop notifs for incoming emails:
(use-package! mu4e-alert
  :ensure t
  :init
  (defun perso--mu4e-notif ()
    "Display both mode line and desktop alerts for incoming new emails."
    (interactive)
    (mu4e-update-mail-and-index 1)        ; getting new emails is ran in the background
    (mu4e-alert-enable-mode-line-display) ; display new emails in mode-line
    (mu4e-alert-enable-notifications))    ; enable desktop notifications for new emails
  (defun perso--mu4e-refresh ()
    "Refresh emails every 300 seconds and display desktop alerts."
    (interactive)
    (mu4e t)                            ; start silently mu4e (mandatory for mu>=1.3.8)
    (run-with-timer 0 300 'perso--mu4e-notif))
  :after mu4e
  :bind ("<f2>" . perso--mu4e-refresh)  ; F2 turns Emacs into a mail client
  :config
  ;; Mode line alerts:
  (add-hook 'after-init-hook #'mu4e-alert-enable-mode-line-display)
  ;; Desktop alerts:
  (mu4e-alert-set-default-style 'libnotify)
  (add-hook 'after-init-hook #'mu4e-alert-enable-notifications)
  ;; Only notify for "interesting" (non-trashed) new emails:
  (setq mu4e-alert-interesting-mail-query
        (concat
         "flag:unread maildir:/INBOX"
         " AND NOT flag:trashed")))



;; org mode
 (setq org-latex-default-packages-alist
      '(("AUTO" "polyglossia" t ("xelatex" "lualatex"))
        ("AUTO" "babel" t ("pdflatex"))
        ("" "graphicx" t)
        ("" "longtable" nil)
        ("" "wrapfig" nil)
        ("" "rotating" nil)
        ("normalem" "ulem" t)
        ("" "amsmath" t)
        ("" "textcomp" t)
        ("" "amssymb" t)
        ("" "capt-of" nil)
        ("" "color" t)
        ("" "listings" t)
        ("dvipsnames" "xcolor" nil)
        ("colorlinks=true, linkcolor=Blue, citecolor=BrickRed, urlcolor=PineGreen" "hyperref" nil)
	("" "indentfirst" nil)))

;; (use-package! ox-latex
;;   (setq org-latex-listings 'engraved))



(setq org-latex-listings 'engraved
      org-latex-src-block-backend 'engraved
      org-latex-pdf-process '("latexmk -pdflatex='%latex -shell-escape -interaction nonstopmode' -pdf -output-directory=%o -f %f"))


;; Programming language
(setq highlight-indent-guides-mode t)
(after! lsp-haskell
  (setq ;;lsp-haskell-server-path "haskell-language-server"
        lsp-haskell-plugin-retire-global-on nil
        lsp-haskell-formatting-provider "fourmolu"
        lsp-haskell-plugin-tactics-global-on nil))

(after! lsp-mode
  (evil-define-key 'normal lsp-mode-map (kbd "`") lsp-command-map)
  (setq lsp-semantic-highlighting t
        lsp-completion-at-point t
        lsp-lens-enable nil
        lsp-enable-imenu t
        lsp-enable-indentation t
        lsp-enable-symbol-highlighting t
        lsp-enable-text-document-color nil
        lsp-headerline-breadcrumb-enable t
        lsp-signature-auto-activate t
        lsp-signature-doc-lines 8
        lsp-signature-render-documentation nil

        lsp-ui-sideline-enable t
        lsp-ui-sideline-show-hover nil
        lsp-ui-sideline-ignore-duplicate t
        lsp-ui-sideline-show-symbol t
        lsp-ui-sideline-show-code-actions t
        lsp-ui-sideline-show-diagnostics t
        lsp-ui-sideline-update-mode 'line

        lsp-ui-doc-enable nil
        ;;lsp-ui-doc-use-webkit nil
        lsp-ui-doc-enhanced-markdown nil
        ;;lsp-ui-doc-use-childframe t
        lsp-ui-doc-max-width 150
        lsp-ui-doc-max-height 15
        lsp-ui-doc-include-signature t
        lsp-ui-doc-show-with-cursor t
        lsp-ui-doc-show-with-mouse t
        lsp-ui-doc-delay 1))

(map! :after lsp-mode
      :map lsp-mode-map
      "M-/" #'lsp-ui-doc-show
      "M-." #'lsp-ui-peek-find-implementation
      )

(use-package! intero
  :hook
  (haskell-mode-hook . intero-mode))

;; Prevent open new workspace when start emacsclient
(after! persp-mode
  (setq persp-emacsclient-init-frame-behaviour-override "main"))
(setq doom-modeline-persp-name t)


;; TREEMACS
(setq winum-scope 'frame-local)
(map! "M-0" #'treemacs-select-window
      "M-1" #'winum-select-window-1
      "M-2" #'winum-select-window-2
      "M-3" #'winum-select-window-3
      "M-4" #'winum-select-window-4
      "M-5" #'winum-select-window-5
      "M-6" #'winum-select-window-6
      "M-7" #'winum-select-window-7
      "M-8" #'winum-select-window-8
      "M-9" #'winum-select-window-9)

;; OTHERS
(add-hook! treemacs-mode
           (treemacs-load-theme "all-the-icons"))

