open Base
open Kindle

let test_parse_highlight_block () =
  let highlight_block =
    [
      "Book Parser";
      "- Your Highlight on page 1 | Location 1-2 | Added on...";
      "";
      "Line one";
      "Line two";
    ]
  in
  match Parser.parse_block highlight_block with
  | None -> Alcotest.fail ""
  | Some (title, content) ->
      Alcotest.(check string) "title" "Book Parser" title;
      Alcotest.(check string) "content" "Line one\nLine two" content

let test_parse_bookmark_block_is_ignored () =
  let bookmark_block =
    [
      "Book Parser";
      "- Your Bookmark on page 9 | Location 100 | Added on ...";
      "";
    ]
  in
  Alcotest.(check bool)
    "bookmark ignored" true
    (Option.is_none (Parser.parse_block bookmark_block))

let test_build_lib_deduplicates_quotes () =
  let duplicated_input =
    [
      "Book A";
      "- Your Highlight on page 1 | Location 10-10 | Added on...";
      "";
      "Same quote";
      "==========";
      "Book A";
      "- Your Highlight on page 1 | Location 10-10 | Added on...";
      "";
      "Same quote";
      "==========";
    ]
  in
  let parsed = Parser.build_lib ~from:duplicated_input in
  match Map.find parsed "Book A" with
  | None -> Alcotest.fail "Book A should exist"
  | Some quotes ->
      Alcotest.(check (list string))
        "deduplicated quotes" [ "Same quote" ] quotes

let test_parse_block_with_empty_content () =
  let block =
    [
      "Book Empty";
      "- Your Highlight on page 1 | Location 1-2 | Added on...";
      "";
      "";
    ]
  in
  Alcotest.(check bool)
    "empty content returns None" true
    (Option.is_none (Parser.parse_block block))

let test_parse_block_with_single_line () =
  let block =
    [
      "Book Single";
      "- Your Highlight on page 5 | Location 20-20 | Added on...";
      "";
      "Just one line";
    ]
  in
  match Parser.parse_block block with
  | None -> Alcotest.fail "Single-line highlight should parse"
  | Some (title, content) ->
      Alcotest.(check string) "title" "Book Single" title;
      Alcotest.(check string) "content" "Just one line" content

let test_parse_block_too_short () =
  let block = [ "Only a title" ] in
  Alcotest.(check bool)
    "short block returns None" true
    (Option.is_none (Parser.parse_block block))

let test_build_lib_empty_input () =
  let parsed = Parser.build_lib ~from:[] in
  Alcotest.(check int) "empty input yields empty map" 0 (Map.length parsed)

let test_build_lib_only_bookmarks () =
  let input =
    [
      "Book A";
      "- Your Bookmark on page 1 | Location 10 | Added on ...";
      "";
      "==========";
      "Book B";
      "- Your Bookmark on page 5 | Location 50 | Added on ...";
      "";
      "==========";
    ]
  in
  let parsed = Parser.build_lib ~from:input in
  Alcotest.(check int) "bookmarks-only yields empty map" 0 (Map.length parsed)

let test_build_lib_strips_bom () =
  let input =
    [
      "\u{feff}BOM Book";
      "- Your Highlight on page 1 | Location 1-1 | Added on...";
      "";
      "Quote from BOM book";
      "==========";
    ]
  in
  let parsed = Parser.build_lib ~from:input in
  Alcotest.(check bool) "" true (Option.is_some (Map.find parsed "BOM Book"))

let () =
  Alcotest.run "parser"
    [
      ( "parser",
        [
          Alcotest.test_case "parse highlight" `Quick test_parse_highlight_block;
          Alcotest.test_case "ignore bookmark" `Quick
            test_parse_bookmark_block_is_ignored;
          Alcotest.test_case "empty content" `Quick
            test_parse_block_with_empty_content;
          Alcotest.test_case "single-line highlight" `Quick
            test_parse_block_with_single_line;
          Alcotest.test_case "too-short block" `Quick test_parse_block_too_short;
          Alcotest.test_case "deduplicate in build_lib" `Quick
            test_build_lib_deduplicates_quotes;
          Alcotest.test_case "empty input" `Quick test_build_lib_empty_input;
          Alcotest.test_case "only bookmarks" `Quick
            test_build_lib_only_bookmarks;
          Alcotest.test_case "BOM stripping" `Quick test_build_lib_strips_bom;
        ] );
    ]
