module Parser = Parser
module Store = Store

module Bookshelf : sig
  type t

  val of_entries : Parser.entry list -> t
  val build_from : string list -> t
  val books : t -> string list
  val quotes : t -> string -> string list option
end
