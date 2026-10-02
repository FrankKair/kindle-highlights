## kindle-highlights

[![CI](https://github.com/FrankKair/kindle-highlights/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/FrankKair/kindle-highlights/actions/workflows/ci.yml)

See your Kindle highlights in your terminal.

## Setup

Requires [opam](https://opam.ocaml.org/doc/Install.html) and OCaml 5.0+.

```
opam install . --deps-only --with-test
```

For the best experience, install [fzf](https://github.com/junegunn/fzf) for fuzzy book selection. If `fzf` is not available, the CLI falls back to a numbered list prompt.

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
highlights. Both commands show a sorted list of books and print highlights for
the selected book. Without a saved library, the browse command explains how to
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

## Notes

- Input is expected to follow Kindle's `==========` block format;
- Bookmarks are ignored; only highlights are extracted;
- Highlight content can span multiple lines;
- UTF-8 BOM at the beginning of the file is handled;
- Duplicate highlights are deduplicated;
- Malformed blocks are skipped.

## Development

```
make test
make load FILE="/path/to/My Clippings.txt"
make run
make benchmark FILE=/path/to/clippings.txt
make fmt
```

The parser design, input grammar, invariants, error policy, and performance notes are documented in [`PARSER_DESIGN.md`](PARSER_DESIGN.md). The test suite includes focused malformed-input cases and property-based tests over arbitrary line lists. The benchmark runs the parser repeatedly against a clippings file so parser changes can be compared on the same input.
