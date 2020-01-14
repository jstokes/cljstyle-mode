;;; cljstyle-mode.el --- Reformat Clojure code using cljstyle

;; Author: Jeff Stokes (jeffecu88@gmail.com)
;; URL: https://github.com/jstokes/cljstyle-mode.el
;; Version: 0.1
;; Keywords: tools
;; Package-Requires: ((emacs "24.3"))

;; This file is NOT part of GNU Emacs.

;; cljstyle-mode.el is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; cljstyle-mode.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with cljstyle-mode.el.
;; If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Reformat Clojure code using cljstyle

;;; Code:

;;;###autoload
(defun cljstyle (&optional is-interactive)
  "Reformat code using cljstyle.
If region is active, reformat it; otherwise reformat entire buffer.
When called interactively, or with prefix argument IS-INTERACTIVE,
show a buffer if the formatting fails"
  (interactive)
  (let* ((p (point))
         (b (if mark-active (min p (mark)) (point-min)))
         (e (if mark-active (max p (mark)) (point-max)))
         (in-file (make-temp-file "cljstyle-in" nil ".clj"))
         (err-file (make-temp-file "cljstyle-err"))
         (output-buffer (get-buffer-create "*cljstyle-mode output*"))
         (contents (buffer-substring-no-properties b e))
         (cwd default-directory)
         (_ (with-temp-file in-file (insert contents))))

        (unwind-protect
          (let* ((error-buffer (get-buffer-create "*cljstyle-mode errors*"))
                 (retcode
                   (with-current-buffer output-buffer
                     (erase-buffer)
                     (let* ((default-directory cwd))
                           (call-process "cljstyle"
                                         in-file
                                         (list t err-file)
                                         nil
                                         "pipe")))))
                (with-current-buffer error-buffer
                  (read-only-mode 0)
                  (insert-file-contents err-file nil nil nil t)
                  (special-mode))
                (if (eq retcode 0)
                    (save-restriction
                      (delete-region b e)
                      (insert-buffer output-buffer)
                      (goto-char p))
                  (message "cljstyle applied")
                  (if is-interactive
                    (display-buffer error-buffer)
                    (message "cljstyle failed: see %s" (buffer-name error-buffer)))))
          (kill-buffer output-buffer)
          (delete-file in-file)
          (delete-file err-file))))


;;;###autoload
(define-minor-mode cljstyle-mode
  "Minor mode for reformatting Clojure code using cljstyle"
  :lighter " cljstyle"
  (if cljstyle-mode
    (add-hook 'before-save-hook 'cljstyle nil t)
    (remove-hook 'before-save-hook 'cljstyle t)))


(provide 'cljstyle-mode)

;;; cljstyle-mode.el ends here
