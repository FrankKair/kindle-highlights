open Base
open Kindle

let check_option expected actual =
  Alcotest.(check (option (pair string string))) "parsed block" expected actual

let test_rejects_malformed_blocks () =
  let cases =
    [
      [];
      [ "Only a title" ];
      [ ""; "- Your Highlight on page 1"; ""; "Quote" ];
      [ "Book"; "- Your Note on page 1"; ""; "Quote" ];
      [ "Book"; "- Your Highlight on page 1"; ""; "" ];
    ]
  in
  List.iter cases ~f:(fun block -> check_option None (Parser.parse_block block))

let test_normalizes_title_and_content () =
  let block =
    [
      "  Book title  ";
      "- Your Highlight on page 1";
      "";
      "  First line  ";
      "";
      "Second line";
      "  ";
    ]
  in
  check_option
    (Some ("Book title", "First line  \n\nSecond line"))
    (Parser.parse_block block)

let test_separator_whitespace_is_accepted () =
  let lines =
    [
      "Book A";
      "- Your Highlight on page 1";
      "";
      "Quote A";
      "  ==========  ";
      "Book B";
      "- Your Highlight on page 2";
      "";
      "Quote B";
    ]
  in
  let entries = Parser.parse_lines lines in
  Alcotest.(check int) "two entries" 2 (List.length entries)

let test_bom_is_only_removed_from_first_lines () =
  let lines =
    [
      "\u{feff}Book";
      "- Your Highlight one page 1";
      "";
      "Quote with \u{feff} marker";
    ]
  in
  let entries = Parser.parse_lines lines in
  match entries with
  | [ entry ] ->
      check_option
        (Some ("Book", "Quote with \u{feff} marker"))
        (Some (entry.Parser.title, entry.Parser.contents))
  | _ -> Alcotest.fail "expected one parsed entry"

let test_parse_lines_preserves_entry_order () =
  let lines =
    [
      "Second";
      "- Your Highlight on page 2";
      "";
      "Second quote";
      "==========";
      "First";
      "- Your Highlight on page 1";
      "";
      "First quote";
    ]
  in
  let titles =
    Parser.parse_lines lines |> List.map ~f:(fun entry -> entry.Parser.title)
  in
  Alcotest.(check (list string)) "input order" [ "Second"; "First" ] titles

let test_empty_separators_are_ignored () =
  let lines =
    [
      "==========";
      "  ========== ";
      "Book";
      "- Your Highlight on page 1";
      "";
      "Quote";
      "==========";
      "==========";
    ]
  in
  Alcotest.(check int) "one entry" 1 (List.length (Parser.parse_lines lines))

let () =
  Alcotest.run "parser_edge_cases"
    [
      ( "parser",
        [
          Alcotest.test_case "rejects malformed blocks" `Quick
            test_rejects_malformed_blocks;
          Alcotest.test_case "normalizes title and content" `Quick
            test_normalizes_title_and_content;
          Alcotest.test_case "separator whitespace" `Quick
            test_separator_whitespace_is_accepted;
          Alcotest.test_case "BOM handling" `Quick
            test_bom_is_only_removed_from_first_lines;
          Alcotest.test_case "preserves entry order" `Quick
            test_parse_lines_preserves_entry_order;
          Alcotest.test_case "ignores empty separators" `Quick
            test_empty_separators_are_ignored;
        ] );
    ]
