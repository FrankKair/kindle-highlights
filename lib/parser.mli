open Base

type entry = { title : string; contents : string }

val parse_block : string list -> (string * string) option
(** Parse one Kindle clipping block. A valid block has a non-empty title,
    metadata containing [Your Highlight], and non-empty content. Bookmarks and
    malformed blocks are ignored. *)

val parse_lines : string list -> entry list
(** Parse all highlight entries in a list of clippings lines. *)

val build_lib : from:string list -> string list Map.M(String).t
(** Build a title-to-highlights index, preserving input order while removing
    duplicate highlight text for each title. *)
