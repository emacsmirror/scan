;;; scan.el --- Scanning Sleeves
;; Copyright (C) 2001, 2002, 2003, 2010, 2011 Lars Magne Ingebrigtsen

;; Author: Lars Magne Ingebrigtsen <larsi@gnus.org>
;; Keywords: music

;; This file is not part of GNU Emacs.

;; Scan is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; Scan is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.

;; You should have received a copy of the GNU General Public License
;; along with Scan; see the file COPYING.  If not, write to the Free
;; Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;; 02111-1307, USA.

;;; Commentary:

;;; Code:

(require 'cl)
(require 'gnus-util)

(defvar scan-command "scanimage --mode=color -d epson --resolution 300dpi -x %s -y %s -l %s -t %s | pnmflip -topbottom -leftright"
  "Command to scan an image.")

(defvar scan-filter "pnmnorm -bvalue 20 -wvalue 235"
  "Command to do post-processing on the image.")

(defun scan-sleeve (dir &optional complete)
  (interactive "DDirectory: ")
  (let ((suffix "")
	(part 0)
	(continue t))
    (while continue
      (let ((spec (scan-type)))
	(if spec
	    (scan-sleeve-1 dir spec suffix (not complete))
	  (setq continue nil)))
      (if complete
	  (setq suffix (format "-%d" (incf part)))
	(setq continue nil)))))

(defun scan-sleeve-1 (dir spec suffix async)
  (message "Scanning sleeve %s" spec)
  (let ((default-directory dir))
    (call-process "scan-sleeve" nil (and async 0) nil
		  dir
		  (number-to-string (nth 0 spec))
		  (number-to-string (nth 1 spec))
		  (number-to-string (or (nth 2 spec) 0))
		  (number-to-string (or (nth 3 spec) 0))
		  suffix)))

(defun scan-type (&optional return-choice)
  ;; The numbers are in millimeters, and are width/height, with
  ;; optional start-x/start-y parameters.
  (let* ((types '((?\r "cd" 117 117)
		  (?n "cdsingle" 138 123)
		  (?C "cdsingle other way" 123 138)
		  (?q "square" 120 123)
		  (?Q "bigger square" 135 135)
		  (?m "clam" 124 125)
		  (?M "mego" 140 165)
		  (?I "slim" 135 116)
		  (?h "high" 120 170)
		  (?2 "12 inch" 310 310)
		  (?H "high and slimmer" 120 170)
		  (?d "dvd" 132 182)
		  (?w "wolf eyes" 145 180)
		  (?D "deluxe high" 130 230)
		  (?t "tape with box" 72 108)
		  (?T "unboxed tape" 65 104)
		  (?R "raster-noton" 150 190)
		  (?3 "3 inch" 85 85)
		  (?l "lp" 310 310)
		  (?L "lp" 320 320)
		  (?i "inner lp" 304 304)
		  (?7 "7 inch" 180 180)
		  (?8 "7 inch label" 120 120 30 30)
		  (?w "Wide 7 inch" 185 180)
		  (?1 "10 inch" 258 258)
		  (?2 "10 inch label" 130 130 60 60)
		  (?a "label" 140 140 80 80)
		  (?z "end")))
	 (choice (gnus-multiple-choice "Sleeve type" types)))
    (if return-choice
	(assq choice types)
      (cddr (assq choice types)))))

(defvar scan-directory "/data/tmp")

(defun scan-with-name (name)
  "Prompt for an item name (like CAD408), create the directory and scan."
  (interactive "sItem name: ")
  (let ((dir (expand-file-name name scan-directory)))
    (unless (file-exists-p dir)
      (make-directory dir)
      (let ((part 0)
	    (continue t))
	(while continue
	  (let ((spec (scan-type t)))
	    (if (not spec)
		(setq continue nil)
	      (shell-command
	       (format "scanimage --mode=color -d epson --resolution 300dpi -t %s -l %s -x %s -y %s | pnmflip -topbottom -leftright | pnmtotiff > %s/%s-%d-%c.tiff"
		       (or (nth 4 spec) 0)
		       (or (nth 5 spec) 0)
		       (nth 2 spec) (nth 3 spec)
		       dir name (incf part)
		       (nth 0 spec))))))))))

(provide 'scan)

;;; scan.el ends here
