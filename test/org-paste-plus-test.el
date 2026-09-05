;;; org-paste-plus-test.el --- Tests for org-paste-plus -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)
(add-to-list 'load-path (expand-file-name ".." (file-name-directory load-file-name)))
(require 'org-paste-plus)

(ert-deftest org-paste-plus-wsl-image-command-uses-windows-temp-file ()
  (cl-letf (((symbol-function 'org-paste-plus--wsl-p) (lambda () t)))
    (let* ((system-type 'gnu/linux)
           (default-directory "/tmp/")
           (org-paste-plus-clipboard-command nil)
           (command (org-paste-plus--clipboard-command "notes.assets/img.png")))
      (should (string-match-p
               "powershell\\.exe -Sta -NoProfile -Command"
               command))
      (should (string-match-p "Get-Clipboard" command))
      (should (string-match-p "ImageFormat" command))
      (should (string-match-p "wslpath" command))
      (should (string-match-p
               (regexp-quote "/tmp/notes.assets/img.png")
               command)))))

(ert-deftest org-paste-plus-wsl-file-command-uses-windows-clipboard ()
  (cl-letf (((symbol-function 'org-paste-plus--wsl-p) (lambda () t)))
    (let ((system-type 'gnu/linux)
          (org-paste-plus-clipboard-file-command nil))
      (let ((expected
             (format
              "powershell.exe -Sta -NoProfile -Command %s"
              (shell-quote-argument
               "$f = Get-Clipboard -Format FileDropList -ErrorAction SilentlyContinue; if ($f) { $f[0].FullName }"))))
        (should (equal (org-paste-plus--clipboard-file-command)
                       expected))))))

(ert-deftest org-paste-plus-wsl-path-converts-windows-path ()
  (let ((windows-path "D:\\screenshots\\shot.png"))
    (cl-letf (((symbol-function 'org-paste-plus--wsl-p) (lambda () t))
              ((symbol-function 'executable-find)
               (lambda (program)
                 (and (equal program "wslpath") "/usr/bin/wslpath")))
              ((symbol-function 'shell-command-to-string)
               (lambda (command)
                 (should (equal command
                                (format "wslpath -u %s"
                                        (shell-quote-argument windows-path))))
                 "/mnt/d/screenshots/shot.png\n")))
      (should (equal (org-paste-plus--wsl-path windows-path)
                     "/mnt/d/screenshots/shot.png")))))

(ert-deftest org-paste-plus-linux-image-command-still-uses-xclip ()
  (cl-letf (((symbol-function 'org-paste-plus--wsl-p) (lambda () nil)))
    (let ((system-type 'gnu/linux)
          (org-paste-plus-clipboard-command nil))
      (should (equal
               (org-paste-plus--clipboard-command "img.png")
               "xclip -selection clipboard -t image/png -o > img.png")))))

;;; org-paste-plus-test.el ends here
