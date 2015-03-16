#lang typed/racket/base

(require racket/vector
         racket/function
         racket/match
         typed/pict
         "constants.rkt"
         "utils.rkt"
         "shapes.rkt")

(provide
 (struct-out tile)
 Tile-Grid Tile-Offsets
 tile->pict
 starting-tile-grid
 accumulate-tile-offsets
 tile-grid-pivot
 tile-grid->pict)

;; tile data
;; ---------------------------------------------------------------------------------------------------

(struct tile ([type : (U 'l 'i)]
              [rotation : Integer]
              [color : (U 'grey 'red 'green 'yellow)])
  #:transparent)

; cache the bitmaps to prevent recalculating them every frame
(define tile-cache : (HashTable tile pict)
  (make-hash '()))

; Converting a tile type to a pict is easy—just look up the appropriate shape.
(define (tile-type->pict [t : (U 'l 'i)])
  (case t
    [(l) pipe-l]
    [(i) pipe-i]))

; Each integral "rotation" is equivalent to a 90º spin.
(define (tile-rotation->radians [t : Float])
  (revolutions->radians (* 1/4 t)))

; Tile color lookups are similarly straightforward.
(define (tile-color->color [t : (U 'grey 'red 'yellow 'green)])
  (case t
    [(grey)   pipe-color-grey]
    [(red)    pipe-color-red]
    [(yellow) pipe-color-yellow]
    [(green)  pipe-color-green]))

; Converting a tile to a pict simply grabs the appropriate graphic, colors it, rotates it, and
; overlays it atop the generic tile base. Tile graphics are cached to avoid recalculation.
(define (tile->pict [t : tile])
  (hash-ref!
   tile-cache t
   (λ ()
     (match-define (tile type rotation color) t)
     (freeze
      (clip
       (pin-over
        tile-base
        0 0
        (colorize (rotate (tile-type->pict type)
                          (tile-rotation->radians (exact->inexact rotation)))
                  (tile-color->color color))))))))

;; tile grid
;; ---------------------------------------------------------------------------------------------------

; A Tile-Grid is simply a vector of length 36 containing tile data.
(define-type Tile-Grid (Vectorof tile))
; A Tile-Offsets map contains information about how tile move around the grid. This data needs to be
; exposed by the data layer so that the rendering layer can perform animation.
(define-type Tile-Offsets (HashTable tile (List Float Float)))

; The initial tile grid is hardcoded. It could be procedurally generated, but for now, it's easier
; to just hardcode things to avoid needing to tune the algorithm.
(define starting-tile-grid : Tile-Grid
  (vector-immutable
   (tile 'l 0 'green)  (tile 'l 1 'grey)   (tile 'l 3 'red)   (tile 'i 0 'yellow) (tile 'i 1 'grey)   (tile 'l 3 'red)
   (tile 'i 1 'grey)   (tile 'l 1 'red)    (tile 'l 3 'grey)  (tile 'l 0 'red)    (tile 'i 0 'red)    (tile 'l 3 'yellow)
   (tile 'i 1 'grey)   (tile 'l 0 'yellow) (tile 'l 1 'green) (tile 'l 2 'yellow) (tile 'l 1 'green)  (tile 'l 2 'grey)
   (tile 'l 2 'green)  (tile 'i 0 'green)  (tile 'i 0 'red)   (tile 'i 1 'green)  (tile 'i 0 'yellow) (tile 'l 0 'grey)
   (tile 'l 1 'yellow) (tile 'l 3 'red)    (tile 'l 0 'grey)  (tile 'i 0 'green)  (tile 'i 1 'grey)   (tile 'i 0 'green)
   (tile 'l 3 'green)  (tile 'i 1 'yellow) (tile 'i 1 'red)   (tile 'i 0 'red)    (tile 'i 0 'yellow) (tile 'l 0 'yellow)))

; Simply converts (x, y) coordinates to linear coordinates. This is easy since the grid is a fixed
; size.
(: tile-grid-point->index (Integer Integer -> Integer))
(define (tile-grid-point->index x y)
  (+ x (* y 6)))

; This adds two sets of tile offsets together via simple addition.
(: accumulate-tile-offsets (Tile-Offsets Tile-Offsets -> Tile-Offsets))
(define (accumulate-tile-offsets offsets new-offsets)
  (for/fold ([offsets offsets])
            ([(tile new-offset) new-offsets])
    (match-let* ([(list new-x new-y) new-offset]
                 [(list old-x old-y) (hash-ref offsets tile (thunk '(0 0)))])
      (hash-set offsets tile (list (+ old-x new-x) (+ old-y new-y))))))

; Pivots tiles around in a clockwise motion. The pivot location is the lower right corner of the tile
; at the provided x and y coordinates.
; It returns the new tile grid as well as hash table of the tiles and their old positions in
; pixel offsets relative to their new positions (this is used for animation).
(: tile-grid-pivot (Tile-Grid Integer Integer -> (Values Tile-Grid Tile-Offsets)))
(define (tile-grid-pivot tg px py)
  (define new-grid (vector-copy tg))
  ; first get the indicies...
  (let ([ai (tile-grid-point->index px        py)]
        [bi (tile-grid-point->index (add1 px) py)]
        [ci (tile-grid-point->index (add1 px) (add1 py))]
        [di (tile-grid-point->index px        (add1 py))])
    ; then get the values...
    (let ([a (vector-ref tg ai)]
          [b (vector-ref tg bi)]
          [c (vector-ref tg ci)]
          [d (vector-ref tg di)])
      ; then rotate them...
      (vector-set! new-grid ai d)
      (vector-set! new-grid bi a)
      (vector-set! new-grid ci b)
      (vector-set! new-grid di c)
      ; and finally, make the result immutable and return the offset information
      (values (vector->immutable-vector new-grid)
              (make-immutable-hasheq `((,a . (-64.   0.))
                                       (,b . (  0. -64.))
                                       (,c . ( 64.   0.))
                                       (,d . (  0.  64.))))))))

; Converts a tile grid and a table of tile offsets to a renderable pict.
(: tile-grid->pict (Tile-Grid Tile-Offsets -> pict))
(define (tile-grid->pict tg offsets)
  ; we start with a completely blank board and overlay tiles on top
  (for/fold ([board (blank (* 64 6) (* 64 6))])
            ([tile (in-vector tg)]
             [i (in-naturals)])
    ; the actual x and y coordinates can be derived from the linear index
    (match-let-values ([(y x) (quotient/remainder i 6)]
                       [((list o-x o-y)) (hash-ref offsets tile (thunk '(0 0)))])
      ; the result is the tile composited onto the board with offsets taken into account
      (pin-over board
                (+ (* x 64) o-x) (+ (* y 64) o-y)
                (tile->pict tile)))))
