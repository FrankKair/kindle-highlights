open Base
open Kindle

(* -- Generators -- *)

let separator = [ "==========" ]

(* Generate a non-empty, trimmed string suitable for a title or quote. *)
let gen_nonempty_trimmed =
  QCheck.Gen.(
    map
      (fun s ->
        let s = String.strip s in
        if String.is_empty s then "fallback" else s)
      (string_size ~gen:printable (1 -- 80)))

let gen_highlight_metadata =
  QCheck.Gen.(
    map
      (fun (page, loc_start) ->
        Printf.sprintf
          "- Your Highlight on page %d | Location %d-%d | Added on..." page
          loc_start (loc_start + 10))
      (pair (1 -- 999) (1 -- 9999)))

let gen_bookmark_metadata =
  QCheck.Gen.(
    map
      (fun (page, loc) ->
        Printf.sprintf "- Your Bookmark on page %d | Location %d | Added on..."
          page loc)
      (pair (1 -- 999) (1 -- 9999)))

(* Generate a valid highlight block: returns (title, content, lines). *)
let gen_highlight_block =
  QCheck.Gen.(
    map
      (fun ((title, content), metadata) ->
        (title, content, [ title; metadata; ""; content ]))
      (pair
         (pair gen_nonempty_trimmed gen_nonempty_trimmed)
         gen_highlight_metadata))

(* Generate a bookmark block (should be ignored by the parser). *)
let gen_bookmark_block =
  QCheck.Gen.(
    map
      (fun (title, metadata) -> [ title; metadata; "" ])
      (pair gen_nonempty_trimmed gen_bookmark_metadata))

(* Generate a block that is guaranteed to be rejected by the parser. *)
let gen_malformed_block =
  QCheck.Gen.oneof
    [
      QCheck.Gen.return [];
      QCheck.Gen.map (fun title -> [ title ]) gen_nonempty_trimmed;
      QCheck.Gen.map
        (fun title ->
          [
            title;
            "- Your Note on page 1 | Location 1 | Added on...";
            "";
            "not a highlight";
          ])
        gen_nonempty_trimmed;
    ]

let blocks_to_lines blocks =
  List.concat_map blocks ~f:(fun block -> block @ separator)

let entries_as_pairs entries =
  List.map entries ~f:(fun e -> (e.Parser.title, e.Parser.contents))

(* Arbitrary inputs *)

let arbitrary_lines = QCheck.list QCheck.string

(* Property: arbitrary input never raises, outputs are normalized *)

let prop_normalized_output =
  QCheck.Test.make ~name:"arbitrary input produces normalized entries"
    ~count:1_000 arbitrary_lines (fun lines ->
      let entries = Parser.parse_lines lines in
      List.for_all entries ~f:(fun entry ->
          (not (String.is_empty entry.Parser.title))
          && String.equal entry.Parser.title (String.strip entry.Parser.title)
          && (not (String.is_empty entry.Parser.contents))
          && String.equal entry.Parser.contents
               (String.strip entry.Parser.contents)))

(* Property: separators are structural, never become content *)

let prop_separators_structural =
  QCheck.Test.make ~name:"separators are structural, never become content"
    ~count:1_000 arbitrary_lines (fun lines ->
      List.for_all (Parser.parse_lines lines) ~f:(fun entry ->
          String.split_lines entry.Parser.contents
          |> List.for_all ~f:(fun line ->
              not (String.equal (String.strip line) "=========="))))

(* Property: a valid highlight round-trips through the parser *)

let prop_highlight_round_trip =
  QCheck.Test.make ~name:"valid highlight round-trips through the parser"
    ~count:1_000 (QCheck.make gen_highlight_block)
    (fun (title, content, block_lines) ->
      let lines = block_lines @ [ "==========" ] in
      let entries = Parser.parse_lines lines in
      match entries with
      | [ entry ] ->
          String.equal entry.Parser.title title
          && String.equal entry.Parser.contents content
      | _ -> false)

(* Property: adding bookmarks does not change parsed highlights *)

let prop_bookmarks_do_not_affect_highlights =
  QCheck.Test.make ~name:"adding bookmarks does not change parsed highlights"
    ~count:500
    (QCheck.make
       (QCheck.Gen.pair
          (QCheck.Gen.list_size (QCheck.Gen.( -- ) 1 5) gen_highlight_block)
          gen_bookmark_block))
    (fun (highlights, bookmark) ->
      let highlight_blocks =
        List.map highlights ~f:(fun (_, _, block) -> block)
      in
      let without_bookmarks = blocks_to_lines highlight_blocks in
      let with_bookmarks =
        blocks_to_lines
          (List.concat_map highlight_blocks ~f:(fun h -> [ h; bookmark ]))
      in
      let entries_without =
        entries_as_pairs (Parser.parse_lines without_bookmarks)
      in
      let entries_with = entries_as_pairs (Parser.parse_lines with_bookmarks) in
      List.equal
        (fun (t1, c1) (t2, c2) -> String.equal t1 t2 && String.equal c1 c2)
        entries_without entries_with)

