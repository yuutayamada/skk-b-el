;;; -*- coding: utf-8; mode: emacs-lisp; -*-

(eval-when-compile (require 'cl))
(require 'skk-vars)
(require 'skk)

;; skk-henkan-mode
;; `on' であれば、▽モード。
;; `active' であれば、▼モード。
;; `nil' であれば、確定入力モード。

(defun skk-b (direction &optional fallback-function)
  (lexical-let*
      ((move-henkan-point
        (lambda (direction)
          (save-excursion
            (save-restriction
              (set-mark-command nil)
              (beginning-of-line)
              (narrow-to-region (point) (mark))
              (re-search-forward "[▽]" nil t)
              (case direction
                (:back    (backward-char 2))
                (:forward (forward-char  1)))
              (skk-set-henkan-point-subr)))))

       (move-henkan-point-fallback
        (lambda (direction)
          (case direction
            (:back    (backward-char))
            (:forward (forward-char)))
          (skk-set-henkan-point-subr)
          (when (equal direction :forward) (forward-char))))

       (change-state
        (case direction
          (:next-comp (skk-comp-wrapper)
                      (skk-j-mode-on))
          (:j-mode    (skk-j-mode-on))))

       (on-command
        (lambda (direction)
          (case direction
            ((:forward :back)
             (if (not (looking-at "▽"))
                 (funcall move-henkan-point direction)
               (funcall move-henkan-point-fallback direction)))
            (:j-mode    (funcall change-state direction))
            (:next-comp (funcall change-state direction)))))

       (active-command
        (lambda (direction)
          (case direction
            (:next        (skk-start-henkan 4))
            (:previous    (skk-previous-candidate))
            (:undo        (skk-undo))
            (:to-on-state (while (eq skk-henkan-mode 'active)
                            (skk-undo)))))))

    (case skk-henkan-mode
      (active (funcall active-command direction))
      (on     (funcall on-command     direction))
      (t      (if fallback-function
                  (funcall fallback-function))))))

(defun skk-b-dwim (active-func on-func &optional fallback)
  (when skk-mode
    (case skk-henkan-mode
      (active (skk-b active-func fallback))
      (on     (skk-b on-func     fallback))
      (t      :not-match))))

(defun skk-b-move-henkan-point-fwd ()
  (interactive)
  (skk-b-dwim :to-on-state :forward))

(defun skk-b-move-henkan-point-back ()
  (interactive)
  (skk-b-dwim :undo :back))

(defun skk-b-change-candidate-next ()
  (interactive)
  (skk-b-dwim :next :next-comp))

(defun skk-b-change-candidate-previous ()
  (interactive)
  (skk-b-dwim :previous :j-mode))

(provide 'skk-b)
