# Parser design

## Purpose

`kindle-highlights` reads the line-oriented `My Clippings.txt` format exported by Kindle devices and builds an index from book title to unique highlight text.

The parser is deliberately tolerant: malformed blocks and unsupported clipping types are ignored rather than causing the whole file to fail. This matches the reality of files accumulated across devices and Kindle software versions.

## Input grammar

At a high level, a clipping file is a sequence of blocks separated by a line whose trimmed value is exactly `==========`:

```
block := title metadata blank-lines content-lines
file  := block (separator block)*
```

The current implementation recognizes a block as a highlight when:

1. it has at least a title and metadata line;
2. the trimmed title is non-empty;
3. the metadata contains `Your Highlights`;
4. the remaining content is non-empty after trimming other whitespace.

Bookmarks, notes, empty highlights, short blocks, and other malformed input are ignored.

## Invariants

The parser maintains these invariants for every returned entry:

- `title` is non-empty and has no leading or trailing whitespace;
- `content` is non-empty and has no leading or trailing whitespace;
- entries retain their input order;
- a UTF-8 BOM is removed only from the beginning of the first input line;
- separator lines are structural and never become content;
- `build_lib` preserves de first occurrence of each quote for a book;
- parsing arbitrary strings does not raise an exception.

The public `Parser.parse_lines` function exposes parsed entries. `Parser.build_lib` then performs the separate indexing and stable de-duplication step. Keeping these steps separate makes the parser easier to test and gives callers a useful intermediate representation.

## Error policy

There is currently no error-reporting API. Invalid blocks are skipped. This is intentional for the command-line browsing use case: one malformed clipping should not hide all valid highlights in a fille.

If diagnostics are needed, a separate result-returning API could be added, rather than changing the tolerant API. For example, a future `parse_lines_with_diagnostics` could return valid entries plus source locations and skipped-block reasons.

## Performance 

Parsing is linear in the number of input lines. Index construction is linear in the number of parsed entries plus the cost of stable de-duplication. The `benchmark` Make target provides a repeatable baseline using a real clippings file:

```
make benchmark
```

The benchmakr is intentionally simple. It is for detecting accidental regressions, not for claiming a universal performance number across machines.