(* Property: malformed blocks do not affect neighboring valid entries *)

let prop_malformed_blocks_do_not_affect_valid =
  QCheck.Test.make
    ~name:"malformed blocks do not affect neighboring valid entries" ~count:500
    (QCheck.make
       (QCheck.Gen.list_size (QCheck.Gen.( -- ) 1 5)
          (QCheck.Gen.pair gen_highlight_block gen_malformed_block)))
    (fun pairs ->
      let highlight_blocks =
        List.map pairs ~f:(fun ((_, _, block), _) -> block)
      in
      let malformed_blocks = List.map pairs ~f:(fun (_, junk) -> junk) in
      let clean_lines = blocks_to_lines highlight_blocks in
      let dirty_lines =
        blocks_to_lines
          (List.map2_exn highlight_blocks malformed_blocks ~f:(fun h j ->
               [ h; j ])
          |> List.concat)
      in
      let clean_entries = entries_as_pairs (Parser.parse_lines clean_lines) in
      let dirty_entries = entries_as_pairs (Parser.parse_lines dirty_lines) in
      List.equal
        (fun (t1, c1) (t2, c2) -> String.equal t1 t2 && String.equal c1 c2)
        clean_entries dirty_entries)

(* Property: parsing the same input twice gives the same results *)

let prop_deterministic =
  QCheck.Test.make ~name:"parsing the same input twice gives the same results"
    ~count:1_000 arbitrary_lines (fun lines ->
      let run () = entries_as_pairs (Parser.parse_lines lines) in
      let first = run () in
      let second = run () in
      List.equal
        (fun (t1, c1) (t2, c2) -> String.equal t1 t2 && String.equal c1 c2)
        first second)

(* Property: entry order is preserved *)

let prop_entry_order_preserved =
  QCheck.Test.make ~name:"entry order is preserved" ~count:500
    (QCheck.make
       (QCheck.Gen.list_size (QCheck.Gen.( -- ) 2 10) gen_highlight_block))
    (fun highlights ->
      let blocks = List.map highlights ~f:(fun (_, _, block) -> block) in
      let lines = blocks_to_lines blocks in
      let expected_titles =
        List.map highlights ~f:(fun (title, _, _) -> title)
      in
      let actual_titles =
        Parser.parse_lines lines |> List.map ~f:(fun e -> e.Parser.title)
      in
      List.equal String.equal expected_titles actual_titles)

(* Property: duplicate entries are stably deduplicated *)

let prop_dedup_preserves_first =
  QCheck.Test.make ~name:"build_lib deduplicates, preserving first occurrence"
    ~count:500
    (QCheck.make
       QCheck.Gen.(
         map
           (fun ((title, quote1), quote2) -> (title, quote1, quote2))
           (pair
              (pair gen_nonempty_trimmed gen_nonempty_trimmed)
              gen_nonempty_trimmed)))
    (fun (title, quote1, quote2) ->
      let meta = "- Your Highlight on page 1 | Location 1-10 | Added on..." in
      let lines =
        [
          title;
          meta;
          "";
          quote1;
          "==========";
          title;
          meta;
          "";
          quote2;
          "==========";
          title;
          meta;
          "";
          quote1;
          "==========";
        ]
      in
      let lib = Parser.build_lib ~from:lines in
      match Map.find lib title with
      | None -> false
      | Some quotes ->
          if String.equal quote1 quote2 then
            List.equal String.equal quotes [ quote1 ]
          else List.equal String.equal quotes [ quote1; quote2 ])

(* Run *)

let () =
  Alcotest.run "parser_properties"
    [
      ( "normalization",
        [
          QCheck_alcotest.to_alcotest prop_normalized_output;
          QCheck_alcotest.to_alcotest prop_separators_structural;
        ] );
      ( "semantic",
        [
          QCheck_alcotest.to_alcotest prop_highlight_round_trip;
          QCheck_alcotest.to_alcotest prop_bookmarks_do_not_affect_highlights;
          QCheck_alcotest.to_alcotest prop_malformed_blocks_do_not_affect_valid;
          QCheck_alcotest.to_alcotest prop_deterministic;
          QCheck_alcotest.to_alcotest prop_entry_order_preserved;
          QCheck_alcotest.to_alcotest prop_dedup_preserves_first;
        ] );
    ]
