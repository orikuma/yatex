;;; -*- Emacs-Lisp -*-
;;; Yet Another tex-mode for emacs.
;;; yatex.el rev. 1.52
;;; (c )1991-1994 by HIROSE Yuuji.[yuuji@ae.keio.ac.jp]
;;; Last modified Tue Oct 25 01:39:08 1994 on figaro
;;; $Id$

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

(require 'comment)
(defconst YaTeX-revision-number "1.52"
  "Revision number of running yatex.el"
)

;---------- Local variables ----------
;;;
;; Initialize local variable for yatex-mode.
;; Preserving user preferred definitions.
;; ** Check all of these defvar-ed values **
;; ** and setq other values more suitable **
;; ** for your site, if needed.           **
;;;
(defvar YaTeX-prefix "\C-c"
  "*Prefix key to trigger YaTeX functions.
You can select favorite prefix key by setq in your ~/.emacs."
)
(defvar YaTeX-open-lines 0
  "*Blank lines between text and \\begin{??}"
)
(defvar YaTeX-environment-indent 1
  "*Indentation depth at column width in LaTeX environments."
)
(defvar YaTeX-fill-prefix ""
  "*fill-prefix used for auto-fill-mode.
The default value is null string."
)
(defvar YaTeX-fill-column 72
  "*fill-column used for auto-fill-mode."
)
(defvar YaTeX-comment-prefix "%"
  "TeX comment prefix."
)
(defvar YaTeX-current-position-register ?3
  "*Position register to keep where the last completion was done.
All of YaTeX completing input store the current position into
the register YaTeX-current-position-register.  So every time you
make a trip to any other part of text than you are writing, you can
return to the editing paragraph by calling register-to-point with argument
YaTeX-current-position-register."
)
(defvar YaTeX-dos (eq system-type 'ms-dos))
(defvar YaTeX-emacs-19 (string= "19" (substring emacs-version 0 2)))
(defvar YaTeX-user-completion-table
  (if YaTeX-dos "~/_yatexrc" "~/.yatexrc")
  "*Default filename in which user completion table is saved."
)
;;(defvar YaTeX-tmp-dic-unit 'main-file
;;  "*Default switching unit of temporary dictionary.
;;There are two switching unit:
;;'main-file	: switch tmp-dic according to main-file directory.
;;'directory	: switch tmp-dic dir by dir."
;;)
(defvar YaTeX-japan (or (boundp 'NEMACS) (boundp 'MULE))
  "Whether yatex mode is running on Japanese environment or not."
)
(defvar tex-command (if YaTeX-japan "jlatex" "latex")
  "*Default command for typesetting LaTeX text."
)
(defvar bibtex-command (if YaTeX-japan "jbibtex" "bibtex")
  "*Default command of BibTeX."
)
(defvar dvi2-command		;previewer command for your site
  (if YaTeX-dos "dviout -wait-"
    (concat "xdvi -geo +0+0 -s 4 -display "
	    (or (getenv "DISPLAY") "unix:0")))
  "*Default previewer command including its option.
This default value is for X window system."
)
(defvar makeindex-command (if YaTeX-dos "makeind" "makeindex")
  "*Default makeindex command."
)
(defvar dviprint-command-format
  (if YaTeX-dos "dviprt %s %f%t"
      "dvi2ps %f %t %s | lpr")
  "*Command line string to print out current file.
Format string %s will be replaced by the filename.  Do not forget to
specify the `from usage' and `to usage' with their option by format string
%f and %t.
  See also documentation of dviprint-from-format and dviprint-to-format."
)
(defvar dviprint-from-format
  (if YaTeX-dos "%b-" "-f %b")
  "*`From' page format of dvi filter.  %b will turn to beginning page number."
)
(defvar dviprint-to-format
  (if YaTeX-dos "%e" "-t %e")
  "*`To' page format of dvi filter.  %e will turn to end page number."
)
(defvar YaTeX-default-document-style
  (concat (if YaTeX-japan "j") "article")
  "*Default LaTeX Documentstyle for YaTeX-typeset-region."
)
(defvar YaTeX-need-nonstop nil
  "*T for adding `\\nonstopmode{}' to text before invoking latex command."
)
(defvar latex-warning-regexp "line.* [0-9]*"
  "*Regular expression of line number of warning message by latex command."
)
(defvar latex-error-regexp "l\\.[1-9][0-9]*"
  "*Regular expression of line number of latex error.
Perhaps your latex command stops at this error message with line number of
LaTeX source text."
)
(defvar latex-dos-emergency-message
  "Emergency stop"      ;<- for Micro tex, ASCII-pTeX 1.6
  "Message pattern of emergency stop of typesetting.
Because Demacs (GNU Emacs on DOS) cannot have concurrent process, the
latex command which is stopping on a LaTeX error, is terminated by Demacs.
Many latex command on DOS display some messages when it is terminated by
other process, user or OS.  Define to this variable a message string of your
latex command on DOS shown at abnormal termination.
  Remember Demacs's call-process function is not oriented for interactive
process."
)
(defvar latex-message-kanji-code 2
  "*Kanji coding system latex command types out.
1 = Shift JIS, 2 = JIS, 3 = EUC."
)
(defvar YaTeX-inhibit-prefix-letter nil
  "*T for changing key definitions from [prefix] Letter to [prefix] C-Letter."
)
(defvar NTT-jTeX nil
  "*Use NTT-jTeX for latex command."
)
(defvar YaTeX-item-regexp (concat (regexp-quote "\\") "\\(sub\\)*item")
  "*R  egular expression of item command."
)
(defvar YaTeX-nervous t
  "*If you are nervous about maintenance of yatexrc, set this value to T.
And you will have the local dictionary."
)
(defvar YaTeX-sectioning-regexp
  "part\\|chapter\\|\\(sub\\)*\\(section\\|paragraph\\)"
  "*LaTeX sectioning commands regexp."
)
(defvar YaTeX-paragraph-delimiter
  (concat "^%\\|^$\\|^\C-l\\|^[ \t]*\\\\\\("
	  YaTeX-sectioning-regexp		;sectioning commands
	  "\\|[A-z]*item\\|begin{\\|end{"	;special declaration
	  "\\)")
  "*Paragraph delimiter regexp of common LaTeX source.  Use this value
for YaTeX-uncomment-paragraph."
)
(defvar YaTeX-fill-inhibit-environments '("verbatim" "tabular")
  "*In these environments, YaTeX inhibits fill-paragraph from formatting.
Define those environments as a form of list."
)
(defvar YaTeX-uncomment-once t
  "*T for removing all continuous commenting character(%).
Nil for removing only one commenting character at the beginning-of-line."
)
(defvar YaTeX-default-pop-window-height 10
  "Default typesetting buffer height.
If integer, sets the window-height of typesetting buffer.
If string, sets the percentage of it.
If nil, use default pop-to-buffer."
)
(defvar YaTeX-close-paren-always t
  "Close parenthesis always when YaTeX-modify-mode is nil."
)
(defvar YaTeX-no-begend-shortcut nil
  "*T for disabling shortcut of begin-type completion, [prefix] b d, etc."
)
(defvar YaTeX-greek-by-maketitle-completion nil
  "*T for greek letters completion by maketitle-type completion."
)
(defvar YaTeX-auto-math-mode t
  "*T for changing YaTeX-math mode automatically.")
(defvar yatex-mode-hook nil
  "*List of functions to be called at the end of yatex-mode initializations."
)

;;-- Math mode values --

(defvar YaTeX-math-key-list-default
  '((";" . YaTeX-math-sign-alist)
    ("/" . YaTeX-greek-key-alist))
  "Default key sequence to invoke math-mode's image completion."
)
(defvar YaTeX-math-key-list-private nil
  "*User defined alist, math-mode-prefix vs completion alist"
)
(defvar YaTeX-math-key-list
  (append YaTeX-math-key-list-private YaTeX-math-key-list-default)
  "Key sequence to invoke math-mode's image completion."
)


;------------ Completion table ------------
; Set tex-section-like command possible completion
(defvar section-table
  '(("part" 0) ("chapter" 0) ("section" 0) ("subsection" 0)
    ("subsubsection" 0) ("paragraph" 0) ("subparagraph" 0)
    ("author") ("thanks") ("documentstyle") ("pagestyle")
    ("title" 0) ("underline" 0) ("label" 0) ("makebox" 0)
    ("footnote" 0) ("footnotetext" 0)
    ("hspace*") ("vspace*") ("bibliography") ("bibitem[]") ("cite[]")
    ("input") ("include") ("includeonly") ("mbox") ("hbox") ("caption" 0)
    ("newlength") ("setlength" 2) ("addtolength" 2) ("settowidth" 2)
    ("setcounter" 2) ("addtocounter" 2) ("stepcounter" 2)
    ("newcommand" 2) ("renewcommand" 2)
    ("setcounter" 2) ("newenvironment" 3) ("newtheorem" 2)
    ("cline") ("framebox") ("savebox") ("date") ("put") ("ref" 0)
    ("frac" 2) ("multicolumn" 3) ("shortstack")
    )
  "Default completion table for section-type completion."
)
(defvar user-section-table nil)
(defvar tmp-section-table nil)

; Set style possible completion
(defvar article-table
  '(("article") ("jarticle") ("report") ("jreport") ("jbook")
    ("4em") ("2ex")
    ("\\textwidth")
    ("\\oddsidemargin") ("\\evensidemargin")
    ("\\rightmargin") ("\\leftmargin")
    ("\\textheight") ("\\topmargin")
    ("\\bottommargin") ("\\footskip") ("\\footheight")
    ("\\baselineskip") ("\\baselinestretch") ("normalbaselineskip")
    )
  "Default completion table for arguments of section-type completion."
)
(defvar user-article-table nil)

; Set tex-environment possible completion
(defvar env-table
  '(("quote") ("quotation") ("center") ("verse") ("document")
    ("verbatim") ("itemize") ("enumerate") ("description")
    ("list") ("tabular") ("table") ("tabbing") ("titlepage")
    ("sloppypar") ("quotation") ("picture") ("displaymath")
    ("eqnarray") ("figure") ("equation") ("abstract") ("array")
    ("thebibliography") ("theindex") ("flushleft") ("flushright")
    ("minipage")
    )
  "Default completion table for begin-type completion."
)
(defvar user-env-table nil)
(defvar tmp-env-table nil)

; Set {\Large }-like completion
(defvar fontsize-table
  '(("rm") ("em") ("bf") ("boldmath") ("it") ("sl") ("sf") ("sc") ("tt")
    ("dg") ("dm")
    ("tiny") ("scriptsize") ("footnotesize") ("small")("normalsize")
    ("large") ("Large") ("LARGE") ("huge") ("Huge")
    )
  "Default completion table for large-type completion."
)
(defvar user-fontsize-table nil)
(defvar tmp-fontsize-table nil)

(defvar singlecmd-table
  '(("maketitle") ("sloppy") ("protect")
    ("LaTeX") ("TeX") ("item") ("item[]") ("appendix") ("hline")
    ("rightarrow") ("Rightarrow") ("leftarrow") ("Leftarrow")
    ("pagebreak") ("newpage") ("clearpage") ("cleardoublepage")
    ("footnotemark") ("verb") ("verb*")
    ("left") ("right")
    )
  "Default completion table for maketitle-type completion."
)
(if YaTeX-greek-by-maketitle-completion
    (setq singlecmd-table
	  (cons '(("alpha") ("beta") ("gamma") ("delta") ("epsilon")
		  ("varepsilon") ("zeta") ("eta") ("theta")("vartheta")
		  ("iota") ("kappa") ("lambda") ("mu") ("nu") ("xi") ("pi")
		  ("varpi") ("rho") ("varrho") ("sigma") ("varsigma") ("tau")
		  ("upsilon") ("phi") ("varphi") ("chi") ("psi") ("omega")
		  ("Gamma") ("Delta") ("Theta") ("Lambda")("Xi") ("Pi")
		  ("Sigma") ("Upsilon") ("Phi") ("Psi") ("Omega"))
		singlecmd-table))
)
(defvar user-singlecmd-table nil)
(defvar tmp-singlecmd-table nil)

