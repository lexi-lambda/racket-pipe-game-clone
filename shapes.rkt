#lang racket/base

(provide
 pipe-l pipe-i
 tile-base
 spin-button)

(require
  pict
  "constants.rkt"
  "utils.rkt")

;; "pipe" graphics -- pipes come in two shapes, I and L
;; ---------------------------------------------------------------------------------------------------

(define pipe-l
  (pin-over* (blank 64 64)
             [24  0 (filled-rectangle 16 32)]
             [ 0 24 (filled-rectangle 32 16)]
             [24 24 (disk 16)]))

(define pipe-i
  (pin-over* (blank 64 64)
             [24 0 (filled-rectangle 16 64)]))

;; other graphics
;; ---------------------------------------------------------------------------------------------------

; This is simply the background that at tiles are rendered on.
(define tile-base
  (freeze
   (pin-over* (colorize (filled-rectangle 64 64) tile-color-bg)
              [2 2 (colorize (filled-rectangle 60 60) tile-color-fg)])))

; This is a button (currently pretty lackluster) that serves as a target to pivot the tiles on the
; grid.
(define spin-button
  (freeze (cellophane (colorize (disk 32) "white") 0.25)))
