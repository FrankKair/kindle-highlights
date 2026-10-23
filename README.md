## kindle-highlights

[![CI](https://github.com/FrankKair/kindle-highlights/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/FrankKair/kindle-highlights/actions/workflows/ci.yml)

See your Kindle highlights in your terminal.

## Setup

Requires [opam](https://opam.ocaml.org/doc/Install.html), OCaml 5.0+,
[fzf](https://github.com/junegunn/fzf) for book selection, and `less` for reading
highlights. Both `fzf` and `less` must be available on your `PATH`.

```
opam install . --deps-only --with-test
```

## Usage

Load highlights while the Kindle is connected:

```
dune exec kindle_highlights -- load "/path/to/My Clippings.txt"
```

Browse them later without the clippings file:

```
dune exec kindle_highlights
```

The `load` command replaces the saved library, including when the file has no
highlights. Both commands show a sorted list of books in `fzf`. Each book has its
unique highlight count displayed before its title, for example
`[24] Piranesi (Susanna Clarke)`.

Select a book to read its highlights in `less`, with the book title as a heading.
Use the arrow keys to scroll or `/` to search. Press `q` to return to the book
selector and choose another book without restarting the program. Press `Esc` in
the selector to exit quietly. Browsing requires `fzf`; there is no numbered-list
fallback.

Without a saved library, the browse command explains how to
load one.

Saved highlights live at `$XDG_DATA_HOME/kindle-highlights/library.sexp` when
`XDG_DATA_HOME` is set, or `~/.local/share/kindle-highlights/library.sexp`
otherwise.

## How it fits together

```text
load FILE:
  clippings file -> Parser.parse_lines -> entries -> Store.save -> library.sexp
                                           |
                                           +-> Bookshelf.of_entries -> selector

no arguments:
  library.sexp -> Store.load -> entries -> Bookshelf.of_entries -> selector
```

The parser handles clipping syntax. The store saves and loads parsed entries.
The bookshelf builds a title-to-quotes index for browsing.
The selector uses `fzf` to choose a book; its highlights are written to a
temporary file for `less`. The file is deleted when the pager exits, and book
selection repeats until cancelled.

## Notes

- Input is expected to follow Kindle's `==========` block format;
- Bookmarks are ignored; only highlights are extracted;
- Highlight content can span multiple lines;
- UTF-8 BOM at the beginning of the file is handled;
- Duplicate highlights are deduplicated;
- Malformed blocks are skipped.

## Development

Use any opam switch with OCaml 5.0 or later. In your selected switch:

```sh
eval $(opam env)
opam install . --deps-only --with-test
opam install ocamlformat
```

```
make test
make load FILE="/path/to/My Clippings.txt"
make run
make benchmark FILE=/path/to/clippings.txt
make fmt
```

The parser design, input grammar, invariants, error policy, and performance notes are documented in [`PARSER_DESIGN.md`](PARSER_DESIGN.md). The test suite includes focused malformed-input cases and property-based tests over arbitrary line lists. The benchmark runs the parser repeatedly against a clippings file so parser changes can be compared on the same input.
