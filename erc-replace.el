;; erc-replace.el -- wash and massage messages inserted into the buffer

;; Copyright (C) 2001, 2002, 2004 Free Software Foundation, Inc.

;; Author: Andreas Fuchs <asf@void.at>
;; Maintainer: Mario Lang (mlang@delysid.org)
;; Keywords: IRC, client, Internet
;; URL: http://www.emacswiki.org/cgi-bin/wiki.pl?ErcReplace

;; This file is part of GNU Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This module allows you to systematically replace text in incoming
;; messages.  Load erc-replace, and customize `erc-replace-alist'.
;; Then add to your ~/.emacs:

;; (require 'erc-replace)
;; (erc-replace-mode 1)

;;; Code:

(require 'erc)

(defconst erc-replace-version "$Revision: 1.8 $"
  "Revision of the ERC replace module.")

(defgroup erc-replace nil
  "Replace text from incoming messages"
  :group 'erc)

(defcustom erc-replace-alist nil
  "Alist describing text to be replaced in incoming messages.
This is useful for filters.

The alist has elements of the form (FROM . TO).  FROM can be a regular
expression or a variable, or any sexp, TO can be a string or a
function to call, or any sexp.  If a function, it will be called with
one argument, the string to be replaced, and it should return a
replacement string."
  :group 'erc-replace
  :type '(repeat (cons :tag "Search & Replace"
		       (choice :tag "From"
			       regexp
			       variable
			       sexp)
		       (choice :tag "To"
			       string
			       function
			       sexp))))

(defun erc-replace-insert ()
  "Function to run from `erc-insert-modify-hook'.
It replaces text according to `erc-replace-alist'."
  (mapcar (lambda (elt)
	    (goto-char (point-min))
	    (let ((from (car elt))
		  (to (cdr elt)))
	      (unless (stringp from)
		(setq from (eval from)))
	      (while (re-search-forward from nil t)
		(cond ((stringp to)
		       (replace-match to))
		      ((and (symbolp to) (fboundp to))
		       (replace-match (funcall to (match-string 0))))
		      (t
		       (eval to))))))
	  erc-replace-alist))

;;;###autoload (autoload 'erc-replace-mode "erc-replace")
(define-erc-module replace nil
  "This mode replaces incoming text according to `erc-replace-alist'."
  ((add-hook 'erc-insert-modify-hook
	     'erc-replace-insert))
  ((remove-hook 'erc-insert-modify-hook
		'erc-replace-insert)))

(provide 'erc-replace)

;; arch-tag: dd904a59-d8a6-47f8-ac3a-76b698289a18
;;; erc-replace.el ends here
