-- The Slingshot's hooks into the ride (as Client/StartLine's): Ride.client sets them.
--   SlingshotRide.bestPet()  -> your fastest pet's model at home (the one you'd ride), or nil
--   SlingshotRide.ride(x, z) -> starts a ride from (x, z) on that pet; false if it can't
-- SlingshotLaunch sets SlingshotRide.flying while you're on the band or in the air (Ride.client
-- then doesn't throw you off for an animal under you: you're not on foot).

local SlingshotRide = {}

SlingshotRide.bestPet = nil :: (() -> Model?)?
SlingshotRide.ride = nil :: ((x: number, z: number) -> boolean)?
SlingshotRide.flying = false

return SlingshotRide
