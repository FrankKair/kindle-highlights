## kindle-highlights

See your Kindle highlights in your terminal.

## Setup

Requires [opam](https://opam.ocaml.org/doc/Install.html) and OCaml 5.0+.

```bash
opam install . --deps-only --with-test
```

For the best experience, install [fzf](https://github.com/junegunn/fzf) for fuzzy book selection. If `fzf` is not available, the CLI falls back to a numered list prompt.

## Usage

```bash
dune exec kindle_highlights -- "My Clippings.txt"
```

The CLI will:
- Parse your clippings file;
- Show a sorted list of books that contain highlights;
- Print highlights for the selected book.

## Notes

- Input is expected to follow Kindle's `==========` block format;
- Bookmarks are ignored; only highlights are extracted;
- Highlight content can span multiple lines;
- UTF-8 BOM at the beginning of the file is handled;
- Duplicate highlights are deduplicated;
- Malformed blocks are skipped.
