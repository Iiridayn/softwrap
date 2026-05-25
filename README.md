# Softwrap Vim Plugin

To install it, use your favorite vim plugin manager. I'm using `plug`, so I'd put `Plug 'Iiridayn/softwrap'` between `call plug#begin(…)` and `call plug#end()` in my `.vimrc`, save, then run `PlugInstall`.

Call it via `:Softwrap x` where x is the number of columns to wrap to; default 80. Disable via `:SoftwrapDisable`. Can update the wrap size by calling `:Softwrap x` again.

Relevant variables:
- `showbreak=\ \ ` or whatever - indent wrapped lines w/whatever prefix characters

Design decisions:
- Global, not per buffer. This is because `columns` is global, and we're already messing with it in a weird way. Best not to try to get too clever.
- Adds a fixed 4 for the gutter width; not worth updating the terminal width every time the gutter width changes (buffer swaps, lint errors, passing 99 or 999 lines, etc).
- Clears `textwidth` since that hard wraps. Clears `colorcolumn`, `cursorline` and `cursorcolumn` as they don't work well with `wrap`. Sets `linebreak` since it seems to work more consistently. Restores them on `:SoftwrapDisable` (or quit, to avoid polluting `.viminfo`).

Credit:
- [eborisch](https://stackoverflow.com/a/26284471/118153) for the basic idea
- [ThirstyMonkey](https://stackoverflow.com/a/70297773/118153) for the autocmd idea
- Iiridayn for realizing you can clear the screen by swapping to a blank scratch buffer
- Claude Sonnet 4.6 for helping write and debug this code
- Iiridayn for the documentation, comments, and guidance.

This probably breaks in all kinds of weird ways - feel free to open an issue so others are aware of weird behavior, and a PR if you'd like to share a fix.
