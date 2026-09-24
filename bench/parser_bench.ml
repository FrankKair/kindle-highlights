open Kindle

let iterations = 100

let () =
  match Sys.argv with
  | [| _; filepath |] ->
      let lines = Stdio.In_channel.read_lines filepath in
      let start = Unix.gettimeofday () in
      for _ = 1 to iterations do
        ignore (Bookshelf.build_from lines)
      done;
      let elapsed = Unix.gettimeofday () -. start in
      let entries = Parser.parse_lines lines |> List.length in
      Printf.printf
        "file=%s\n\
         lines=%d\n\
         entries=%d\n\
         iterations=%d\n\
         elapsed_seconds=%.6f\n\
         per_iteration_ms=%.3f\n"
        filepath (List.length lines) entries iterations elapsed
        (elapsed *. 1000. /. Float.of_int iterations)
  | _ ->
      Printf.eprintf "usage: dune exec bench/parser_bench.exe -- FILE\n";
      exit 2
