module Library : sig
  type ('a, 'b) t

  (* Creates a library given a list of string (lines) *)
  val build : string list -> ('a, 'b) t

  (* List with book titles *)
  val books : ('a, 'b) t -> string list

  (* Quotes associated with a book title *)
  val quotes : ('a, 'b) t -> string -> string list
end
