#lang at-exp racket/base

(module+ test
  (require rackunit))

;; Notice
;; To install (from within the package directory):
;;   $ raco pkg install
;; To install (once uploaded to pkgs.racket-lang.org):
;;   $ raco pkg install <<name>>
;; To uninstall:
;;   $ raco pkg remove <<name>>
;; To view documentation:
;;   $ raco docs <<name>>
;;
;; For your convenience, we have included LICENSE-MIT and LICENSE-APACHE files.
;; If you would prefer to use a different license, replace those files with the
;; desired license.
;;
;; Some users like to add a `private/` directory, place auxiliary files there,
;; and require them in `main.rkt`.
;;
;; See the current version of the racket style guide here:
;; http://docs.racket-lang.org/style/index.html

;; Code here




(require racket/list
         racket/string
         racket/format
         gregor
         timable/gregor
         scribble/core
         scribble/base)

(provide (all-defined-out))

(define (post-url str)
  (define lst (string-split str "-"))
  (define name (string-join (drop lst 3) "-"))
  (hyperlink @~a{/@(first lst)/@(second lst)/@|name|.html} name))

(define (title . text)
  (list* "Title: " text))

(define (date . text)
  (list "Date: " (datetime->iso8601 (parse/datetime (car text)))))

(define (tags . text)
  (list "Tags: " (string-join (string-split (car text)) ", ")))

(define (meta . text)
  (let* ([lst (string-split (string-join text) "\n" #:trim? #t)]
         [title (first lst)]
         [date (datetime->iso8601 (parse/datetime (second lst)))]
         [tags (string-join (string-split (third lst)) " ,")])
    (list "Title: " title "\n"
          "Date: " date "\n"
          "Tags: " tags)))


(define (essay . text)
  (let* ([seperator1 (index-of text "\n")]
          [lst1 (take text seperator1)]
          [lst1r (drop text (add1 seperator1))]
          [seperator2 (index-of lst1r "\n")]
          [lst2 (take lst1r seperator2)]
          [lst2r (drop lst1r (add1 seperator2))])
    (list (element 'bold (element 'larger lst1))
          "\n"
          (element 'smaller (flatten (list "(" lst2 ")")))
          (element 'newline '())
          (map (lambda (i)
                  (if (eq? i "\n")
                      (element 'newline '())
                      i))
                lst2r))))


(module+ test
  ;; Any code in this `test` submodule runs when this file is run using DrRacket
  ;; or with `raco test`. The code here does not run when this file is
  ;; required by another module.

  #;(check-equal? (+ 2 2) 4))

(module+ main
  ;; (Optional) main submodule. Put code here if you need it to be executed when
  ;; this file is run using DrRacket or the `racket` executable.  The code here
  ;; does not run when this file is required by another module. Documentation:
  ;; http://docs.racket-lang.org/guide/Module_Syntax.html#%28part._main-and-test%29

  (require racket/cmdline
           raco/command-name
           racket/system
           racket/file
           gregor)

  (define (strip-iso8601-nanoseconds str)
    (define segments (string-split str "."))
    (car segments))

  (define command (make-parameter #f))
  (define post-title (make-parameter #f))
  (define skip-frog-check? (make-parameter #f))
  (define make-missing-directories? (make-parameter #f))

  (command-line
   #:program (short-program+command-name)
   #:once-any ; only one command at a time
   [("-N" "--new-scribble")
    title
    "your title name of the new post"
    (command 'new-scribble-post)
    (post-title title)]
   #:once-each ; flags
   [("-f" "--force")
    "Skip checks that we are in a valid frog or darwin blog"
    (skip-frog-check? #t)
    (make-missing-directories? #t)])

  (case (command)
    [(new-scribble-post)
     (unless (skip-frog-check?)
       (or (file-exists? (build-path (current-directory) "frog.rkt"))
           (file-exists? (build-path (current-directory) "darwin.rkt"))
           (error "`frog.rkt` or `darwin.rkt` not found, you may want to run `raco frog --init` first.")))
     (define filename @string-append{_src/posts/@|(date->iso8601 (current-date))|-@|(post-title)|.scrbl})
     (define filepath (build-path (current-directory) filename))
     (when (make-missing-directories?)
       (let-values ([(base name must-be-dir?) (split-path filepath)])
         (make-directory* base)))
     (and (file-exists? filepath)
          (error (~a "file already exist: " filepath)))
     (define filecontent @~a{#lang scribble/manual

                             @"@"(require scribble-frog-helper)
                             @"@"(require (for-label racket)) @"@"; remove this line if no racket doc links needed

                             @"@"title{@(post-title)}
                             @"@"date{@(strip-iso8601-nanoseconds (datetime->iso8601 (now)))}
                             @"@"tags{DRAFT tag1 tag2}


                             Replace this with your post text. Add one or more comma-separated
                             Tags above. The special tag `DRAFT` will prevent the post from being
                             published. And text before the `more` line will appear in the post
                             index page as well.

                             <!-- more -->

                             @"@"(table-of-contents) @"@"; remove this line if no toc neeeded.

                             You blog content continues here.
                             })
     (display-to-file filecontent filepath)
     (displayln filepath)]))
