open Base
open Kindle

let with_temp_path f =
  let path = Stdlib.Filename.temp_file "kindle-highlights-test-" ".sexp" in
  Stdlib.Fun.protect
    ~finally:(fun () ->
      if Stdlib.Sys.file_exists path then Stdlib.Sys.remove path)
    (fun () -> f path)

let pairs entries =
  List.map entries ~f:(fun (entry : Parser.entry) ->
      (entry.title, entry.contents))

let save_exn ~path entries =
  match Store.save ~path entries with
  | Ok () -> ()
  | Error error -> Alcotest.fail (Store.error_to_string error)

let load_exn ~path =
  match Store.load ~path with
  | Ok entries -> entries
  | Error error -> Alcotest.fail (Store.error_to_string error)

let test_round_trip_and_replace () =
  with_temp_path (fun path ->
      let first : Parser.entry list =
        [ { title = "Book A"; contents = "First quote" } ]
      in
      let second : Parser.entry list =
        [ { title = "Book B"; contents = "Second quote" } ]
      in
      save_exn ~path first;
      Alcotest.(check (list (pair string string)))
        "saved entries" (pairs first)
        (pairs (load_exn ~path));
      let invalid : Parser.entry list =
        [ { title = ""; contents = "Bad quote" } ]
      in
      (match Store.save ~path invalid with
      | Error Store.Invalid_data -> ()
      | _ -> Alcotest.fail "invalid entries should be rejected");
      Alcotest.(check (list (pair string string)))
        "failed save keeps old entries" (pairs first)
        (pairs (load_exn ~path));
      save_exn ~path second;
      Alcotest.(check (list (pair string string)))
        "replacement contains only new entries" (pairs second)
        (pairs (load_exn ~path)))

let write_file path contents =
  let channel = Stdlib.open_out_bin path in
  Stdlib.Fun.protect
    ~finally:(fun () -> Stdlib.close_out_noerr channel)
    (fun () -> Stdlib.output_string channel contents)

let test_bad_data_and_version () =
  with_temp_path (fun path ->
      write_file path "not a saved library";
      (match Store.load ~path with
      | Error Store.Invalid_data -> ()
      | _ -> Alcotest.fail "malformed data should be rejected");
      write_file path "(kindle-highlights 99 ())";
      (match Store.load ~path with
      | Error (Store.Unsupported_version 99) -> ()
      | _ -> Alcotest.fail "future version should be reported");
      write_file path "(kindle-highlights 1 (((title \"\") (contents Quote))))";
      match Store.load ~path with
      | Error Store.Invalid_data -> ()
      | _ -> Alcotest.fail "empty titles should be rejected")

let test_missing_file () =
  with_temp_path (fun path ->
      Stdlib.Sys.remove path;
      match Store.load ~path with
      | Error Store.Missing_file -> ()
      | _ -> Alcotest.fail "missing library should be reported")

let () =
  Alcotest.run "store"
    [
      ( "persistence",
        [
          Alcotest.test_case "round trip and replace" `Quick
            test_round_trip_and_replace;
          Alcotest.test_case "bad data and version" `Quick
            test_bad_data_and_version;
          Alcotest.test_case "missing file" `Quick test_missing_file;
        ] );
    ]
