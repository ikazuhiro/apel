;;; emu-x20.el --- emu API implementation for XEmacs with mule

;; Copyright (C) 1994,1995,1996,1997,1998 MORIOKA Tomohiko

;; Author: MORIOKA Tomohiko <morioka@jaist.ac.jp>
;; Version: $Id$
;; Keywords: emulation, compatibility, Mule, XEmacs

;; This file is part of emu.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;;    This module requires XEmacs 20.3-b5 or later with mule.

;;; Code:

(require 'emu-xemacs)
(require 'emu-20)


(and (coding-system-property 'iso-2022-jp 'input-charset-conversion)
     (copy-coding-system 'iso-2022-7bit 'iso-2022-jp))


;;; @ binary access
;;;

(defun insert-binary-file-contents (filename &optional visit beg end replace)
  "Like `insert-file-contents', q.v., but don't code and format conversion."
  (let ((coding-system-for-read 'binary)
	format-alist)
    (insert-file-contents filename visit beg end replace)
    ))

    
;;; @ MIME charset
;;;

(defsubst encode-mime-charset-region (start end charset)
  "Encode the text between START and END as MIME CHARSET."
  (let ((cs (mime-charset-to-coding-system charset)))
    (if cs
	(encode-coding-region start end cs)
      )))

(defsubst decode-mime-charset-region (start end charset)
  "Decode the text between START and END as MIME CHARSET."
  (let ((cs (mime-charset-to-coding-system charset)))
    (if cs
	(decode-coding-region start end cs)
      )))

(defsubst encode-mime-charset-string (string charset)
  "Encode the STRING as MIME CHARSET."
  (let ((cs (mime-charset-to-coding-system charset)))
    (if cs
	(encode-coding-string string cs)
      string)))

(defsubst decode-mime-charset-string (string charset)
  "Decode the STRING as MIME CHARSET."
  (let ((cs (mime-charset-to-coding-system charset)))
    (if cs
	(decode-coding-string string cs)
      string)))


(defvar charsets-mime-charset-alist
  '(((ascii)						. us-ascii)
    ((ascii latin-iso8859-1)				. iso-8859-1)
    ((ascii latin-iso8859-2)				. iso-8859-2)
    ((ascii latin-iso8859-3)				. iso-8859-3)
    ((ascii latin-iso8859-4)				. iso-8859-4)
    ((ascii cyrillic-iso8859-5)				. iso-8859-5)
;;; ((ascii cyrillic-iso8859-5)				. koi8-r)
    ((ascii arabic-iso8859-6)				. iso-8859-6)
    ((ascii greek-iso8859-7)				. iso-8859-7)
    ((ascii hebrew-iso8859-8)				. iso-8859-8)
    ((ascii latin-iso8859-9)				. iso-8859-9)
    ((ascii latin-jisx0201
	    japanese-jisx0208-1978 japanese-jisx0208)	. iso-2022-jp)
    ((ascii korean-ksc5601)				. euc-kr)
    ((ascii chinese-gb2312)				. cn-gb-2312)
    ((ascii chinese-big5-1 chinese-big5-2)		. cn-big5)
    ((ascii latin-iso8859-1 greek-iso8859-7
	    latin-jisx0201 japanese-jisx0208-1978
	    chinese-gb2312 japanese-jisx0208
	    korean-ksc5601 japanese-jisx0212)		. iso-2022-jp-2)
    ((ascii latin-iso8859-1 greek-iso8859-7
	    latin-jisx0201 japanese-jisx0208-1978
	    chinese-gb2312 japanese-jisx0208
	    korean-ksc5601 japanese-jisx0212
	    chinese-cns11643-1 chinese-cns11643-2)	. iso-2022-int-1)
    ((ascii latin-iso8859-1 latin-iso8859-2
	    cyrillic-iso8859-5 greek-iso8859-7
	    latin-jisx0201 japanese-jisx0208-1978
	    chinese-gb2312 japanese-jisx0208
	    korean-ksc5601 japanese-jisx0212
	    chinese-cns11643-1 chinese-cns11643-2
	    chinese-cns11643-3 chinese-cns11643-4
	    chinese-cns11643-5 chinese-cns11643-6
	    chinese-cns11643-7)				. iso-2022-int-1)
    ))

(defun detect-mime-charset-region (start end)
  "Return MIME charset for region between START and END."
  (charsets-to-mime-charset (charsets-in-region start end)))


;;; @ character
;;;

;;; @@ Mule emulating aliases
;;;
;;; You should not use them.

(defalias 'char-leading-char 'char-charset)

(defun char-category (character)
  "Return string of category mnemonics for CHAR in TABLE.
CHAR can be any multilingual character
TABLE defaults to the current buffer's category table."
  (mapconcat (lambda (chr)
	       (char-to-string (int-char chr))
	       )
	     (char-category-list character)
	     ""))


;;; @ string
;;;

(defun string-to-int-list (str)
  (mapcar #'char-int str)
  )


;;; @ end
;;;

(provide 'emu-x20)

;;; emu-x20.el ends here
