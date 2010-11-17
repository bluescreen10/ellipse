;; Globals
(setq ellipse-config-file "~/.ellipse-settings")
(setq projects)
(setq ellipse-settings-modified-date 0)

;; Set Major mode hooks
;; Perl
(add-hook 'cperl-mode-hook
          (lambda ()
            (local-set-key "\C-xt" 'pretty-print-perl)
            (setup-project)))

;; XML
(add-hook 'nxml-mode-hook
          (lambda ()
            (local-set-key "\C-xt" 'pretty-print-xml)))
            

;; Java
(add-hook 'jde-mode-hook  
          (lambda ()
            (local-set-key "\C-xt" 'pretty-print-java)
            (setup-project)))

;; C
(add-hook 'c-mode-hook  
          (lambda ()
            (local-set-key "\C-xt" 'pretty-print-c)
            (setup-project)))


;; General functions

(defun setup-project()
  """ Set the project tools and variables
  """
  (let ((project (find-project (buffer-file-name))))
        (let ((home (plist-get project ':home))
              (name (plist-get project ':name))
              (tags (project-get-tags-file mode-name (plist-get project ':name))))

          ;; Project general settings
          (make-local-variable 'project-settings)
          (setq project-settings project)

          ;; TAGS
          (make-local-variable 'tags-file-name)
          (setq tags-file-name tags)

          ;; Grep in workspace
          (make-local-variable 'workspace-dir)
          (setq workspace-dir (file-truename home))))))

(defun find-project(filename)
  """ Search thourght projects listed in ~/.ellipse-settings and
      find the matching project according to buffer's locaton
  """
  (let ((mdate (float-time (nth 5 (file-attributes project-config-file)))))
    (if (> mdate ellipse-settings-modified-date)
        (progn
          (setq ellipse-settings-modified-date mdate )
          (setq projects)
          (load ellipse-config-file))))
  (let ((index 0)
        (number-of-projects (length projects))
        (current-project nil))
    (while (< index number-of-projects)
      (let ((project (nth index projects)))
        (when (string-match (file-truename (plist-get project ':home)) filename)
          (setq current-project project))
        (setq index (+ index 1))))
    current-project))

(defun project-map-mode-to-language(mode)
  " Maps mode-name to etags languaje"
  (cond ((string= mode "CPerl") '"Perl")
        ((string= mode "JDE") '"Java")
        ((string= mode "C/l") '"C")))


;; ETAGS
;; The various functions to regenerate tags table

(defun project-get-tags-file( type name )
  "Return the project's tags table"
  (file-truename (concat "~/.ellipse/" name "-" type ".TAGS")))


;; find
(defun tags-vc-hook(command file flags)
  "regenerate tags on repository updates"
  (regenerate-tags))

(defun regenerate-tags()
  "regenerate etags for each language"
  (if (boundp 'project-settings)
      (let ((tags (project-get-tags-file mode-name (plist-get project-settings ':name)))
            (home (file-truename (plist-get project-settings ':home)))
            (language (project-map-mode-to-language mode-name)))
        (start-process "refresh-tags" "*etags*" "etags" "--recurse=yes" (concat "--languages=" language) "-f" tags home))))

(add-hook 'after-save-hook 'regenerate-tags)

;;init
(unless (file-exists-p "~/.ellipse")
  (make-directory "~/.ellipse"))

;; Pretty print
;; The various functions used to beautify the different languages

;; XML
(defun pretty-print-xml ()
  """ Pretty format XML markup in region. You need to have nxml-mode
      http://www.emacswiki.org/cgi-bin/wiki/NxmlMode installed to do
      this.  The function inserts linebreaks to separate tags that have
      nothing but whitespace between them.  It then indents the markup
      by using nxml's indentation rules.
  """
  (interactive)
  (let ((begin (if mark-active (point) (point-min)))
        (end   (if mark-active (mark) (point-max))))
    (save-excursion
      (nxml-mode)
      (goto-char begin)
      (while (search-forward-regexp "\>[ \\t]*\<" nil t)
        (backward-char) (insert "\n"))
      (indent-region begin end))))

;; Perl
;; From: http://www.perlmonks.org/index.pl?node_id=380724
;; 
;; Put this in your ~/.emacs file, select the region you
;; want to clean up and type C-xt or M-x perltidy-region.
(defun pretty-print-perl ()
  "Run perltidy on the current region or the whole buffer."
  (interactive)
  (save-excursion
    (let ((beg (if mark-active (point) (point-min)))
          (end (if mark-active (mark) (point-max)))) 
      (shell-command-on-region beg end "perltidy -q" nil t))))

;; Java
(defun pretty-print-java ()
  "Run uncrustify on the current region or the whole buffer."
  (interactive)
  (save-excursion
    (let ((beg (if mark-active (point) (point-min)))
          (end (if mark-active (mark) (point-max)))) 
      (shell-command-on-region beg end "uncrustify -q -l java -c ~/.uncrustify" nil t))))

;; C
(defun pretty-print-c ()
  "Run uncrustify on the current region or the whole buffer."
  (interactive)
  (save-excursion
    (let ((beg (if mark-active (point) (point-min)))
          (end (if mark-active (mark) (point-max)))) 
      (shell-command-on-region beg end "uncrustify -q -l c -c ~/.uncrustify" nil t))))

;;
;; Grep and Locate in workspace
;;

;; Grep
(grep-compute-defaults)
(defvar workspace-dir '"~")
(defun grep-in-workspace (pattern)
  "Run `rgrep' in all files of `wokspace-dir' for the given PATTERN."
  (interactive "sGrep pattern: ")
  (rgrep pattern "*" workspace-dir))

(global-set-key "\C-xgs" 'grep-in-workspace)

;; Locate
(defun locate-in-workspace (pattern)
  "Run `locate' in `workspace-dir'."
  (interactive "sFilename wildcard: ")
  (locate pattern workspace-dir))

(global-set-key "\C-xgl" 'locate-in-workspace)