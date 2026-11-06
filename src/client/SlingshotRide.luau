-- The Slingshot's hooks into the ride (as Client/StartLine's): Ride.client sets them.
--   SlingshotRide.bestPet()  -> your fastest pet's model at home (the one you'd ride), or nil
--   SlingshotRide.ride(x, z) -> starts a ride from (x, z) on that pet; false if it can't

local SlingshotRide = {}

SlingshotRide.bestPet = nil :: (() -> Model?)?
SlingshotRide.ride = nil :: ((x: number, z: number) -> boolean)?

return SlingshotRide
