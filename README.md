
# pipe-game-clone

This is a "game". It's not really a game—you can't actually play it and win, lose, or even get any sort of score. It *is* interactive, though, and it's something of a proof-of-concept I've tried out to see what writing a simple game in a purely functional style would be like.

This is a partial clone of a game currently in development by [Natalie Frost](http://natalie-games.itch.io/). I do not take credit for any of the concepts or artwork.

## Running the game

The main file to run is `main.rkt`. You will need to be running at least Racket version 6.1.1.8, which is only available as a snapshot build as of this writing. This uses some Typed Racket features such as the object system and improved pict support that are not available in 6.1.1 or earlier.

This also depends on the `2htdp-typed` package (which is my own), which is included as a dependency in the `info.rkt` file. Installing this repository as a package will automatically install the required dependency.

## The philosophy of this project

I laid out a couple of guidelines for myself when working on this.

  1. **There is no mutable state.** None at all. The game is written in a purely functional style. This does mean, unfortunately, doing a lot of unnecessary copying which Racket can almost certainly *not* optimize out—it's not that clever. That said, the game should still be performant considering its simplicity.
  2. **There are no external assets.** All of the graphics for the game are generated entirely at runtime. In this case, I decided to use Racket's pict library, which is fairly fully-featured and suited my needs.
  3. **Code is modular and decoupled.** This is a sort of silly goal since this project is so small, anyway. There are really only two files that do anything serious, and they definitely have some non-trivial coupling between them. Still, I think the code can be understand in independent units, and I think it's flexible enough to modify parts of the system without breaking the rest of it.
  4. **All the logic is expressive!** This is really the end goal, which should be the result of the above points. I think Racket is a very expressive language, and I want to let that shine through while still making a semi-performant game.

## Game structure

This project contains three relatively small utility modules which are used by the two main logic modules.

The helper modules include `constants`, `shapes`, and `utils`.

- `constants.rkt` simply includes constants used by the game, currently only colors.
- `shapes.rkt` *also* provides constants, but it includes the shape primitives that are composed in other parts of the program to make the final graphical output.
- `utils.rkt` includes a couple utility functions and some macros for making working with picts nicer.

The other two files contain the game itself.

- `data.rkt` includes functions for initializing the game and interacting with the tile grid. It also handles rendering the tiles and tile grid, though without any logic or additional UI.
- `main.rkt` manages game state, user input, and general world rendering. It's the main entry point, and it calls `big-bang`.

All the code should be comprehensively documented in the comments.

## Existing known issues

- The "game" is obviously incomplete. This is sort of a secondary problem (since I'm not making this for the purpose of playing it), but I should probably reiterate it for clarity's sake.
- There are recurring, rather noticeable lag spikes. These lag spikes can last up to a couple of seconds at a time, and they seem to happen at random intervals. The most obvious explanation for these would be GC, especially considering the amount of allocation being performed by the constant copying of values, but I'm not entirely sure yet.
