#lang racket/base

(provide
 pipe-color-grey pipe-color-red pipe-color-yellow pipe-color-green
 tile-color-bg tile-color-fg)

(require
  racket/class
  racket/draw)

;; color constants
;; ---------------------------------------------------------------------------------------------------

(define pipe-color-grey (make-object color% 153 153 153))
(define pipe-color-red (make-object color% 240 0 0))
(define pipe-color-yellow (make-object color% 194 184 46))
(define pipe-color-green (make-object color% 19 142 43))

(define tile-color-bg (make-object color% 67 107 147))
(define tile-color-fg (make-object color% 25 34 65))
