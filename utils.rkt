#lang typed/racket/base

(provide
 revolutions->radians
 in-radius?
 freeze
 pin-over* pin-under*)

(require (for-syntax racket/base
                     syntax/parse)
         racket/math
         typed/pict)

;; math-y helper functions
;; ---------------------------------------------------------------------------------------------------

(: revolutions->radians (Float -> Float))
(define (revolutions->radians revs)
  (* revs 2 pi))

; Just a nice little helper function to check if two points are within a certain distance apart.
(: in-radius? (Float Float Float Float Float -> Boolean))
(define (in-radius? x1 y1 x2 y2 r)
  (let ([dx (- x1 x2)]
        [dy (- y1 y2)])
    (< (+ (* dx dx) (* dy dy)) (* r r))))

;; freeze -- renders to bitmaps then converts back to picts
;; ---------------------------------------------------------------------------------------------------

(: freeze (pict -> pict))
(define (freeze pict)
  (bitmap (pict->bitmap pict)))

;; pin-over* / pin-under*
;; ---------------------------------------------------------------------------------------------------

(define-syntax pin-over*-helper
  (syntax-rules ()
    [(_ base)
     base]
    [(_ base [dx dy pict] rest ...)
     (pin-over (pin-over*-helper base rest ...)
               dx dy pict)]))

(define-syntax pin-under*-helper
  (syntax-rules ()
    [(_ base)
     base]
    [(_ base [dx dy pict] rest ...)
     (pin-under (pin-under*-helper base rest ...)
                dx dy pict)]))

(define-syntax pin-over*
  (syntax-parser
    [(_ base clause ...)
     (with-syntax ([(reversed-clause ...) (reverse (syntax->list #'(clause ...)))])
       #'(pin-over*-helper base reversed-clause ...))]))

(define-syntax pin-under*
  (syntax-parser
    [(_ base clause ...)
     (with-syntax ([(reversed-clause ...) (reverse (syntax->list #'(clause ...)))])
       #'(pin-under*-helper base reversed-clause ...))]))
