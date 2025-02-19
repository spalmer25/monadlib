(** The list monad transformer will add non-determinism to computations. I
    have not provided a transformer for lazy lists, since I'm not yet sure how
    to implement it. It would probably need a lazy version of map_m, but it's
    not clear to me how to write this, since whether the computations are
    strict will determine whether the argument has to be completely forced. *)
module Trans (M : Monad.S) : sig
  include Monad.S with type 'a m = 'a list M.m

  val lift : 'a M.m -> 'a m
end

module TransPlus (M : MonadPlus.S) : sig
  include MonadPlus.S with type 'a m = 'a list M.m

  val lift : 'a M.m -> 'a m
end

module Monad : MonadPlus.S with type 'a m = 'a list
