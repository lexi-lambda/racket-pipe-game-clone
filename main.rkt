#lang typed/racket

(require typed/pict
         typed/2htdp/universe
         "utils.rkt"
         "data.rkt"
         "shapes.rkt")

; The world only contains two fields, a grid of tile data and a map of tile offsets. The grid field
; contains all the information needed for the actual game logic—it contains information about where
; the tiles are as far as gameplay is concerned. The data in tile-offsets is simply used to make tile
; movement animated so it looks nicer for the player and so that tile motion is easier to track.
(struct world ([grid : Tile-Grid]
               [tile-offsets : Tile-Offsets]))

;; on-tick
;; ---------------------------------------------------------------------------------------------------

; Every tick, each tile offset is updated. If a tile is already fairly close to its actual position,
; it just gets snapped there. Otherwise, it's moved closer to its actual position by a factor scaled
; based on its distance away from that position. This creates an "easing" effect for the animation.
(: advance-tile-offset (Float -> Float))
(define (advance-tile-offset offset)
  (let* ([d (abs offset)]
         [o (* d 0.2)]) ; this controls the easing factor
    (if (< d 1) 0.0
      (* (sgn offset) (- d o)))))

; This consumes a map of all the tile offsets and applies advance-tile-offset to each value.
(: advance-tile-offsets (Tile-Offsets -> Tile-Offsets))
(define (advance-tile-offsets offsets)
  (for/hasheq ([(k v) offsets]) : Tile-Offsets
    (match-let ([(list x y) v])
      (values k (list (advance-tile-offset x)
                      (advance-tile-offset y))))))

; Currently, this just updates all the tile offsets on each tick.
(: world-tick (world -> world))
(define (world-tick state)
  (struct-copy world state
               [tile-offsets (advance-tile-offsets (world-tile-offsets state))]))

;; player input
;; ---------------------------------------------------------------------------------------------------

; The only mouse interactions we care about at the moment are presses.
(: handle-mouse-interaction (world Integer Integer String -> world))
(define (handle-mouse-interaction state mx my event)
  (case event
    [("button-down")
     (handle-mouse-down state mx my)]
    [else state]))

; A mouse press only matters if the click lands on one of the spinner buttons. If so, then it needs to
; pivot the relevant tiles in the grid in response.
(: handle-mouse-down (world Integer Integer -> world))
(define (handle-mouse-down state mx my)
  ; pivot the grid if necessary
  (define-values (new-grid new-offsets)
    (for/fold ([grid (world-grid state)]
               [offsets (world-tile-offsets state)])
              ([p (in-list spin-button-locations)]) : (Values Tile-Grid Tile-Offsets)
      (match-define (cons x y) p)
      (define-values (new-grid new-offsets)
        (if (in-radius? (exact->inexact mx)
                        (exact->inexact my)
                        (exact->inexact (* (add1 x) 64))
                        (exact->inexact (* (add1 y) 64))
                        16.0)
            (tile-grid-pivot grid x y)
            (values grid (ann (make-immutable-hasheq '()) Tile-Offsets))))
      (values new-grid (accumulate-tile-offsets offsets new-offsets))))
  ; update the state
  (struct-copy world state
               [grid new-grid]
               [tile-offsets new-offsets]))

;; rendering the scene
;; ---------------------------------------------------------------------------------------------------

; Converting a world to a renderable scene is easy since almost all of the rendering is performed
; in tile-grid->pict. Once the tile grid is rendered, this also overlays the spinner buttons on top.
(: world->pict (world -> pict))
(define (world->pict state)
  (match-let ([(world grid offsets) state])
    (overlay-spin-buttons (tile-grid->pict grid offsets))))

; This is a constant value calculated for ease of use in for loops for getting at the locations
; of the spinner buttons.
(define spin-button-locations
  (for*/list ([x (in-range 5)]
              [y (in-range 5)]) : (Listof (Pairof Integer Integer))
    (cons x y)))

; The spin buttons are really just a constant overlay. They could be frozen into a static bitmap
; image, but theoretically they should eventually animate in response to user input.
(: overlay-spin-buttons (pict -> pict))
(define (overlay-spin-buttons grid)
  (for/fold ([grid grid])
            ([p (in-list spin-button-locations)])
    (match-define (cons x y) p)
    (pin-over
     grid
     (+ 48 (* x 64)) (+ 48 (* y 64))
     spin-button)))

;; ---------------------------------------------------------------------------------------------------

(big-bang
 (world starting-tile-grid (make-immutable-hasheq '())) : world
 [name "WIP Game Clone"]
 [to-draw (λ ([state : world]) (pict->bitmap (world->pict state)))]
 [on-tick world-tick 1/30]
 [on-mouse handle-mouse-interaction])
