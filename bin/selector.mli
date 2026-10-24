val select : prompt:string -> (string * 'a) list -> ('a option, string) result
(** Select a value using its display label. Cancellation returns [Ok None];
    failures return [Error message]. *)
