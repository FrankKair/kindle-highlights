open Base
open Kindle

let sample_lines =
  [
    "\u{feff}Book One";
    "- Your Highlight on page 1 | Location 10-12 | Added on...";
    "";
    "First quote line";
    "Second quote line";
    "==========";
    "Book One";
    "- Your Bookmark on page 4 | Location 20 | Added on...";
    "";
    "";
    "==========";
    "Book Two";
    "- Your Highlight on page 7 | Location 40-42 | Added on...";
    "";
    "Another quote";
    "==========";
    "Book Two";
    "- Your Highlight on page 7 | Location 40-42 | Added ...";
    "";
    "Another quote";
    "==========";
  ]

let test_books_are_sorted () =
  let lib = Bookshelf.build_from sample_lines in
  Alcotest.(check (list string))
    "books are sorted" [ "Book One"; "Book Two" ] (Bookshelf.books lib)

let test_quotes_for_book_one () =
  let lib = Bookshelf.build_from sample_lines in
  let actual =
    match Bookshelf.quotes lib "Book One" with
    | None -> []
    | Some quotes -> quotes
  in
  Alcotest.(check (list string))
    "book one quotes"
    [ "First quote line\nSecond quote line" ]
    actual

let test_quotes_are_duplicated () =
  let lib = Bookshelf.build_from sample_lines in
  let actual =
    match Bookshelf.quotes lib "Book Two" with
    | None -> []
    | Some quotes -> quotes
  in
  Alcotest.(check (list string))
    "book two deduplicated quotes" [ "Another quote" ] actual

let test_missing_book_returns_none () =
  let lib = Bookshelf.build_from sample_lines in
  Alcotest.(check bool)
    "missing book" true
    (Option.is_none (Bookshelf.quotes lib "Missing Book"))

let test_empty_input () =
  let lib = Bookshelf.build_from [] in
  Alcotest.(check (list string))
    "no books from empty input" [] (Bookshelf.books lib)

let () =
  Alcotest.run "kindle_highlights"
    [
      ( "bookshelf",
        [
          Alcotest.test_case "books are sorted" `Quick test_books_are_sorted;
          Alcotest.test_case "book one quotes" `Quick test_quotes_for_book_one;
          Alcotest.test_case "book two dedup" `Quick test_quotes_are_duplicated;
          Alcotest.test_case "missing book returns none" `Quick
            test_missing_book_returns_none;
          Alcotest.test_case "empty input" `Quick test_empty_input;
        ] );
    ]