;---------- Key mode map ----------
;;;
;; Create new key map: YaTeX-mode-map
;; Do not change this section.
;;;
(defvar YaTeX-mode-map nil
  "Keymap used in YaTeX mode."
)
(defvar YaTeX-typesetting-mode-map nil
  "Keymap used in YaTeX typesetting buffer."
)
(defvar YaTeX-prefix-map nil
  "Keymap used when YaTeX-prefix key pushed."
)
(defvar YaTeX-current-completion-type nil
  "Has current completion type.  This may be used in YaTeX addin functions."
)
(defvar YaTeX-modify-mode nil
  "*T for normal key assignment of opening parentheses, nil for entering
both open/close parentheses when opening parentheses key pressed."
)
(defvar YaTeX-math-mode nil
  "Holds whether current mode is math-mode."
)
;---------- Define default key bindings on YaTeX mode map ----------
(defun YaTeX-define-key (key binding)
  "Define key on YaTeX-prefix-map"
  (if YaTeX-inhibit-prefix-letter
      (let ((c (aref key 0)))
	(cond
	 ((and (>= c ?a) (<= c ?z)) (aset key 0 (1+ (- c ?a))))
	 ((and (>= c ?A) (<= c ?Z) (numberp YaTeX-inhibit-prefix-letter))
	  (aset key 0 (1+ (- c ?A))))
	 (t nil))))
  (define-key YaTeX-prefix-map key binding)
)
(defun YaTeX-define-begend-key-normal (key env)
  "Define short cut YaTeX-make-begin-end key."
  (YaTeX-define-key
   key
   (list 'lambda '(arg) '(interactive "P")
	 (list 'YaTeX-insert-begin-end env 'arg)))
)
(defun YaTeX-define-begend-region-key (key env)
  "Define short cut YaTeX-make-begin-end-region key."
  (YaTeX-define-key key (list 'lambda nil '(interactive)
			      (list 'YaTeX-insert-begin-end env t)))
)
(defun YaTeX-define-begend-key (key env)
  "Define short cut key for begin type completion both for normal
and region mode.  To customize YaTeX, user should use this function."
  (YaTeX-define-begend-key-normal key env)
  (if YaTeX-inhibit-prefix-letter nil
    (YaTeX-define-begend-region-key
     (concat (upcase (substring key 0 1)) (substring key 1)) env))
)
;;;
;; Define key table
;;;
(if YaTeX-mode-map 
    nil
  (setq YaTeX-mode-map (make-sparse-keymap))
  (setq YaTeX-prefix-map (make-sparse-keymap))
  (define-key YaTeX-mode-map "\"" 'YaTeX-insert-quote)
  (define-key YaTeX-mode-map "{" 'YaTeX-insert-braces)
  (define-key YaTeX-mode-map "(" 'YaTeX-insert-parens)
  (define-key YaTeX-mode-map "$" 'YaTeX-insert-dollar)
  (define-key YaTeX-mode-map "[" 'YaTeX-insert-brackets)
  (define-key YaTeX-mode-map YaTeX-prefix YaTeX-prefix-map)
  (define-key YaTeX-mode-map "\M-\C-@" 'YaTeX-mark-environment)
  (define-key YaTeX-mode-map "\M-\C-a" 'YaTeX-beginning-of-environment)
  (define-key YaTeX-mode-map "\M-\C-e" 'YaTeX-end-of-environment)
  (define-key YaTeX-mode-map "\M-\C-m" 'YaTeX-intelligent-newline)
  (define-key YaTeX-mode-map "\C-i" 'YaTeX-indent-line)
  (YaTeX-define-key "%" 'YaTeX-%-menu)
  (YaTeX-define-key "t" 'YaTeX-typeset-menu)
  (YaTeX-define-key "w" 'YaTeX-switch-mode-menu)
  (YaTeX-define-key "'" 'YaTeX-prev-error)
  (YaTeX-define-key "^" 'YaTeX-visit-main)
  (YaTeX-define-key "4^" 'YaTeX-visit-main-other-window)
  (YaTeX-define-key " " 'YaTeX-do-completion)
  (YaTeX-define-key "v" 'YaTeX-version)

  (YaTeX-define-key "}" 'YaTeX-insert-braces-region)
  (YaTeX-define-key "]" 'YaTeX-insert-brackets-region)
  (YaTeX-define-key ")" 'YaTeX-insert-parens-region)
  (YaTeX-define-key "$" 'YaTeX-insert-dollars-region)
  (YaTeX-define-key "i" 'YaTeX-fill-item)
  (YaTeX-define-key
   "\\" '(lambda () (interactive) (insert "$\\backslash$")))
  (if YaTeX-no-begend-shortcut
      (progn
	(YaTeX-define-key "B" 'YaTeX-make-begin-end-region)
	(YaTeX-define-key "b" 'YaTeX-make-begin-end))
    (YaTeX-define-begend-key "bc" "center")
    (YaTeX-define-begend-key "bd" "document")
    (YaTeX-define-begend-key "bD" "description")
    (YaTeX-define-begend-key "be" "enumerate")
    (YaTeX-define-begend-key "bE" "equation")
    (YaTeX-define-begend-key "bi" "itemize")
    (YaTeX-define-begend-key "bl" "flushleft")
    (YaTeX-define-begend-key "bm" "minipage")
    (YaTeX-define-begend-key "bt" "tabbing")
    (YaTeX-define-begend-key "bT" "tabular")
    (YaTeX-define-begend-key "b\^t" "table")
    (YaTeX-define-begend-key "bp" "picture")
    (YaTeX-define-begend-key "bq" "quote")
    (YaTeX-define-begend-key "bQ" "quotation")
    (YaTeX-define-begend-key "br" "flushright")
    (YaTeX-define-begend-key "bv" "verbatim")
    (YaTeX-define-begend-key "bV" "verse")
    (YaTeX-define-key "B " 'YaTeX-make-begin-end-region)
    (YaTeX-define-key "b " 'YaTeX-make-begin-end))
  (YaTeX-define-key "e" 'YaTeX-end-environment)
  (YaTeX-define-key "S" 'YaTeX-make-section-region)
  (YaTeX-define-key "s" 'YaTeX-make-section)
  (YaTeX-define-key "L" 'YaTeX-make-fontsize-region)
  (YaTeX-define-key "l" 'YaTeX-make-fontsize)
  (YaTeX-define-key "m" 'YaTeX-make-singlecmd)
  (YaTeX-define-key "." 'YaTeX-comment-paragraph)
  (YaTeX-define-key "," 'YaTeX-uncomment-paragraph)
  (YaTeX-define-key ">" 'YaTeX-comment-region)
  (YaTeX-define-key "<" 'YaTeX-uncomment-region)
  (YaTeX-define-key "g" 'YaTeX-goto-corresponding-*)
  (YaTeX-define-key "k" 'YaTeX-kill-*)
  (YaTeX-define-key "c" 'YaTeX-change-*)
  (YaTeX-define-key "a" 'YaTeX-make-accent)
  (YaTeX-define-key "?" 'YaTeX-help)
  (YaTeX-define-key "/" 'YaTeX-apropos)
  (YaTeX-define-key "&" 'YaTeX-what-column)
  (YaTeX-define-key "n"
    '(lambda () (interactive) (insert "\\\\")))
  (if YaTeX-dos
      (define-key YaTeX-prefix-map "\C-r"
	'(lambda () (interactive)
	   (set-screen-height YaTeX-saved-screen-height) (recenter))))
  (mapcar
   (function
    (lambda (key)
      (define-key YaTeX-mode-map (car key) 'YaTeX-math-insert-sequence)))
   YaTeX-math-key-list)
)

(if YaTeX-typesetting-mode-map nil
  (setq YaTeX-typesetting-mode-map (make-keymap))
  ;(suppress-keymap YaTeX-typesetting-mode-map t)
  (define-key YaTeX-typesetting-mode-map " " 'YaTeX-jump-error-line)
  (define-key YaTeX-typesetting-mode-map "\C-m" 'YaTeX-send-string)
)

(defvar YaTeX-minibuffer-completion-map nil
  "*Key map used at YaTeX completion in the minibuffer.")
(if YaTeX-minibuffer-completion-map nil
  (setq YaTeX-minibuffer-completion-map
	(copy-keymap (or (and (boundp 'gmhist-completion-map)
			      gmhist-completion-map)
			 minibuffer-local-completion-map)))
  (define-key YaTeX-minibuffer-completion-map
    " " 'YaTeX-minibuffer-complete)
  (define-key YaTeX-minibuffer-completion-map
    "\C-i" 'YaTeX-minibuffer-complete)
  (define-key YaTeX-minibuffer-completion-map
    "\C-v" 'YaTeX-read-section-with-overview))

(defvar YaTeX-recursive-map nil
  "*Key map used at YaTeX reading arguments in the minibuffer.")
(if YaTeX-recursive-map nil
  (setq YaTeX-recursive-map (copy-keymap global-map))
  (define-key YaTeX-recursive-map YaTeX-prefix YaTeX-prefix-map))

;;    (define-key YaTeX-recursive-map
;;      (concat YaTeX-prefix (if YaTeX-inhibit-prefix-letter "\C-s" "s"))
;;      'YaTeX-make-section)
;;    (define-key map
;;      (concat YaTeX-prefix (if YaTeX-inhibit-prefix-letter "\C-m" "m"))
;;      'YaTeX-make-singlecmd)
;;    (define-key map
;;      (concat YaTeX-prefix (if YaTeX-inhibit-prefix-letter "\C-l" "l"))
;;      'YaTeX-make-fontsize)


;---------- Define other variable ----------
(defvar env-name "document" "*Initial tex-environment completion")
(defvar section-name "documentstyle" "*Initial tex-section completion")
(defvar fontsize-name "large" "*Initial fontsize completion")
(defvar single-command "maketitle" "*Initial LaTeX single command")
(defvar YaTeX-user-table-has-read nil
  "Flag that means whether user completion table has been read or not."
)
(defvar YaTeX-user-table-modified nil
  "Flag that means whether user completion table has been modified or not."
)
(defvar YaTeX-kanji-code-alist nil
  "Kanji-code expression translation table."
)
(if (boundp 'MULE)
    (setq YaTeX-kanji-code-alist
	  (list (cons
		 1
		 (if YaTeX-dos (if (boundp '*sjis-dos*) *sjis-dos* *sjis*dos)
		   *sjis*))
		'(2 . *junet*) '(3 . *euc-japan*))
))
(defvar YaTeX-kanji-code (if YaTeX-dos 1 2)
  "*File kanji code used by Japanese TeX."
)
(defvar YaTeX-coding-system nil "File coding system used by Japanese TeX.")
(defvar YaTeX-latex-message-code "Process coding system for LaTeX.")
(cond
 ((boundp 'MULE)
  (setq YaTeX-coding-system
	(symbol-value (cdr (assoc YaTeX-kanji-code YaTeX-kanji-code-alist))))
  (if (not YaTeX-dos)
      (setq YaTeX-latex-message-code *autoconv*)))
 ((boundp 'NEMACS)
  (setq YaTeX-latex-message-code latex-message-kanji-code))
)
(defvar YaTeX-parent-file nil
  "*Main LaTeX source file name used when %#! expression doesn't exist.")
;---------- Provide YaTeX-mode ----------
;;;
;; Major mode definition
;;;
(defun yatex-mode ()
  "  Yet Another LaTeX mode: Major mode for editing input files of LaTeX.
-You can invoke processes concerning LaTeX typesetting by
 		\\[YaTeX-typeset-menu]
-Complete LaTeX environment form of `\\begin{env} ... \\end{env}' by
		\\[YaTeX-make-begin-end]
-Enclose region into some environment by
		\\[universal-argument] \\[YaTeX-make-begin-end]
-Complete LaTeX command which takes argument like `\\section{}' by
		\\[YaTeX-make-section]
-Put LaTeX command which takes no arguments like `\\maketitle' by
		\\[YaTeX-make-singlecmd]
-Complete font or character size descriptor like `{\\large }' by
		\\[YaTeX-make-fontsize]
-Enclose region into those descriptors above by
		\\[universal-argument] \\[YaTeX-make-fontsize]
-Enter European accent notation by
		\\[YaTeX-make-accent]
-Toggle various modes of YaTeX by
		\\[YaTeX-switch-mode-menu]
-Change environt name (on the begin/end line) by
		\\[YaTeX-change-*]
-Kill LaTeX command/environment sequences by
		\\[YaTeX-kill-*]
-Kill LaTeX command/environment with its contents 
		\\[universal-argument] \\[YaTeX-kill-*]
-Go to corresponding object (begin/end, file, labels) by
		\\[YaTeX-goto-corresponding-*]
-Go to main LaTeX source text by
		\\[YaTeX-visit-main]
-Comment out or uncomment region by
		\\[YaTeX-comment-region]  or  \\[YaTeX-uncomment-region]
-Comment out or uncomment paragraph by
		\\[YaTeX-comment-paragraph]  or  \\[YaTeX-uncomment-paragraph]
-Make an \\item entry hang-indented by
		\\[YaTeX-fill-item]
-Enclose the region with parentheses by
		\\[YaTeX-insert-parens-region]
		\\[YaTeX-insert-braces-region]
		\\[YaTeX-insert-brackets-region]
		\\[YaTeX-insert-dollars-region]
-Look up the corresponding column header of tabular environment by
		\\[YaTeX-what-column]
-Refer the online help of popular LaTeX commands by
		\\[YaTeX-help]		(help)
		\\[YaTeX-apropos]		(apropos)
-Edit `%# notation' by
		\\[YaTeX-%-menu]

  Those are enough for fastening your editing of LaTeX source.  But further
more features are available and they are documented in the manual.
"
  (interactive)
  (kill-all-local-variables)
  (setq major-mode 'yatex-mode)
  (setq mode-name (if YaTeX-japan "やてふ" "YaTeX"))
  (mapcar 'make-local-variable
	  '(dvi2-command YaTeX-parent-file fill-column fill-prefix
	    tmp-env-table tmp-section-table tmp-fontsize-table
	    tmp-singlecmd-table YaTeX-math-mode ;;indent-line-function
	    ))
  (cond ((boundp 'MULE)
	 (set-file-coding-system  YaTeX-coding-system))
  	((boundp 'NEMACS)
	 (make-local-variable 'kanji-fileio-code)
	 (setq kanji-fileio-code YaTeX-kanji-code)))
  (setq fill-column YaTeX-fill-column
	fill-prefix YaTeX-fill-prefix
	paragraph-start    YaTeX-paragraph-delimiter
	paragraph-separate YaTeX-paragraph-delimiter
	;;indent-line-function 'YaTeX-indent-line
	)
  (use-local-map YaTeX-mode-map)
  (if YaTeX-dos (setq YaTeX-saved-screen-height (screen-height)))
  (YaTeX-read-user-completion-table)
  (run-hooks 'text-mode-hook 'yatex-mode-hook)
)

;---------- Define YaTeX-mode functions ----------
(defvar YaTeX-ec "\\" "Escape character of current mark-up language.")
(defvar YaTeX-ec-regexp (regexp-quote YaTeX-ec))
(defvar YaTeX-struct-begin
  (concat YaTeX-ec "begin{%1}%2")
  "Keyword to begin environment.")
(defvar YaTeX-struct-end (concat YaTeX-ec "end{%1}")
  "Keyword to end environment.")
(defvar YaTeX-struct-name-regexp "[^}]+"
  "Environment name regexp.")
(defvar YaTeX-TeX-token-regexp
  (cond (YaTeX-japan "[A-Za-z*あ-ん亜-龠]+")
	(t "[A-Za-z*]+"))
  "Regexp of characters which can be a member of TeX command's name.")
(defvar YaTeX-command-token-regexp YaTeX-TeX-token-regexp
  "Regexp of characters which can be a member of current mark up
language's command name.")
;;(defvar YaTeX-struct-section
;;  (concat YaTeX-ec "%1{%2}")
;;  "Keyword to make section.")

;;;
;; autoload section
;;;
;;autoload from yatexlib(general).
(autoload 'YaTeX-showup-buffer "yatexlib" "YaTeX library" t)
(autoload 'YaTeX-window-list "yatexlib" "YaTeX library" t)
(autoload 'YaTeX-search-active-forward "yatexlib" "YaTeX library" t)
(autoload 'YaTeX-search-active-backward "yatexlib" "YaTeX library" t)
(autoload 'substitute-all-key-definition "yatexlib" "YaTeX library" t)
(autoload 'YaTeX-switch-to-buffer "yatexlib" "YaTeX library" t)
(autoload 'YaTeX-switch-to-buffer-other-window "yatexlib" "YaTeX library" t)
(autoload 'YaTeX-replace-format "yatexlib" "YaTeX library" t)
(autoload 'YaTeX-replace-format-args "yatexlib" "YaTeX library" t)
(autoload 'rindex "yatexlib" "YaTeX library" t)
(autoload 'YaTeX-match-string "yatexlib" "YaTeX library" t)
(autoload 'YaTeX-minibuffer-complete "yatexlib" "YaTeX library" t)

;;autoload from yatexprc.el
(autoload 'YaTeX-visit-main "yatexprc" "Visit main LaTeX file." t)
(autoload 'YaTeX-visit-main-other-window "yatexprc"
	  "Visit main other window." t)

;;autoload from yatexmth.el
(autoload 'YaTeX-math-insert-sequence "yatexmth" "Image input." t)
(autoload 'YaTeX-in-math-mode-p "yatexmth" "Check if in math-env." t)
(autoload 'YaTeX-toggle-math-mode "yatexmth" "YaTeX math-mode interfaces." t)

;;autoload from yatexhlp.el
(autoload 'YaTeX-help "yatexhlp" "YaTeX helper with LaTeX commands." t)
(autoload 'YaTeX-apropos "yatexhlp" "Apropos for (La)TeX commands." t)

;;autoload from yatexgen.el
(autoload 'YaTeX-generate "yatexgen" "YaTeX add-in function generator." t)
(autoload 'YaTeX-generate-simple "yatexgen" "YaTeX add-in support." t)

;;autoload from yatexsec.el
(autoload 'YaTeX-read-section-in-minibuffer "yatexsec" "YaTeX sectioning" t)
(autoload 'YaTeX-make-section-with-overview "yatexsec" "YaTeX sectioning" t)

;;autoload from yatexenv.el
(autoload 'YaTeX-what-column "yatexenv" "YaTeX env. specific funcs" t)
(autoload 'YaTeX-intelligent-newline "yatexenv" "YaTeX env. specific funcs" t)

;;;
;; YaTeX-mode functions
;;;
(defun YaTeX-insert-begin-end (env region-mode)
  "Insert \\begin{mode-name} and \\end{mode-name}.
This works also for other defined begin/end tokens to define the structure."
  (setq YaTeX-current-completion-type 'begin)
  (let*((ccol (current-column)) beg exchange
	(arg region-mode)		;for old compatibility
	(indent-column (+ ccol YaTeX-environment-indent))(i 1))
    (if (and region-mode (> (point) (mark)))
	(progn (exchange-point-and-mark)
	       (setq exchange t
		     ccol (current-column)
		     indent-column (+ ccol YaTeX-environment-indent))))
    ;;VER2 (insert "\\begin{" env "}" (YaTeX-addin env))
    (setq beg (point))
    (YaTeX-insert-struc 'begin env)
    (insert "\n")
    (indent-to indent-column)
    (save-excursion
      ;;indent optional argument of \begin{env}, if any
      (while (> (point-beginning-of-line) beg)
	(skip-chars-forward "\\s " (point-end-of-line))
	(indent-to indent-column)
	(forward-line -1)))
    (if region-mode
	  ;;if region-mode, indent all text in the region
	(save-excursion
	  (while (< (progn (forward-line 1) (point)) (mark))
	    (if (eolp) nil
	      (skip-chars-forward " \t\n")
	      (indent-to indent-column))))
      ;;if not region-mode, open line.
      (while (<= i (1+ (* 2 YaTeX-open-lines)))
	(indent-to indent-column)
	(insert "\n")
	(setq i (1+ i))))
    (if region-mode (exchange-point-and-mark))
    (indent-to ccol)
    ;;VER2 (insert "\\end{" env "}\n")
    (YaTeX-insert-struc 'end env)
    (if region-mode
	(progn
	  (if (not (eolp)) (insert "\n"))
	  (or exchange (exchange-point-and-mark)))
      (previous-line (+ 1 YaTeX-open-lines)))
    (if YaTeX-current-position-register
	(point-to-register YaTeX-current-position-register)))
)


(defun YaTeX-make-begin-end (arg)
  "Make LaTeX environment command of \\begin{env.} ... \\end{env.}
by completing read.
 If you invoke this command with universal argument,
\(key binding for universal-argument is \\[universal-argument]\)
you can put REGION into that environment between \\begin and \\end."
  (interactive "P")
  (let*
      ((mode (if arg " region" ""))
       (env
	(YaTeX-read-environment
	 (format "Begin environment%s(default %s): " mode env-name))))
    (if (string= env "")
	(setq env env-name))
    (setq env-name env)
    (YaTeX-update-table
     (list env-name) 'env-table 'user-env-table 'tmp-env-table)
    (YaTeX-insert-begin-end env-name arg))
)

(defun YaTeX-make-begin-end-region ()
  "Call YaTeX-make-begin-end with ARG to specify region mode."
  (interactive)
  (YaTeX-make-begin-end t)
)



(defun YaTeX-inner-environment (&optional quick)
  "Return current inner-most environment.
Non-nil for optional argument QUICK restricts search bound to most
recent sectioning command."
  (let ((nest 0)
	(begend (concat "\\("
			(YaTeX-replace-format-args
			 (regexp-quote YaTeX-struct-begin)
			 YaTeX-command-token-regexp "" "")
			"\\)\\|\\("
			(YaTeX-replace-format-args
			 (regexp-quote YaTeX-struct-end)
			 YaTeX-command-token-regexp "" "")
			"\\)"))
	bound)
    (save-excursion
      (if quick
	  (setq bound
		(save-excursion
		  (YaTeX-re-search-active-backward
		   (concat YaTeX-sectioning-regexp "\\*?\\{")
		   YaTeX-comment-prefix nil 1)
		  (point-end-of-line))))
      (if (catch 'begin
	    (while (YaTeX-re-search-active-backward
		    begend YaTeX-comment-prefix bound t)
	      (if (match-beginning 2)
		  (setq nest (1+ nest))
		(setq nest (1- nest)))
	      ;;(message "N=%d" nest) (sit-for 1)
	      (if (< nest 0) (throw 'begin t))))
	  (buffer-substring
	   (progn (skip-chars-forward "^{") (1+ (point)))
	   (progn (skip-chars-forward "^}") (point))))))
)

(defun YaTeX-end-environment ()
  "Close opening environment"
  (interactive)
  (let ((curp (point))
	(env (YaTeX-inner-environment))
	(md (match-data)))

    (if (not env) (error "No premature environment")
      (save-excursion
	(if (YaTeX-search-active-forward
	     (YaTeX-replace-format-args YaTeX-struct-end env "" "")
	     YaTeX-comment-prefix nil t)
	    (if (y-or-n-p
		 (concat "Environment `" env
			 "' may be already closed. Force close?"))
		nil
	      (error "end environment aborted."))))
      (message "")			;Erase (y or n) message.
      ;(insert "\\end{" env "}")
      (YaTeX-insert-struc 'end env)
      (store-match-data md)
      (setq curp (point))
      (goto-char (match-end 0))
      (if (pos-visible-in-window-p)
	  (sit-for (if YaTeX-dos 2 1))
	(message "Matches with %s at line %d"
		 (YaTeX-replace-format-args YaTeX-struct-begin env "" "")
		 (count-lines (point-min) (point))))
      (goto-char curp))
    )
)

;;;VER2
(defun YaTeX-insert-struc (what env)
  (cond
   ((eq what 'begin)
    (insert (YaTeX-replace-format-args
	     YaTeX-struct-begin env (YaTeX-addin env))))
   ((eq what 'end)
    (insert (YaTeX-replace-format-args YaTeX-struct-end env)))
   (t nil))
)

(defun YaTeX-make-section (arg &optional beg end cmd)
  "Make LaTeX \\section{} type command with completing read.
With numeric ARG, you can specify the number of arguments of
LaTeX command.
  For example, if you want to produce LaTeX command

	\\addtolength{\\topmargin}{8mm}

which has two arguments.  You can produce that sequence by typing...
	ESC 2 C-c s add SPC RET \\topm SPC RET 8mm RET
\(by default\)
Then yatex will automatically complete `addtolength' with two arguments
next time.
  You can complete symbol at LaTeX command and the 1st argument.

If the optional 2nd and 3rd argument BEG END are specified, enclose
the region from BEG to END into the first argument of the LaTeX sequence.
Optional 4th arg CMD is LaTeX command name, for non-interactive use."
  (interactive "P")
  (setq YaTeX-current-completion-type 'section)
  (unwind-protect
      (let*
	  ((source-window (selected-window))
	   (section
	    (or cmd
		(YaTeX-read-section
		 (if (> (minibuffer-depth) 0)
		     (format "%s???{} (default %s)%s: " YaTeX-ec section-name
			     (format "[level:%d]" (minibuffer-depth)))
		   (format "(C-v for view) %s???{} (default %s): "
			   YaTeX-ec section-name))
		 nil)))
	   (section (if (string= section "") section-name section))
	   (numarg	;; The number of section-type command's argument
	    (or arg
		(nth 1 (assoc section
			      (append tmp-section-table user-section-table
				      section-table)))
		1))
	   (arg-reader (intern-soft (concat "YaTeX::" section)))
	   (addin-args (and arg-reader (fboundp arg-reader)))
	   (title "")
	   (j 2)
	   (enable-recursive-minibuffers t));;let
	(setq section-name section)
	(if beg
	    (let ((e (make-marker)))
	      (goto-char end)
	      (insert "}")
	      (set-marker e (point))
	      (goto-char beg)
	      (insert YaTeX-ec section-name "{")
	      (goto-char (marker-position e)))
	  (use-global-map YaTeX-recursive-map)
	  (setq title
		(concat
		 (YaTeX-addin section)
		 "{"
		 (cond
		  (addin-args (funcall arg-reader 1))
		  ((equal numarg 0) ;;chapter, section, subsection, etc...
		   (read-string (concat YaTeX-ec section "{???}: ")))
		  (t
		   (completing-read
		    (concat YaTeX-ec section "{???}: ")
		    (append user-article-table article-table)
		    nil nil)))
		 "}"))
	  (insert YaTeX-ec section title))
	(while (<= j numarg)
	  (insert
	   "{"
	   (setq title
		 (if addin-args
		     (funcall arg-reader j)
		   (read-string (format "Argument %d: " j))))
	   "}")
	  (setq j (1+ j)))
	(YaTeX-update-table
	 (if (/= numarg 1) (list section numarg)
	   (list section))
	 'section-table 'user-section-table 'tmp-section-table)
	(if YaTeX-current-position-register
	    (point-to-register YaTeX-current-position-register))
	(if (string= (buffer-substring (- (point) 2) (point)) "{}")
	    (forward-char -1)))
    (if (<= (minibuffer-depth) 0) (use-global-map global-map)))
)

(defun YaTeX-make-section-region (args beg end)
  "Call YaTeX-make-section with arguments to specify region mode."
 (interactive "P\nr")
 (YaTeX-make-section args beg end)
)

(defun YaTeX-make-fontsize (arg)
  "Make completion like {\\large ...} or {\\slant ...} in minibuffer.
If you invoke this command with universal argument, you can put region
into {\\xxx } braces.
\(key binding for universal-argument is \\[universal-argument]\)"
  (interactive "P")
  (YaTeX-sync-tmp-table 'tmp-fontsize-table)
  (let* ((mode (if arg "region" ""))
	 (fontsize
	  (YaTeX-read-fontsize
	   (format "{\\??? %s} (default %s)%s: " mode fontsize-name
		   (if (> (minibuffer-depth) 0)
		       (format "[level:%d]" (minibuffer-depth)) ""))
	   nil nil)))
    (if (string= fontsize "")
	(setq fontsize fontsize-name))
    (setq fontsize-name fontsize)
    (YaTeX-update-table
     (list fontsize-name)
     'fontsize-table 'user-fontsize-table 'tmp-fontsize-table)
    (if arg
	(save-excursion
	  (if (> (point) (mark)) (exchange-point-and-mark))
	  (insert "{\\" fontsize-name " ")
	  (exchange-point-and-mark)
	  (insert "}"))
      (insert "{\\" fontsize-name " }")
      (if YaTeX-current-position-register
	  (point-to-register YaTeX-current-position-register))
      (forward-char -1)))
)

(defun YaTeX-make-fontsize-region ()
  "Call function:YaTeX-make-fontsize with ARG to specify region mode."
  (interactive)
  (YaTeX-make-fontsize t)
)

(defun YaTeX-make-singlecmd (single)
  (interactive
   (list (completing-read
	  (format "%s??? (default %s)%s: " YaTeX-ec single-command
		  (if (> (minibuffer-depth) 0)
		      (format "[level:%d]" (minibuffer-depth)) ""))
	  (progn
	    (YaTeX-sync-tmp-table 'tmp-singlecmd-table)
	    (append tmp-singlecmd-table user-singlecmd-table singlecmd-table))
	  nil nil )))
  (if (string= single "")
      (setq single single-command))
  (setq single-command single)
  (YaTeX-update-table
   (list single-command)
   'singlecmd-table 'user-singlecmd-table 'tmp-singlecmd-table)
  (setq YaTeX-current-completion-type 'maketitle)
  (insert YaTeX-ec single-command (YaTeX-addin single) " ")
  (if YaTeX-current-position-register
      (point-to-register YaTeX-current-position-register))
)

(defvar YaTeX-completion-begin-regexp "[{\\]"
  "Regular expression of limit where LaTeX command's
completion begins.")

(defun YaTeX-do-completion ()
  "Try completion on LaTeX command preceding point."
  (interactive)
  (if
      (or (eq (preceding-char) ? )
	  (eq (preceding-char) ?\t)
	  (eq (preceding-char) ?\n)
	  (bobp))
      (message "Nothing to complete.")   ;Do not complete
    (let* ((end (point))
	   (limit (point-beginning-of-line))
	   (completion-begin 
	    (progn (re-search-backward "[ \t\n]" limit 1) (point)))
	   (begin (progn
		    (goto-char end)
		    (if (re-search-backward YaTeX-completion-begin-regexp
					    completion-begin t)
			(1+ (point))
		      nil))))
      (goto-char end)
      (cond
       ((null begin)
	(message "I think it is not a LaTeX sequence."))
       (t
	(mapcar 'YaTeX-sync-tmp-table
		'(tmp-section-table tmp-env-table tmp-singlecmd-table))
	(let*((pattern (buffer-substring begin end))
	      (all-table
	       (append
		section-table user-section-table tmp-section-table
		article-table user-article-table
		env-table     user-env-table     tmp-env-table
		singlecmd-table user-singlecmd-table tmp-singlecmd-table))
	      ;; First,
	      ;; search completion without backslash.
	      (completion (try-completion pattern all-table)))
	  (if
	      (eq completion nil)
	      ;; Next,
	      ;; search completion with backslash
	      (setq completion
		    (try-completion (buffer-substring (1- begin) end)
				    all-table nil)
		    begin (1- begin)))
	  (cond
	   ((null completion)
	    (message (concat "Can't find completion for '" pattern "'"))
	    (ding))
	   ((eq completion t) (message "Sole completion."))
	   ((not (string= completion pattern))
	    (kill-region begin end)
	    (insert completion)
	    )
	   (t
	    (message "Making completion list...")
	    (with-output-to-temp-buffer "*Help*"
	      (display-completion-list
	       (all-completions pattern all-table))))))))))
)

(defun YaTeX-toggle-modify-mode (&optional arg)
  (interactive "P")
  (or (memq 'YaTeX-modify-mode mode-line-format)
      (setq mode-line-format
	    (append (list "" 'YaTeX-modify-mode) mode-line-format)))
  (if (or arg (null YaTeX-modify-mode))
      (progn
	(setq YaTeX-modify-mode "*m*")
	(message "Modify mode"))
    (setq YaTeX-modify-mode nil)
    (message "Cancel modify mode."))
  (set-buffer-modified-p (buffer-modified-p))	;redraw mode-line
)

(defun YaTeX-switch-mode-menu (arg &optional char)
  (interactive "P")
  (message "Toggle: (M)odify-mode ma(T)h-mode")
  (let ((c (or char (read-char))))
    (cond
     ((= c ?m) (YaTeX-toggle-modify-mode arg))
     ((or (= c ?$) (= c ?t))
      (if YaTeX-auto-math-mode
	  (message "Makes no sense in YaTeX-auto-math-mode.")
	(YaTeX-toggle-math-mode arg)))))
)

(defun YaTeX-insert-quote ()
  (interactive)
  (insert
   (cond
    ((YaTeX-quick-in-environment-p "verbatim") ?\")
    ((= (preceding-char) ?\\ ) ?\")
    ((= (preceding-char) ?\( ) ?\")
    ((or (= (preceding-char) 32)
	 (= (preceding-char) 9)
	 (= (preceding-char) ?\n)
	 (bobp)
	 (string-match
	  (char-to-string (preceding-char)) "、。，．？！」』】"))
     "``")
    (t  "''")))
)

(defun YaTeX-closable-p ()
  (and (not YaTeX-modify-mode)
       (or YaTeX-close-paren-always (eolp))
       (not (input-pending-p))
       (not (YaTeX-quick-in-environment-p "verbatim")))
  ;;(or YaTeX-modify-mode
  ;;    (and (not YaTeX-close-paren-always) (not (eolp)))
  ;;    (input-pending-p)
  ;;    (YaTeX-quick-in-environment-p "verbatim"))
)

(defun YaTeX-insert-braces-region (beg end &optional open close)
  (interactive "r")
  (save-excursion
    (goto-char end)
    (insert (or close "}"))
    (goto-char beg)
    (insert (or open "{")))
)

(defun YaTeX-insert-braces (&optional open close)
  (interactive)
  (let (env)
    (cond
     ((YaTeX-jmode) (YaTeX-self-insert nil))
     ((not (YaTeX-closable-p)) nil)
     ((and (> (point) (+ (point-min) 5))
	   (save-excursion (backward-char 5) (looking-at "\\\\end"))
	   (not (YaTeX-in-verb-p (point)))
	   (not (YaTeX-quick-in-environment-p "verbatim"))
	   (setq env (YaTeX-inner-environment)))
      (momentary-string-display
       (concat
	(cond
	 (YaTeX-japan
	  (format "今度からはちゃんと %s b を使いましょう" YaTeX-prefix))
	 (t (format "You don't understand Zen of `%c b':p" YaTeX-prefix)))
	"}")
       (point))
      (insert (or open "{") env (or close "}")))
     (t
      (insert (or open "{") (or close "}"))
      (forward-char -1))))
)

(defun YaTeX-jmode ()
  (or (and (boundp 'canna:*japanese-mode*) canna:*japanese-mode*)
      (and (boundp 'egg:*mode-on*) egg:*mode-on*))
)
(defun YaTeX-self-insert (arg)
  (funcall
   (or (and (fboundp 'canna-self-insert-command)
	    'canna-self-insert-command)
       (and (fboundp 'egg-self-insert-command)
	    'egg-self-insert-command)
       'self-insert-command)
   arg)
)
(defun YaTeX-insert-brackets (arg)
  "Insert Kagi-kakko or \\ [ \\] pair or simply \[."
  (interactive "p")
  (let ((col (1- (current-column))))
    (cond
     ((YaTeX-jmode) (YaTeX-self-insert arg))
     ((not (YaTeX-closable-p))
      (YaTeX-self-insert arg))
     ((and (= (preceding-char) ?\\ )
	   (/= (char-after (- (point) 2)) ?\\ )
	   (not (YaTeX-in-math-mode-p)))
      (insert last-command-char "\n")
      (indent-to (max 0 col))
      (insert "\\]")
      (beginning-of-line)
      (open-line 1)
      (kill-line 0)
      (indent-to (+ YaTeX-environment-indent (max 0 col)))
      (YaTeX-toggle-math-mode 1))
     ((YaTeX-closable-p)
      (insert "[]")
      (backward-char 1))
     (t (YaTeX-self-insert arg)))
    )
)

(defun YaTeX-insert-brackets-region (beg end)
  (interactive "r")
  (YaTeX-insert-braces-region beg end "[" "]")
)

(defun YaTeX-insert-parens (arg)
  "Insert parenthesis pair."
  (interactive "p")
  (cond
   ((YaTeX-jmode) (YaTeX-self-insert arg))
   ((not (YaTeX-closable-p)) (YaTeX-self-insert arg))
   ((and (= (preceding-char) ?\\ ) (not (YaTeX-in-math-mode-p)))
    (insert "(\\)")
    (backward-char 2))
   ((YaTeX-closable-p)
    (insert "()")
    (backward-char 1))
   (t (YaTeX-self-insert arg)))
)

(defun YaTeX-insert-parens-region (beg end)
  (interactive "r")
  (YaTeX-insert-braces-region beg end "(" ")")
)

(defun YaTeX-insert-dollar ()
  (interactive)
  (if (or (not (YaTeX-closable-p))
	  (= (preceding-char) 92))
      (insert "$")
    (insert "$$")
    (forward-char -1)
    (YaTeX-toggle-math-mode 1))
)

(defun YaTeX-insert-dollars-region (beg end)
  (interactive "r")
  (YaTeX-insert-braces-region beg end "$" "$")
)

(defun YaTeX-version ()
  "Return string of the version of running YaTeX."
  (interactive)
  (message
   (concat "Yet Another tex-mode "
	   (if YaTeX-japan "「野鳥」" "Wild Bird")
	   " Revision "
	   YaTeX-revision-number))
)

(defun YaTeX-typeset-menu (arg &optional char)
  "Typeset, preview, visit error and miscellaneous convenient menu.
Optional second argument CHAR is for non-interactive call from menu."
  (interactive "P")
  (message
   (concat "J)latex R)egion B)ibtex make(I)ndex "
	   (if (not YaTeX-dos) "K)ill-latex ")
	   "P)review V)iewerror L)pr M)ode"))
  (let ((sw (selected-window)) (c (or char (read-char))))
    (require 'yatexprc)			;for Nemacs's bug
    (select-window sw)
    (cond
     ((= c ?j) (YaTeX-typeset-buffer))
     ((= c ?r) (YaTeX-typeset-region))
     ((= c ?b) (YaTeX-call-command-on-file
		bibtex-command "*YaTeX-bibtex*"))
     ((= c ?i) (YaTeX-call-command-on-file
		makeindex-command "*YaTeX-makeindex*"))
     ((= c ?k) (YaTeX-kill-typeset-process YaTeX-typeset-process))
     ((= c ?p) (call-interactively 'YaTeX-preview))
     ((= c ?q) (YaTeX-system "lpq" "*Printer queue*"))
     ((= c ?v) (YaTeX-view-error))
     ((= c ?l) (YaTeX-lpr arg))
     ((= c ?m) (YaTeX-switch-mode-menu arg))
     ((= c ?b) (YaTeX-insert-string "\\"))))
)

(defun YaTeX-%-menu (&optional beg end char)
  "Operate %# notation."
  ;;Do not use interactive"r" for the functions which require no mark
  (interactive)
  (message "!)Edit-%%#! B)EGIN-END-region L)Edit-%%#LPR")
  (let ((c (or char (read-char))) (string "") key
	(b (make-marker)) (e (make-marker)))
    (save-excursion
      (cond
       ((or (= c ?!) (= c ?l))		;Edit `%#!'
	(goto-char (point-min))
	(setq key (cond ((= c ?!) "%#!")
			((= c ?l) "%#LPR")))
	(if (re-search-forward key nil t)
	    (progn
	      (setq string (buffer-substring (point) (point-end-of-line)))
	      (kill-line))
	  (open-line 1)
	  (kill-line 0)			;for Emacs-19 :-<
	  (insert key))
	(unwind-protect
	    (setq string (read-string (concat key ": ") string))
	  (insert string)))

       ((= c ?b)			;%#BEGIN %#END region
	(or end (setq beg (min (point) (mark)) end (max (point) (mark))))
	(set-marker b beg)
	(set-marker e end)
	(goto-char (point-min))
	(while (re-search-forward "^%#\\(BEGIN\\)\\|\\(END\\)$" nil t)
	  (beginning-of-line) (kill-line 1))
	(goto-char (marker-position b))
	(open-line 1)
	(kill-line 0)			;for Emacs-19 :-<
	(insert "%#BEGIN")
	(goto-char (marker-position e))
	(insert "%#END\n"))
       )))
)

(defun YaTeX-goto-corresponding-label (reverse)
  "Jump to corresponding \\label{} or \\ref{}.  The default search
direction depends on the command at the cursor position.  When the
cursor is on \\ref, YaTeX will try to search the corresponding \\label
backward, and if it fails search forward again.  And when the cursor is
on \\label, YaTeX will search the corresponding \\ref forward at first
and secondary backward.  Argument REVERSE non-nil makes the default
direction rule reverse.  Since Search string is automatically set to
search-last-string, you can repeat search the same label/ref by typing
\\[isearch-forward] or \\[isearch-backward]."

  (let (label (scmd "ref") direc (p (point)))
    (cond
     ((or (YaTeX-on-section-command-p "label") (not (setq scmd "label"))
	  (YaTeX-on-section-command-p "ref"))
      (goto-char (match-end 0))
      (let ((label (buffer-substring 
		    (1- (point)) (progn (backward-list 1) (1+ (point))))))
	(setq search-last-string (concat "\\" scmd "{" label "}"))
	(setq direc (if( equal scmd "ref") 'search-forward 'search-backward))
	(if reverse (setq direc (if (eq direc 'search-forward)
				    'search-backward 'search-forward)))
	(if (or
	     (funcall direc search-last-string nil t)
	     (funcall (if (eq direc 'search-forward)
			  'search-backward 'search-forward)
		      search-last-string))
	    (progn
	      (goto-char (match-beginning 0))
	      (set-mark p) (message "mark set")))
	))
     (t nil)))
)

(defun YaTeX-goto-corresponding-environment ()
  "Go to corresponding begin/end enclosure."
  (interactive)
  (if (not (YaTeX-on-begin-end-p)) nil
    (let (b0 b1 (p  (match-end 0)) env (nest 0) regexp re-s (op (point))
	  (m0 (match-beginning 0))	;whole matching
	  (m1 (match-beginning 1))	;environment in \begin{}
	  (m2 (match-beginning 2)))	;environment in \end{}
      ;(setq env (regexp-quote (buffer-substring p (match-beginning 0))))
      (if (cond
	   (m1				;if begin{xxx}
	    (setq env (buffer-substring m1 (match-end 1)))
	;    (setq regexp (concat "\\(\\\\end{" env "}\\)\\|"
	;			 "\\(\\\\begin{" env "}\\)"))
	    (setq regexp
		  (concat
		   "\\("
		   (regexp-quote
		    (YaTeX-replace-format-args YaTeX-struct-end env "" ""))
		   "\\)\\|\\("
		   (regexp-quote
		    (YaTeX-replace-format-args YaTeX-struct-begin env "" ""))
		   "\\)"))
	    (setq re-s 're-search-forward))
	   (m2				;if end{xxx}
	    (setq env (buffer-substring m2 (match-end 2)))
	;   (setq regexp (concat "\\(\\\\begin{" env "}\\)\\|"
	;			 "\\(\\\\end{" env "}\\)"))
	    (setq regexp
		  (concat
		   "\\("
		   (regexp-quote
		    (YaTeX-replace-format-args YaTeX-struct-begin env "" ""))
		   "\\)\\|\\("
		   (regexp-quote
		    (YaTeX-replace-format-args YaTeX-struct-end env "" ""))
		   "\\)"))
	    (setq re-s 're-search-backward))
	   ((error "Corresponding environment not found.")))
	  (progn
	    (while (and (>= nest 0) (funcall re-s regexp nil t))
	      (setq b0 (match-beginning 0) b1 (match-beginning 1))
	      (if (or (equal b0 m0)
		      (YaTeX-quick-in-environment-p "verbatim"))
		  nil
		(setq nest (if (equal b0 b1)
			       (1- nest) (1+ nest)))))
	    (if (< nest 0) nil		;found.
	      (goto-char op)
	      (error "Corresponding environment `%s' not found." env)))
	)
      (beginning-of-line));let
    t); if on begin/end line
)

(defun YaTeX-goto-corresponding-file ()
  "Visit or switch buffer of corresponding file, looking at \\input or
\\include or \includeonly on current line."
  (if (not (YaTeX-on-includes-p)) nil
    (let (input-file)
      (save-excursion
	(if (search-forward "{" (point-end-of-line) t)
	    nil
	  (skip-chars-backward "^,{"))
	(setq input-file
	      (buffer-substring
	       (point) (progn (skip-chars-forward "^ ,}") (point))))
	(if (not (string-match "\\.\\(tex\\|sty\\)$" input-file))
	    (setq input-file (concat input-file ".tex"))))
      (if (get-buffer-window input-file)
	  (select-window (get-buffer-window input-file))
	(YaTeX-switch-to-buffer input-file))))
)

(defun YaTeX-goto-corresponding-BEGIN-END ()
  (if (not (YaTeX-on-BEGIN-END-p)) nil
    (if (cond
	 ((equal (match-beginning 0) (match-beginning 1)) ;if on %#BEGIN
	  (not (search-forward "%#END" nil t)))
	 (t ; if on %#END
	  (not (search-backward "%#BEGIN" nil t))))
	(error "Corresponding %%#BEGIN/END not found."))
    (beginning-of-line)
    t)
)

(defun YaTeX-on-section-command-p (command)
  "Check if point is on the LaTeX command: COMMAND."
  (let ((p (point)))
    (save-excursion
      (or (looking-at YaTeX-ec-regexp)
	  (progn
	    (skip-chars-backward
	     (concat "^" YaTeX-ec-regexp) (point-beginning-of-line))
	    (backward-char 1)))
      (and (looking-at (concat YaTeX-ec-regexp command "[ \t\n\r]*{[^}]+}"))
	   (< p (match-end 0)))))
)

(defun YaTeX-on-begin-end-p ()
  (save-excursion
    (beginning-of-line)
    (re-search-forward
     ;;"\\\\begin{\\([^}]+\\)}\\|\\\\end{\\([^}]+\\)}"
     (concat
      (YaTeX-replace-format-args
       (regexp-quote YaTeX-struct-begin)
       (concat "\\(" YaTeX-struct-name-regexp "\\)") "" "" "")
      "\\|"
      (YaTeX-replace-format-args
       (regexp-quote YaTeX-struct-end)
       (concat "\\(" YaTeX-struct-name-regexp "\\)") "" "" ""))
     (point-end-of-line) t))
)

(defun YaTeX-on-includes-p ()
  (save-excursion
    (beginning-of-line)
    (re-search-forward "\\(\\(include.*\\)\\|\\(input\\)\\){.*}"
		       (point-end-of-line) t))
)

(defun YaTeX-on-comment-p (&optional sw)
  "Return t if current line is commented out.
Optional argument SW t to treat all `%' lines as comment,
even if on `%#' notation."
  (save-excursion
    (beginning-of-line)
    (skip-chars-forward "\\s ")
    (looking-at (if sw "%" "%[^#]")))
)

(defun YaTeX-on-BEGIN-END-p ()
  (save-excursion
    (let ((case-fold-search nil))
      (beginning-of-line)
      (re-search-forward "\\(%#BEGIN\\)\\|\\(%#END\\)" (point-end-of-line) t)))
)

(defun YaTeX-goto-corresponding-* (arg)
  "Parse current line and call suitable function."
  (interactive "P")
  (cond
   ((YaTeX-goto-corresponding-label arg))
   ((YaTeX-goto-corresponding-environment))
   ((YaTeX-goto-corresponding-file))
   ((YaTeX-goto-corresponding-BEGIN-END))
   (t (message "I don't know where to go.")))
)

(defun YaTeX-comment-region (alt-prefix)
  "Comment out region by '%'.
If you call this function on the 'begin{}' or 'end{}' line,
it comments out whole environment"
  (interactive "P")
  (if (not (YaTeX-on-begin-end-p))
      (comment-region
       (if alt-prefix
	   (read-string "Insert prefix: ")
	 YaTeX-comment-prefix))
    (YaTeX-comment-uncomment-env 'comment-region))
)

(defun YaTeX-uncomment-region (alt-prefix)
  "Uncomment out region by '%'."
  (interactive "P")
  (if (not (YaTeX-on-begin-end-p))
      (uncomment-region
       (if alt-prefix (read-string "Remove prefix: ")
	 YaTeX-comment-prefix)
       YaTeX-uncomment-once)
    (YaTeX-comment-uncomment-env 'uncomment-region))
)

(defun YaTeX-comment-uncomment-env (func)
  "Comment or uncomment out one LaTeX environment switching function by FUNC."
  (save-excursion
    (if (match-beginning 2) 			; if on the '\end{}' line
	(YaTeX-goto-corresponding-environment)) ; goto '\begin{}' line
    (beginning-of-line)
    (set-mark-command nil)
    (YaTeX-goto-corresponding-environment)
    (forward-line 1)
    (funcall func YaTeX-comment-prefix YaTeX-uncomment-once))
  (message "%sommented out current environment."
	   (if (eq func 'comment-region) "C" "Un-c"))
)

(defun YaTeX-end-of-environment (&optional limit-search-bound)
  "Goto the end of the current environment.
Optional argument LIMIT-SEARCH-BOUND non-nil limits the search bound
to most recent sectioning command."
  (interactive)
  (let ((in-env (YaTeX-inner-environment limit-search-bound)) (op (point)))
    (if in-env
	(if (re-search-forward
	     (concat
	      "^[ \t]*"
	      (YaTeX-replace-format-args
	       (regexp-quote YaTeX-struct-end)
	       (concat "\\(" (regexp-quote in-env) "\\)") "" "" ""))
	     nil t)
	    (progn
	      (if (interactive-p) (push-mark op))
	      t))
      (message "No further environment on the outside.")
      nil))
)

(defun YaTeX-beginning-of-environment (&optional limit-search-bound)
  "Goto the beginning of the current environment.
Optional argument LIMIT-SEARCH-BOUND non-nil limits the search bound to
most recent sectioning command."
  (interactive)
  (let ((op (point)))
    (if (YaTeX-end-of-environment limit-search-bound)
	(progn
	  (YaTeX-goto-corresponding-environment)
	  (if (interactive-p) (push-mark op))
	  t)))
)

(defun YaTeX-mark-environment ()
  "Mark current position and move point to end of environment."
  (interactive)
  (let ((curp (point)))
    (if (and (YaTeX-on-begin-end-p) (match-beginning 1)) ;if on \\begin
	(forward-line 1)
      (beginning-of-line))
    (if (not (YaTeX-end-of-environment))   ;arg1 turns to match-beginning 1
	(progn
	  (goto-char curp)
	  (error "Cannot found the end of current environment."))
      (YaTeX-goto-corresponding-environment)
      (beginning-of-line)		;for confirmation
      (if (< curp (point))
	  (progn
	    (message "Mark this environment?(y or n): ")
	    (if (= (read-char) ?y) nil
	      (goto-char curp)
	      (error "Abort.  Please call again at more proper position."))))
      (set-mark-command nil)
      (YaTeX-goto-corresponding-environment)
      (end-of-line)
      (if (eobp) nil (forward-char 1))))
)


(defun YaTeX-comment-paragraph ()
  "Comment out current paragraph."
  (interactive)
  (save-excursion
    (cond
     ((YaTeX-on-begin-end-p)
      (beginning-of-line)
      (insert YaTeX-comment-prefix)
      (YaTeX-goto-corresponding-environment)
      (beginning-of-line)
      (insert YaTeX-comment-prefix))
     ((YaTeX-on-comment-p)
      (message "Already commented out."))
     (t
      (mark-paragraph)
      (if (looking-at paragraph-separate) (forward-line 1))
      (comment-region "%"))))
)

(defun YaTeX-uncomment-paragraph ()
  "Uncomment current paragraph."
  (interactive)
  (save-excursion
    (if (YaTeX-on-begin-end-p)
	(let ((p (make-marker)))
	  (set-marker p (point))
	  (YaTeX-goto-corresponding-environment)
	  (YaTeX-remove-prefix YaTeX-comment-prefix YaTeX-uncomment-once)
	  (goto-char (marker-position p))
	  (YaTeX-remove-prefix YaTeX-comment-prefix YaTeX-uncomment-once))
      (if (YaTeX-on-comment-p)
	  (let*((fill-prefix "")
		;;append `^%' to head of paragraph delimiter.
		(paragraph-start
		 (concat
		  "^$\\|^%\\(" YaTeX-paragraph-delimiter "\\)"))
		(paragraph-separate paragraph-start)
		)
	    ;;(recursive-edit)
	    (mark-paragraph)
	    (if (not (bobp)) (forward-line 1))
	    (uncomment-region "%" YaTeX-uncomment-once))
	(message "This line is not a comment line."))))
)

(defun YaTeX-remove-prefix (prefix &optional once)
  "Remove prefix on current line as far as prefix detected. But
optional argument ONCE makes deletion once."
  (interactive "sPrefix:")
  (beginning-of-line)
  (while (re-search-forward (concat "^" prefix) (point-end-of-line) t)
    (replace-match "")
    (if once (end-of-line)))
)

(defun YaTeX-kill-option-string ()
  (if (and (eq predicate 'YaTeX-on-begin-end-p)
	   (looking-at "\\(\\[.*\\]\\)*\\({.*}\\)*"))
      (delete-region (match-beginning 0) (match-end 0)))  
)

(defun YaTeX-kill-some-pairs (predicate gofunc kill-contents)
  "Kill some matching pair.
This function assumes that pairs occupy each line where they resid."
  ;;(interactive)
  (if (not (funcall predicate)) nil
    (let ((beg (make-marker)) (end (make-marker)) (p (make-marker)))
      (set-marker end (match-end 0))
      (if (match-beginning 2)
	  (set-marker beg (match-beginning 2))
	(set-marker beg (match-beginning 1))
	(goto-char (match-end 0))
	(YaTeX-kill-option-string))
      (save-excursion
	(funcall gofunc)
	(delete-region (point-beginning-of-line) (match-end 0))
	(YaTeX-kill-option-string)
	(if (eolp) (delete-char 1))
	(set-marker p (point))
	(goto-char beg)
	(delete-region (point-beginning-of-line) end)
	(if (eolp) (delete-char 1))
	(if kill-contents (delete-region p (point))))
      t))
)

(defun YaTeX-kill-section-command (point kill-all)
  "Kill section-type command at POINT leaving its argument.
Non-nil for the second argument kill its argument too."
  (let (beg (end (make-marker)))
    (save-excursion
      (goto-char point)
      (or (looking-at YaTeX-ec-regexp)
	  (progn
	    (skip-chars-backward (concat "^" YaTeX-ec-regexp))
	    (forward-char -1)))
      (setq beg (point))
      (skip-chars-forward "^{")
      (forward-list 1)
      (set-marker end (point))
      (if kill-all (delete-region beg end)
	(goto-char beg)
	(delete-region
	 (point) (progn (skip-chars-forward "^{" end) (1+ (point))))
	(goto-char end)
	(backward-delete-char 1))))
)

(defun YaTeX-kill-paren (kill-contents)
  "Kill parentheses leaving its contents.
But kill its contents if the argument KILL-CONTENTS is non-nil."
  (save-excursion
    (let (p)
      (if (looking-at "\\s(\\|\\(\\s)\\)")
	  (progn
	    (if (match-beginning 1)
		(up-list -1))
	    (setq p (point))
	    (forward-list 1)
	    (if kill-contents (delete-region p (point))
	      (backward-delete-char 1)
	      (goto-char p)
	      (if (looking-at
		   (concat "{" YaTeX-ec-regexp
			   YaTeX-command-token-regexp "+"
			   "\\s +"))
		  (delete-region
		   (point)
		   (progn (re-search-forward "\\s +" nil t) (point)))
		(delete-char 1)))
	    t))))
)

(defvar YaTeX-read-environment-history nil "Holds history of environments.")
(put 'YaTeX-read-environment-history 'no-default t)
(defun YaTeX-read-environment (prompt &optional predicate must-match initial)
  "Read a LaTeX environment name with completion."
  (YaTeX-sync-tmp-table 'tmp-env-table)
  (let ((minibuffer-history-symbol 'YaTeX-read-environment-history))
    (completing-read
     prompt (append tmp-env-table user-env-table env-table)
     predicate must-match initial))
)

(defvar YaTeX-read-section-history nil "Holds history of section-types.")
(put 'YaTeX-read-section-history 'no-default t)
(defun YaTeX-read-section (prompt &optional predicate initial)
  "Read a LaTeX section-type command with completion."
  (YaTeX-sync-tmp-table 'tmp-section-table)
  (let ((minibuffer-history-symbol 'YaTeX-read-section-history)
	(minibuffer-completion-table
	 (append tmp-section-table user-section-table section-table)))
    (read-from-minibuffer
     prompt initial YaTeX-minibuffer-completion-map))
)

(defun YaTeX-read-section-with-overview ()
  "Read sectioning command with overview.
This function refers a local variable `source-window' in YaTeX-make-section"
  (interactive)
  (if (> (minibuffer-depth) 1)
      (error "Too many minibuffer levels for overview."))
  (let ((sw (selected-window))(enable-recursive-minibuffers t) sect)
    (unwind-protect
	(progn
	  (select-window source-window)
	  (setq sect (YaTeX-read-section-in-minibuffer
		      "Sectioning(Up=C-p, Down=C-n, Help=?): "
		      YaTeX-sectioning-level (YaTeX-section-overview))))
      (select-window sw))
    (if (eq (selected-window) (minibuffer-window))
	(erase-buffer))
    (insert sect)
    (exit-minibuffer)
    )
)

(defun YaTeX-read-fontsize (prompt &optional predicate must-match initial)
  "Read a LaTeX font changing command with completion."
  (YaTeX-sync-tmp-table 'tmp-fontsize-table)
  (completing-read
   prompt (append tmp-fontsize-table user-fontsize-table fontsize-table)
   predicate must-match initial)
)

(defun YaTeX-change-environment ()
  "Change the name of environment."
  (interactive)
  (if (not (YaTeX-on-begin-end-p)) nil
    (save-excursion
      (let (p env (m1 (match-beginning 1)) (m2 (match-beginning 2)))
	(setq env (if m1 (buffer-substring m1 (match-end 1))
		    (buffer-substring m2 (match-end 2))))
	(goto-char (match-beginning 0))
	(set-mark-command nil)
	(YaTeX-goto-corresponding-environment)
	(setq newenv (YaTeX-read-environment
		      (format "Change environment `%s' to: " env)))
	(cond
	 ((string= newenv "")	(message "Change environment cancelled."))
	 ((string= newenv env)	(message "No need to change."))
	 (t
	  (search-forward (concat "{" env) (point-end-of-line) t)
	  (replace-match (concat "{" newenv))
	  (exchange-point-and-mark)
	  (search-forward (concat "{" env) (point-end-of-line) t)
	  (replace-match (concat "{" newenv))))
	t)))
)

(defun YaTeX-change-section ()
  "Change section-type command."
  (interactive)
  (if (not (YaTeX-on-section-command-p YaTeX-command-token-regexp)) nil
    (let ((p (point))(beg (1+ (match-beginning 0))) end new)
      (save-excursion
	(goto-char beg) ;beginning of the command
	(setq new (YaTeX-read-section
		   (format "Change `%s' to: "
			   (buffer-substring
			    beg
			    (progn (skip-chars-forward "^{")
				   (setq end (point)))))
		   nil))
	(delete-region beg end)
	(insert-before-markers new)
	(goto-char p))
      t))
)

(defun YaTeX-kill-* (&optional arg)
  "Parse current line and call suitable function.
Non-nil for ARG kills its contents too."
  (interactive "P")
  (cond
   ((YaTeX-kill-some-pairs 'YaTeX-on-begin-end-p
			   'YaTeX-goto-corresponding-environment arg))
   ((YaTeX-kill-some-pairs 'YaTeX-on-BEGIN-END-p
			   'YaTeX-goto-corresponding-BEGIN-END arg))
   ((YaTeX-on-section-command-p YaTeX-command-token-regexp);on any command
    (YaTeX-kill-section-command (match-beginning 0) arg))
   ((YaTeX-kill-paren arg))
   (t (message "I don't know what to kill.")))
)

(defun YaTeX-change-* ()
  "Parse current line and call suitable function."
  (interactive)
  (cond
   ((YaTeX-change-environment))
   ((YaTeX-change-section))
   ;;((YaTeX-change-fontsize))
   (t (message "I don't know what to change.")))
)

;;;
;Check availability of addin functions
;;;
(cond
 ((featurep 'yatexadd) nil)	;Already provided.
 ((load "yatexadd" t) nil)	;yatexadd is in load-path
 (t (message "YaTeX add-in functions not supplied.")))

(defun YaTeX-addin (name)
  "Check availability of addin function and call it if exists."
  (if (and (not (get 'YaTeX-generate 'disabled))
	   (intern-soft (concat "YaTeX:" name))
	   (fboundp (intern-soft (concat "YaTeX:" name))))
      (let ((s (funcall (intern (concat "YaTeX:" name)))))
	(if (stringp s) s ""))
    "") ;Add in function is not bound.
)

(defun YaTeX-on-item-p (&optional point)
  "Return t if POINT (default is (point)) is on \\item."
  (let ((p (or point (point))))
    (save-excursion
      (goto-char p)
      (end-of-line)
      (setq p (point))
      (re-search-backward YaTeX-paragraph-delimiter nil t)
      (re-search-forward YaTeX-item-regexp p t)))
)

(defun YaTeX-in-verb-p (point)
  (save-excursion
    (if (not (re-search-backward "\\\\verb\\([^-A-Za-z_]\\)"
				 (point-beginning-of-line) t))
	nil
      (goto-char (match-end 1))
      (skip-chars-forward
       (concat "^" (buffer-substring (match-beginning 1) (match-end 1))))
      (and (< (match-beginning 1) point) (< point (point)))))
)

(defun YaTeX-in-environment-p (env)
  "Return if current LaTeX environment is ENV.
ENV is given in the form of environment's name or its list."
  (let ((md (match-data)) (nest 0) p envrx)
    (cond
     ((atom env)
      (setq envrx
	    (concat "\\("
		    (regexp-quote
		     (YaTeX-replace-format-args
		      YaTeX-struct-begin env "" ""))
		    "\\)\\|\\("
		    (regexp-quote
		     (YaTeX-replace-format-args
		      YaTeX-struct-end env "" ""))
		    "\\)"))
      (save-excursion
	(setq p (catch 'open
		  (while (YaTeX-re-search-active-backward
			  envrx YaTeX-comment-prefix nil t)
		    (if (match-beginning 2)
			(setq nest (1+ nest))
		      (setq nest (1- nest)))
		    (if (< nest 0) (throw 'open t)))))))
     ((listp env)
      (while (and env (not p))
	(setq p (YaTeX-in-environment-p (car env)))
	(setq env (cdr env)))))
    (store-match-data md)
    (if p p (YaTeX-in-verb-p (match-beginning 0))))
)

(defun YaTeX-quick-in-environment-p (env)
  "Check quickly but unsure if current environment is ENV.
ENV is given in the form of environment's name or its list.
This function returns currect result only if ENV is NOT nested."
  (save-excursion
    (let ((md (match-data)) (p (point)) q clfound rc)
      (cond
       ((listp env)
	(while (and env (not q))
	  (setq q (YaTeX-quick-in-environment-p (car env)))
	  (setq env (cdr env)))
	q)
       (t
	(if (YaTeX-search-active-backward
	     (YaTeX-replace-format-args YaTeX-struct-begin env "" "")
	     YaTeX-comment-prefix nil t)
	    (setq q (not (YaTeX-search-active-forward
			  (YaTeX-replace-format-args
			   YaTeX-struct-end env)
			  YaTeX-comment-prefix p t))))
	(goto-char p)
	(setq rc (if q q (YaTeX-in-verb-p (match-beginning 0))))
	(store-match-data md)
	rc))))
)

;; Filling \item
(defun YaTeX-remove-trailing-comment (start end)
  "Remove trailing comment from START to end."
  (save-excursion
    (let ((trcom (concat YaTeX-comment-prefix "+$")))
      (goto-char start)
      (while (re-search-forward trcom end t)
	(replace-match ""))))
)


(defun YaTeX-get-item-info ()
  "Return the list of the beginning of \\item and column of its item."
  (save-excursion
    (let* ((p (point))
	   (bndry (prog2 (search-backward "\\begin{" nil t) (point)
			 (goto-char p))))
      (end-of-line)
      (if (not (re-search-backward YaTeX-item-regexp bndry t))
	  (error "\\item not found."))
      ;;(skip-chars-forward "^ \t" (point-end-of-line))
      (goto-char (match-end 0))
      (if (equal (following-char) ?\[) (forward-list 1))
      (skip-chars-forward " \t" (point-end-of-line))
      ;;(if (not (eolp))  nil
      ;;	(forward-line 1)
      ;;	(skip-chars-forward "	 "))
      (list (point-beginning-of-line) (current-column))))
)

(defun YaTeX-fill-item ()
  "Fill item in itemize environment."
  (interactive)
  (save-excursion
      (let* ((p (point))
	     (item-term (concat
			 "\\(^$\\)\\|" YaTeX-item-regexp "\\|\\("
			 YaTeX-ec-regexp "end\\)"))
	     ;;This value is depend on LaTeX.
	     fill-prefix start col
	     (info (YaTeX-get-item-info)))
	(setq start (car info)
	      col (car (cdr info)))
	(beginning-of-line)
	(if (<= (save-excursion
		 (re-search-forward
		  (concat "\\\\end{\\|^ *$") nil t)
		 (match-beginning 0))
	       p)
	    (error "Not on itemize."))
	(end-of-line)
	(newline)
	(indent-to col)
	(setq fill-prefix
	      (buffer-substring (point-beginning-of-line)(point)))
	(beginning-of-line)
	(kill-line 1)
	(re-search-forward item-term nil 1)
	(YaTeX-remove-trailing-comment start (point))
	(beginning-of-line)
	(push-mark (point) t)
	(fill-region-as-paragraph start (mark))
	(if NTT-jTeX
	    (while (progn(forward-line -1)(end-of-line) (> (point) start))
	      (insert ?%)))
	(pop-mark)))
)

(defun YaTeX-fill-* ()
  "Fill paragraph according to its condition."
  (interactive)
  (cond
   ((YaTeX-fill-item))
   )
)

;; Accent completion
(defun YaTeX-read-accent-char (x)
  "Read char in accent braces."
  (let ((c (read-char)))
    (concat
     (if (and (or (= c ?i) (= c ?j))
	      (not (string-match (regexp-quote x) "cdb")))
	 "\\" "")
     (char-to-string c)))
)

(defun YaTeX-make-accent ()
  "Make accent usage."
  (interactive)
  (message "1:` 2:' 3:^ 4:\" 5:~ 6:= 7:. u v H t c d b")
  (let ((c (read-char))(case-fold-search nil))
    (setq c (cond ((and (> c ?0) (< c ?8))
		   (substring "`'^\"~=." (1- (- c ?0)) (- c ?0)))
		  ((= c ?h) "H")
		  (t (char-to-string c))))
    (if (not (string-match c "`'^\"~=.uvHtcdb")) nil
      (insert "\\" c "{}")
      (backward-char 1)
      (insert (YaTeX-read-accent-char c))
      (if (string= c "t") (insert (YaTeX-read-accent-char c)))
      (forward-char 1)))
)

;; Indentation
(defun YaTeX-current-indentation ()
  "Return the indentation of current environment."
  (save-excursion
    (beginning-of-line)
    (if (YaTeX-beginning-of-environment t) nil
      (forward-line -1))
    (beginning-of-line)
    (skip-chars-forward " \t")
    (current-column))
)

(defun YaTeX-reindent (col)
  "Remove current indentation and reindento to COL column."
  (save-excursion
    (beginning-of-line)
    (skip-chars-forward " \t")
    (kill-line 0)
    (indent-to col))
  (skip-chars-forward " \t" (point-end-of-line)))

(defun YaTeX-indent-relative ()
  (YaTeX-reindent (+ (YaTeX-current-indentation) YaTeX-environment-indent))
)

(defun YaTeX-indent-line ()
  "Indent corrent line referrin current environment."
  (interactive)
  (cond
   ((YaTeX-on-item-p)
    (if (= (point-beginning-of-line) (car (YaTeX-get-item-info)))
	(YaTeX-indent-relative)
      (YaTeX-reindent (car (cdr (YaTeX-get-item-info)))))
    )
   ((or (YaTeX-in-verb-p (point))
	(YaTeX-quick-in-environment-p '("verbatim" "verbatim*")))
    (tab-to-tab-stop))
   ((and (YaTeX-on-begin-end-p) (match-beginning 2))
    (YaTeX-reindent (YaTeX-current-indentation)))
   ((let ((inner (YaTeX-inner-environment t)))
      (and inner (not (equal "document" inner))))
    (YaTeX-indent-relative))
   ((and (bolp) fill-prefix) (insert fill-prefix))
   (t (save-excursion
	(beginning-of-line)
	(skip-chars-forward " \t")
	(indent-relative-maybe))
      (skip-chars-forward " \t")))
)

(defun YaTeX-tmp-table-symbol (symbol)
  "Return the lisp symbol which keeps local completion table of SYMBOL."
  (intern (concat "YaTeX$"
		  default-directory
		  (symbol-name symbol)))
)

(defun YaTeX-sync-tmp-table (symbol)
  "Synchronize local variable SYMBOL.
Copy its corresponding directory dependent completion table to SYMBOL."
  (if (boundp (YaTeX-tmp-table-symbol symbol))
      (set symbol (symbol-value (YaTeX-tmp-table-symbol symbol))))
)

(defun YaTeX-read-user-completion-table ()
  "Append user completion table of LaTeX macros"
  (let*((user-table (expand-file-name YaTeX-user-completion-table))
	(tmp-table (expand-file-name (file-name-nondirectory user-table))))
    (if YaTeX-user-table-has-read nil
      (message "Loading personal completion table")
      (if (file-exists-p user-table) (load-file user-table)
	(message "Personal completion table not found.")))
    (setq YaTeX-user-table-has-read t)
    (cond
     ((file-exists-p tmp-table)
      (progn
	(if (boundp (YaTeX-tmp-table-symbol 'tmp-env-table))
	    nil				;do not load twice or more(94/6/24).
	  (load-file tmp-table)
	  (mapcar
	   (function
	    (lambda (sym)
	      (or (and (boundp (YaTeX-tmp-table-symbol sym))
		       (symbol-value (YaTeX-tmp-table-symbol sym)))
		  (set (YaTeX-tmp-table-symbol sym)
		       (symbol-value sym)))))
	   '(tmp-env-table tmp-section-table
	     tmp-fontsize-table tmp-singlecmd-table)))
      ))))
)

(defun YaTeX-update-table (vallist default-table user-table tmp-table)
  "Update completion table if the car of VALLIST is not in current tables.
Second argument DEFAULT-TABLE is the quoted symbol of default completion
table, third argument USER-TABLE is user table which will be saved in
YaTeX-user-completion-table, fourth argument TMP-TABLE should have the
completion which is valid during current Emacs's session.  If you
want to make TMP-TABLE valid longer span (but restrict in this directory)
create the file in current directory which has the same name with
YaTeX-user-completion-table."
  (let ((car-v (car vallist)) key answer
	(file (file-name-nondirectory YaTeX-user-completion-table)))
    (cond
     ((assoc car-v (symbol-value default-table))
      nil) ;Nothing to do
     ((setq key (assoc car-v (symbol-value user-table)))
      (if (equal (cdr vallist) (cdr key)) nil
	;; if association hits, but contents differ.
	(message
	 "%s's attributes turned into %s" (car vallist) (cdr vallist))
	(set user-table (delq key (symbol-value user-table)))
	(set user-table (cons vallist (symbol-value user-table)))
	(setq YaTeX-user-table-modified t)))
     ((setq key (assoc car-v (symbol-value tmp-table)))
      (if (equal (cdr vallist) (cdr key)) nil
	(message
	 "%s's attributes turned into %s" (car vallist) (cdr vallist))
	(set tmp-table (delq key (symbol-value tmp-table)))
	(set tmp-table (cons vallist (symbol-value tmp-table)))
	(set (YaTeX-tmp-table-symbol tmp-table) (symbol-value tmp-table))
	(YaTeX-save-tmp-table file tmp-table)))
     ;; All of above cases, there are some completion in tables.
     ;; Then update tables.
     (t
      (if (not YaTeX-nervous)
	  (setq answer ?u)
	(message
	 "`%s' is not in table. Register into: U)serTable L)ocalTable N)one"
	 (car vallist))
	(setq answer (read-char)))
      (cond
       ((or (= answer ?u) (= answer ?y))
	(set user-table (cons vallist (symbol-value user-table)))
	(setq YaTeX-user-table-modified t))
       ((or (= answer ?t) (= answer ?T) (= answer ?l) (= answer ?L))
	(set tmp-table (cons vallist (symbol-value tmp-table)))
	(set (YaTeX-tmp-table-symbol tmp-table) (symbol-value tmp-table))
	(YaTeX-save-tmp-table file tmp-table))
       (t nil)))))
)

(defun YaTeX-save-tmp-table (file symbol)
  (if (and t  ;;(file-exists-p file) ;force write(1.49)
	   (not (string= (expand-file-name YaTeX-user-completion-table)
			 (expand-file-name file))))
      (let ((tmp-table-buf (find-file-noselect file))
	    (name (symbol-name symbol))
	    (value (symbol-value symbol)))
	(save-excursion
	  (message "Updating local table...")
	  (set-buffer tmp-table-buf)
	  (goto-char (point-max))
	  (search-backward (concat "(setq " name) nil t)
	  (delete-region (point) (progn (forward-sexp) (point)))
	  (delete-blank-lines)
	  (insert "(setq " name " '(\n")
	  (mapcar '(lambda (s)
		     (insert (format "%s\n" (prin1-to-string s))))
		  value)
	  (insert "))\n\n")
	  (if (eobp) (delete-blank-lines))
	  (basic-save-buffer)
	  (kill-buffer tmp-table-buf)
	  (message "Updating local table...Done"))))
)

(defun YaTeX-save-table ()
  "Save personal completion table as dictionary."
  (interactive)
  (if (not YaTeX-user-table-modified)
      nil
    (message "Saving user table in %s" YaTeX-user-completion-table)
    (find-file (expand-file-name YaTeX-user-completion-table))
    (erase-buffer)
    (mapcar '(lambda (table-sym)
	       (insert (format "(setq %s '(\n" table-sym))
	       (mapcar '(lambda (s)
			  (insert (format "%s\n" s)))
		       (prin1-to-string (symbol-value table-sym)))
	       (insert "))\n\n"))
	    '(user-section-table user-article-table user-env-table
				 user-fontsize-table user-singlecmd-table))

    (basic-save-buffer)
    (kill-buffer (current-buffer))
    (message "")
    (setq YaTeX-user-table-modified nil))
)

;; --------------- General sub functions ---------------
(defun point-beginning-of-line ()
  (save-excursion (beginning-of-line)(point))
)

(defun point-end-of-line ()
  (save-excursion (end-of-line)(point))
)

;;--------------------- hooks for the standard functions --------------------
(if (fboundp 'YaTeX-saved-kill-emacs) nil
  (fset 'YaTeX-saved-kill-emacs (symbol-function 'kill-emacs))
  (fset 'kill-emacs
	(function (lambda (&optional query)
		    (interactive "P")
		    (YaTeX-save-table)
		    (YaTeX-saved-kill-emacs arg))))
)

(if (fboundp 'YaTeX-saved-fill-paragraph) nil
  (fset 'YaTeX-saved-fill-paragraph (symbol-function 'fill-paragraph))
  (fset 'fill-paragraph
	(function (lambda (arg)
		    (interactive "P")
		    (if (or (not (eq major-mode 'yatex-mode))
			    (not (YaTeX-quick-in-environment-p
				  YaTeX-fill-inhibit-environments)))
			(YaTeX-saved-fill-paragraph arg)))))
)

(provide 'yatex)
(defvar yatex-mode-load-hook nil
  "*List of functions to be called when yatex.el is loaded.")
(if YaTeX-emacs-19 (load "yatex19.el"))
(run-hooks 'yatex-mode-load-hook)
(load "yatexhks" t)
;--------------------------------- History ---------------------------------
; Rev. |   Date   | Contents
;------+----------+---------------------------------------------------------
; 1.00 | 91/ 6/13 | Initial version.
;      |          | Auto compilation & preview.
;      |          | \section{}-type and \begin{}\end{}-type completion.
; 1.01 | 91/ 6/14 | Add {\large ..} type completion (prefix+l).
; 1.10 |     6/21 | Add learning feature of completion.
; 1.11 |     6/27 | Simplify function begin-document etc. using lambda.
; 1.12 |     7/ 6 | Modify YaTeX-make-section, show section-name.
; 1.13 |    12/ 4 | Delete blank lines in make begin/end environment.
; 1.20 |    12/ 5 | Saving learned completions into user file.
; 1.21 |    12/ 6 | Add \maketitle type completion (prefix+m).
; 1.22 |    12/30 | Port yatex.el to DOS(Demacs).
; 1.23 | 92/ 1/ 8 | Enable latex and preview command on DOS.
; 1.24 |     1/ 9 | Add YaTeX-save-table to kill-emacs-hook automatically.
; 1.25 |     1/16 | YaTeX-do-completion (prefix+SPC) and argument
;      |          | acceptable YaTeX-make-section work. Put region into
;      |          | \begin...\end by calling YaTeX-make-begin-end with ARG.
;      |          | append-kill-emacs-hook was revised to append-to-hook.
; 1.26 |     1/18 | Region mode is added to {\large }. Default fontsize.
; 1.27 |     1/21 | Default name on completing-read.
; 1.28 |     7/ 2 | Add \nonstopmode{} automatically on DOS.
;      |     7/20 | %#! usage to specify latex command and its arguments.
;      |          | Change default fill-prefix from TAB to null string.
; 1.29 |     7/21 | Add YaTeX-end-environment.
; 1.30 |     9/26 | Support project 30 lines(other than 25 lines).
; 1.31 |    10/28 | Variable argument for previewer from %#! usage.
; 1.32 |    11/16 | YaTeX-goto-corresponding-environment.
;      |          | Comment out region/paragraph added.
; 1.33 |    11/29 | Variable default value, on DOS and other OS.
;      |          | Make dvi2-command buffer local.  Change the behavior of
;      |          | comment out region/paragraph on the \begin{} or \end{}
;      |          | line.  Make YaTeX-end-environment faster. Add YaTeX-
;      |          | define-key, YaTeX-define-begend-(region-)key.
; 1.34 |    12/26 | YaTeX-goto-corresponding-* automatically choose its move.
;      |          | YaTeX-prev-error supports separate typesetting.
; 1.35 | 93/ 1/25 | YaTeX-kill-environment erases pair of begin/end.
;      |          | YaTeX-change-environment change the environment name.
;      |          | Auto indent at YaTeX-make-begin-end.
; 1.36 |     1/27 | YaTeX-typeset-region typesets the region from %#BEGIN to
;      |          | %#END, or simple region between point and mark.
; 1.37 |     2/12 | YaTeX-kill-environment turns YaTeX-kill-some-pairs and
;      |          | now it can kill %#BEGIN and %#END pairs.
;      |          | Now YaTeX-goto-corresponding-environment detects nested
;      |          | environment.  Put `"\ by `"' in verbatim.  Auto save
;      |          | buffers with query.  Add current file to includeonly list
;      |          | automatically.  Support YaTeX-fill-item, YaTeX-make-
;      |          | accent, YaTeX-visit-main-other-window.
;      |          | [prefix] tl for lpr.  Revise YaTeX-view-error.
; 1.38 |     2/20 | Fix for byte-compilation.  Do not ask from/to page if
;      |          | no %f/%t was given.  Support temporary dictionary if
;      |          | YaTeX-nervous is t.  Remember the number of section-type
;      |          | command's  argument add learning feature to it.
;      |          | Abolish append-to-hook, override kill-emacs instead.
; 1.39 |     2/25 | Send string to halted latex command in typeset-buffer.
;      |(birthday)| Add YaTeX-bibtex-buffer and YaTeX-kill-typeset-process.
;      |          | Now you can edit with seeing typeset buffer scrolling.
; 1.40 |     3/ 2 | Support sources in sub directories.  Give "texput" at
;      |          | preview prompt after typeset-region.  yatexprc.el
; 1.41 |     3/ 9 | Automatic generation of add-in function.
;      |          | Typesetting buffer now accepts string correctly.
;      |          | Addin function for maketitle-type completion.
; 1.42 |     5/ 3 | Fill-paragraph and (un)comment-paragraph work fine.
;      |          | Fix kill range of YaTeX-kill-some-pairs.  Ignore begin/
;      |          | end in verb or verbatim.  Indent rigidly initial space
;      |          | between begin/end pairs.  Add yatex-mode-load-hook.
;      |          | Go to corresponding \label or \ref.
; 1.43 |     5/31 | Indentation of environments.  Add yatexmth, math-mode,
;      |          | modify-mode.  Complete label in \ref by menu.  Optimize
;      |          | window selection in yatexprc.
; 1.44 |    10/25 | Fasten the invocation of typesetter.  Optimize window
;      |          | use.  Change mode-line format properly.  Turn on math-
;      |          | mode automatically at completion of LaTeX math-mode.
; 1.45 | 94/ 1/27 | Show message at comment-region on begin/end mode.
;      |          | Greek letters completion in yatexmth.  Add the function
;      |          | YaTeX-mark-environment and YaTeX-%-menu.  Erase cursor
;      |          | at the execution of dviout(DOS).  Enable recursive
;      |          | completion at section-type completion.
; 1.46 | 94/ 4/23 | Region-based section-type complete.  Kill section-type
;      |          | command and parentheses by [prefix] k.  Error jump
;      |          | now jumps proper position.  Fix the bug of recursive
;      |          | section-type completion.
; 1.47 | 94/ 4/25 | Fix bugs in YaTeX-quick-in-environment-p and YaTeX-
;      |          | get-latex-command.
; 1.48 | 94/ 5/ 5 | Auto-indent at begin-type completion works fine.
;      |          | With gmhist, independent history list is available
;      |          | at the prompt of Preview/Lpr/Call-command.  Fix the
;      |          | bug on \ref-completion.  YaTeX-help is now available.
; 1.49 | 94/ 5/16 | Make variables for temporary dictionary buffer-local.
;      |          | Change the default value of YaTeX-nervous to t.
;      |          | Create a temporary dictionary file when `T' is selected
;      |          | at the dictionary selection menu.
; 1.50 | 94/ 7/ 8 | Change the YaTeX-math-mode's prefix from `,' to `;'.
;      |          | Add YaTeX-apropos, YaTeX-what-column, YaTeX-beginning-
;      |          | of-environment, YaTeX-end-of-environment.  Add variables
;      |          | YaTeX-default-pop-window-height, YaTeX-close-paren-always
;      |          | YaTeX-no-begend-shortcut, YaTeX-auto-math-mode. Remove
;      |          | Greek letters from maketitle-type.  Make YaTeX-inner-
;      |          | environment two times faster and reliable.  C-u for
;      |          | [prefix] k kills contents too.  Fix the detection of
;      |          | the range of section-type commands when nested.
;      |          | Add \end{ completion.  Add YaTeX-generate-simple.
;      |          | Refine documents.  %#REQUIRE for sub-preambles.
; 1.51 | 94/ 9/20 | Support menu-bar. Fix YaTeX-fill-item, YaTeX-indent-line.
;      |          | Support hilit19.
; 1.52 | 94/10/24 | Support special-popup-frame.  Refine highlightening.
;      |          | Modify saving-table functions for Emacs-19.
;----------------------------- End of yatex.el -----------------------------
