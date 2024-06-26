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
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
(setq  doom-font (font-spec :family "FiraCode Nerd Font Mono" :size 17 :weight 'semibold)
       ;;  doom-font (font-spec :family "SauceCodePro Nerd Font Mono" :size 15 :weight 'regular)
       ;; doom-font (font-spec :family "DejaVuSansMono Nerd Font Mono" :size 12 :weight 'regular)
       ;; doom-font (font-spec :family "Iosevka Nerd Font Mono" :size 12 :weight 'regular)
       ;; doom-variable-pitch-font (font-spec :family "Fira Sans")
       ;; doom-unicode-font (font-spec :family "FiraCode Nerd Font Mono" )
       ;; doom-big-font (font-spec :family "FiraCode Nerd Font Mono" :size 19)
       doom-themes-enable-bold t
       doom-themes-enable-italic t)
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one-light)
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
;; keychain environment
(use-package! keychain-environment
  :config
  (keychain-refresh-environment))
(when noninteractive
  (add-to-list 'doom-env-whitelist "^SSH_"))

(setenv "SSH_AUTH_SOCK" "/run/user/1000/gnupg/S.gpg-agent.ssh")

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

(setq org-latex-listings 'engraved
      org-latex-src-block-backend 'engraved
      org-latex-pdf-process '("latexmk -pdflatex='%latex -shell-escape -interaction nonstopmode' -pdf -output-directory=%o -f %f"))

;; Programming language
(setq highlight-indent-guides-mode t)
(after! lsp-haskell
  (setq ;;lsp-haskell-server-path "haskell-language-server"
   lsp-haskell-plugin-retire-global-on nil
   lsp-haskell-formatting-provider "stylish-haskell"
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
        lsp-ui-sideline-show-hover t
        lsp-ui-sideline-ignore-duplicate t
        lsp-ui-sideline-show-symbol t
        lsp-ui-sideline-show-code-actions t
        lsp-ui-sideline-show-diagnostics t
        lsp-ui-sideline-update-mode 'line

        lsp-ui-peek-enable t

        lsp-ui-doc-enable t
        ;;lsp-ui-doc-use-webkit nil
        lsp-ui-doc-enhanced-markdown nil
        ;;lsp-ui-doc-use-childframe t
        lsp-ui-doc-max-width 150
        lsp-ui-doc-max-height 15
        lsp-ui-doc-include-signature t
        lsp-ui-doc-show-with-cursor nil
        lsp-ui-doc-show-with-mouse t
        lsp-ui-doc-delay 1))

(map! :after lsp-mode
      :map lsp-mode-map
      "M-/" #'lsp-ui-doc-show
      "M-." #'lsp-ui-peek-find-implementation
      )

(add-hook! elixir-mode
  (add-hook 'before-save-hook 'lsp-format-buffer nil t))

;; Elixir lsp
;; (setq lsp-elixir-server-command '("/nix/store/7yxbq69ln8m9p89wynms70bmj7zg01y5-elixir-ls-0.14.6/bin/elixir-ls"))

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
