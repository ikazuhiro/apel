;;; emu-mule.el --- emu module for Mule 1.* and Mule 2.*

;; Copyright (C) 1995,1996,1997,1998 MORIOKA Tomohiko

;; Author: MORIOKA Tomohiko <morioka@jaist.ac.jp>
;;         Katsumi Yamaoka <yamaoka@jpl.org>
;; Keywords: emulation, compatibility, Mule

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

;;; Code:

;;; @ version specific features
;;;

(cond (running-emacs-19
       (require 'emu-e19)
       
       ;; Suggested by SASAKI Osamu <osamu@shuugr.bekkoame.or.jp>
       ;; (cf. [os2-emacs-ja:78])
       (defun fontset-pixel-size (fontset)
	 (let* ((font (get-font-info
		       (aref (cdr (get-fontset-info fontset)) 0)))
		(open (aref font 4)))
	   (if (= open 1)
	       (aref font 5)
	     (if (= open 0)
		 (let ((pat (aref font 1)))
		   (if (string-match "-[0-9]+-" pat)
		       (string-to-number
			(substring
			 pat (1+ (match-beginning 0)) (1- (match-end 0))))
		     0)))
	     )))
       )
      (running-emacs-18
       (require 'emu-18)
       (defun make-overlay (beg end &optional buffer type))
       (defun overlay-put (overlay prop value))
       ))


;;; @ character set
;;;

(defalias 'make-char 'make-character)

(defalias 'find-non-ascii-charset-string 'find-charset-string)
(defalias 'find-non-ascii-charset-region 'find-charset-region)

(defalias 'charset-bytes	'char-bytes)
(defalias 'charset-description	'char-description)
(defalias 'charset-registry	'char-registry)
(defalias 'charset-columns	'char-width)
(defalias 'charset-direction	'char-direction)

(defun charset-chars (charset)
  "Return the number of characters per dimension of CHARSET."
  (if (= (logand (nth 2 (character-set charset)) 1) 1)
      96
    94))


;;; @ coding system
;;;

(defun encode-coding-region (start end coding-system)
  "Encode the text between START and END to CODING-SYSTEM.
\[EMACS 20 emulating function]"
  (code-convert-region start end *internal* coding-system)
  )

(defun decode-coding-region (start end coding-system)
  "Decode the text between START and END which is encoded in CODING-SYSTEM.
\[EMACS 20 emulating function]"
  (code-convert-region start end coding-system *internal*)
  )

(defun encode-coding-string (str coding-system)
  "Encode the STRING to CODING-SYSTEM.
\[EMACS 20 emulating function]"
  (code-convert-string str *internal* coding-system)
  )

(defun decode-coding-string (str coding-system)
  "Decode the string STR which is encoded in CODING-SYSTEM.
\[EMACS 20 emulating function]"
  (let ((len (length str))
	ret)
    (while (and
	    (< 0 len)
	    (null
	     (setq ret
		   (code-convert-string (substring str 0 len)
					coding-system *internal*))
	     ))
      (setq len (1- len))
      )
    (concat ret (substring str len))
    ))

(defalias 'detect-coding-region 'code-detect-region)

(defalias 'set-buffer-file-coding-system 'set-file-coding-system)

(defmacro as-binary-process (&rest body)
  (` (let (selective-display	; Disable ^M to nl translation.
	   ;; Mule
	   mc-flag	
	   (default-process-coding-system (cons *noconv* *noconv*))
	   program-coding-system-alist)
       (,@ body)
       )))

(defmacro as-binary-input-file (&rest body)
  (` (let (mc-flag
	   (file-coding-system-for-read *noconv*)
	   )
       (,@ body)
       )))

(defmacro as-binary-output-file (&rest body)
  (` (let (mc-flag
	   (file-coding-system *noconv*)
	   )
       (,@ body)
       )))

(defalias 'set-process-input-coding-system 'set-process-coding-system)


;;; @ binary access
;;;

(defun insert-file-contents-as-binary (filename
				       &optional visit beg end replace)
  "Like `insert-file-contents', q.v., but don't code and format conversion.
Like `insert-file-contents-literary', but it allows find-file-hooks,
automatic uncompression, etc.

Namely this function ensures that only format decoding and character
code conversion will not take place."
  (let (mc-flag
	(file-coding-system *noconv*))
    (insert-file-contents filename visit beg end replace)
    ))

(defalias 'insert-binary-file-contents 'insert-file-contents-as-binary)
(make-obsolete 'insert-binary-file-contents 'insert-file-contents-as-binary)

(defun insert-binary-file-contents-literally (filename
					      &optional visit beg end replace)
  "Like `insert-file-contents-literally', q.v., but don't code conversion.
A buffer may be modified in several ways after reading into the buffer due
to advanced Emacs features, such as file-name-handlers, format decoding,
find-file-hooks, etc.
  This function ensures that none of these modifications will take place."
  (let (mc-flag
	(file-coding-system *noconv*))
    (insert-file-contents-literally filename visit beg end replace)
    ))

(if running-emacs-19_29-or-later
    ;; for MULE 2.3 based on Emacs 19.34.
    (defun write-region-as-binary (start end filename
					 &optional append visit lockname)
      "Like `write-region', q.v., but don't code conversion."
      (let (mc-flag
	    (file-coding-system *noconv*))
	(write-region start end filename append visit lockname)
	))
  ;; for MULE 2.3 based on Emacs 19.28.
  (defun write-region-as-binary (start end filename
				       &optional append visit lockname)
    "Like `write-region', q.v., but don't code conversion."
    (let (mc-flag
	  (file-coding-system *noconv*))
      (write-region start end filename append visit)
      ))
  )


;;; @ MIME charset
;;;

(defun encode-mime-charset-region (start end charset)
  "Encode the text between START and END as MIME CHARSET."
  (let ((cs (mime-charset-to-coding-system charset)))
    (if cs
	(code-convert start end *internal* cs)
      )))

(defun decode-mime-charset-region (start end charset)
  "Decode the text between START and END as MIME CHARSET."
  (let ((cs (mime-charset-to-coding-system charset)))
    (if cs
	(code-convert start end cs *internal*)
      )))

(defun encode-mime-charset-string (string charset)
  "Encode the STRING as MIME CHARSET."
  (let ((cs (mime-charset-to-coding-system charset)))
    (if cs
	(code-convert-string string *internal* cs)
      string)))

(defun decode-mime-charset-string (string charset)
  "Decode the STRING which is encoded in MIME CHARSET."
  (let ((cs (mime-charset-to-coding-system charset)))
    (if cs
	(decode-coding-string string cs)
      string)))

(defun write-region-as-mime-charset (charset start end filename)
  "Like `write-region', q.v., but code-convert by MIME CHARSET."
  (let ((file-coding-system
	 (or (mime-charset-to-coding-system charset)
	     *noconv*)))
    (write-region start end filename append visit)
    ))


;;; @@ to coding-system
;;;

(defvar mime-charset-coding-system-alist
  '((iso-8859-1      . *ctext*)
    (x-ctext         . *ctext*)
    (gb2312          . *euc-china*)
    (koi8-r          . *koi8*)
    (iso-2022-jp-2   . *iso-2022-ss2-7*)
    (x-iso-2022-jp-2 . *iso-2022-ss2-7*)
    (shift_jis       . *sjis*)
    (x-shiftjis      . *sjis*)
    ))

(defun mime-charset-to-coding-system (charset &optional lbt)
  (if (stringp charset)
      (setq charset (intern (downcase charset)))
    )
  (let ((cs
	 (or (cdr (assq charset mime-charset-coding-system-alist))
	     (let ((cs (intern (concat "*" (symbol-name charset) "*"))))
	       (and (coding-system-p cs) cs)
	       ))))
    (if (or (null lbt)
	    (null cs))
	cs
      (intern (concat (symbol-name cs) (symbol-name lbt)))
      )))


;;; @@ detection
;;;

(defvar charsets-mime-charset-alist
  (let ((alist
	 '(((lc-ascii)					. us-ascii)
	   ((lc-ascii lc-ltn1)				. iso-8859-1)
	   ((lc-ascii lc-ltn2)				. iso-8859-2)
	   ((lc-ascii lc-ltn3)				. iso-8859-3)
	   ((lc-ascii lc-ltn4)				. iso-8859-4)
;;;	   ((lc-ascii lc-crl)				. iso-8859-5)
	   ((lc-ascii lc-crl)				. koi8-r)
	   ((lc-ascii lc-arb)				. iso-8859-6)
	   ((lc-ascii lc-grk)				. iso-8859-7)
	   ((lc-ascii lc-hbw)				. iso-8859-8)
	   ((lc-ascii lc-ltn5)				. iso-8859-9)
	   ((lc-ascii lc-roman lc-jpold lc-jp)		. iso-2022-jp)
	   ((lc-ascii lc-kr)				. euc-kr)
	   ((lc-ascii lc-cn)				. gb2312)
	   ((lc-ascii lc-big5-1 lc-big5-2)		. big5)
	   ((lc-ascii lc-roman lc-ltn1 lc-grk
		      lc-jpold lc-cn lc-jp lc-kr
		      lc-jp2)				. iso-2022-jp-2)
	   ((lc-ascii lc-roman lc-ltn1 lc-grk
		      lc-jpold lc-cn lc-jp lc-kr lc-jp2
		      lc-cns1 lc-cns2)			. iso-2022-int-1)
	   ((lc-ascii lc-roman
		      lc-ltn1 lc-ltn2 lc-crl lc-grk
		      lc-jpold lc-cn lc-jp lc-kr lc-jp2
		      lc-cns1 lc-cns2 lc-cns3 lc-cns4
		      lc-cns5 lc-cns6 lc-cns7)		. iso-2022-int-1)
	   ))
	dest)
    (while alist
      (catch 'not-found
	(let ((pair (car alist)))
	  (setq dest
		(append dest
			(list
			 (cons (mapcar (function
					(lambda (cs)
					  (if (boundp cs)
					      (symbol-value cs)
					    (throw 'not-found nil)
					    )))
				       (car pair))
			       (cdr pair)))))))
      (setq alist (cdr alist)))
    dest))

(defvar default-mime-charset 'x-ctext
  "Default value of MIME-charset.
It is used when MIME-charset is not specified.
It must be symbol.")

(defun detect-mime-charset-region (start end)
  "Return MIME charset for region between START and END."
  (charsets-to-mime-charset
   (cons lc-ascii (find-charset-region start end))))


;;; @ character
;;;

(defalias 'char-charset 'char-leading-char)

(defmacro char-next-index (char index)
  "Return index of character succeeding CHAR whose index is INDEX."
  (` (+ (, index) (char-bytes (, char)))))

;;; @@ obsoleted aliases
;;;
;;; You should not use them.

(defalias 'char-length 'char-bytes)
;;(defalias 'char-columns 'char-width)


;;; @ string
;;;

(defalias 'string-columns 'string-width)

(defalias 'string-to-int-list 'string-to-char-list)

(or (fboundp 'truncate-string)
;;; Imported from Mule-2.3
(defun truncate-string (str width &optional start-column)
  "Truncate STR to fit in WIDTH columns.
Optional non-nil arg START-COLUMN specifies the starting column.
\[emu-mule.el; Mule 2.3 emulating function]"
  (or start-column
      (setq start-column 0))
  (let ((max-width (string-width str))
	(len (length str))
	(from 0)
	(column 0)
	to-prev to ch)
    (if (>= width max-width)
	(setq width max-width))
    (if (>= start-column width)
	""
      (while (< column start-column)
	(setq ch (aref str from)
	      column (+ column (char-width ch))
	      from (+ from (char-bytes ch))))
      (if (< width max-width)
	  (progn
	    (setq to from)
	    (while (<= column width)
	      (setq ch (aref str to)
		    column (+ column (char-width ch))
		    to-prev to
		    to (+ to (char-bytes ch))))
	    (setq to to-prev)))
      (substring str from to))))
;;;
  )

(defalias 'looking-at-as-unibyte 'looking-at)


;;; @ regulation
;;;

(defun regulate-latin-char (chr)
  (cond ((and (<= ?$B#A(B chr)(<= chr ?$B#Z(B))
	 (+ (- chr ?$B#A(B) ?A)
	 )
	((and (<= ?$B#a(B chr)(<= chr ?$B#z(B))
	 (+ (- chr ?$B#a(B) ?a)
	 )
	((eq chr ?$B!%(B) ?.)
	((eq chr ?$B!$(B) ?,)
	(t chr)
	))

(defun regulate-latin-string (str)
  (let ((len (length str))
	(i 0)
	chr (dest ""))
    (while (< i len)
      (setq chr (sref str i))
      (setq dest (concat dest
			 (char-to-string (regulate-latin-char chr))))
      (setq i (+ i (char-bytes chr)))
      )
    dest))


;;; @ end
;;;

(provide 'emu-mule)

;;; emu-mule.el ends here
