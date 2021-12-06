module type T = sig
  type 'a m

  val return : 'a -> 'a m
  val ( <*> ) : ('a -> 'b) m -> 'a m -> 'b m
end

module type S = sig
  include T

  val map : ('a -> 'b) -> 'a m -> 'b m

  val ( $ ) : ('a -> 'b) -> 'a m -> 'b m
  (** Alias for map *)

  val ( let$ ) : 'a m -> ('a -> 'b) -> 'b m
  (** Binding operator for map *)

  val ignore : 'a m -> unit m
  val ( <* ) : 'a m -> 'b m -> 'a m
  val ( *> ) : 'a m -> 'b m -> 'b m
  val map2 : ('a -> 'b -> 'c) -> 'a m -> 'b m -> 'c m
  val map3 : ('a -> 'b -> 'c -> 'd) -> 'a m -> 'b m -> 'c m -> 'd m

  val map4
    :  ('a -> 'b -> 'c -> 'd -> 'e)
    -> 'a m
    -> 'b m
    -> 'c m
    -> 'd m
    -> 'e m

  (** {1 List functions} *)

  val sequence : 'a m list -> 'a list m
  val sequence_unit : unit m list -> unit m
  val list_map : ('a -> 'b m) -> 'a list -> 'b list m
  val list_iter : ('a -> unit m) -> 'a list -> unit m

  (** {1 Option functions} *)

  val optional : 'a m option -> 'a option m
  val option_map : ('a -> 'b m) -> 'a option -> 'b option m

  (** {1 Boolean function} *)

  val conditional : bool -> (unit -> unit m) -> unit m
end

module Make (A : T) : S with type 'a m = 'a A.m = struct
  include A

  let ( $ ) f x = return f <*> x
  let map = ( $ )
  let ( let$ ) x f = f $ x
  let map2 f x y = f $ x <*> y
  let map3 f x y z = f $ x <*> y <*> z
  let map4 f x y z w = f $ x <*> y <*> z <*> w
  let ( <* ) x y = map2 (fun x _ -> x) x y
  let ( *> ) x y = map2 (fun _ y -> y) x y
  let ignore m = map (fun _ -> ()) m

  let rec sequence = function
    | [] -> return []
    | m :: ms -> map2 (fun x xs -> x :: xs) m (sequence ms)

  let rec sequence_unit = function
    | [] -> return ()
    | m :: ms -> m *> sequence_unit ms

  let list_map f xs = sequence (BatList.map f xs)
  let list_iter f xs = sequence_unit (BatList.map f xs)

  let optional = function
    | None -> return None
    | Some f -> map (fun y -> Some y) f

  let option_map f xs = optional (BatOption.map f xs)
  let conditional b f = if b then f () else return ()
end

module Transform (A : T) (Inner : T) = struct
  module A = Make (A)

  type 'a m = 'a Inner.m A.m

  let return x = A.return (Inner.return x)
  let ( <*> ) f x = A.map2 Inner.( <*> ) f x
end
