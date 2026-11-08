-- The Slingshot's hooks into the ride (as Client/StartLine's): Ride.client sets them.
--   SlingshotRide.bestPet()  -> your fastest pet's model at home (the one you'd ride), or nil
--   SlingshotRide.ride(x, z, biome) -> starts a ride from (x, z) on that pet, that biome's gate
--     open to you; false if it can't
--   SlingshotRide.pet       -> the pet to fly with and ride instead of the fastest (the one you
--                              held E on), or nil
--   SlingshotRide.menu(pet, rideHere) -> (SlingshotLaunch sets it) opens the Slingshot menu for
--     the pet you held E on (QM Nov 7, after the tutorial); Meadow (or no slingshot) rides it
--     from home as before (rideHere), any other biome flings you there on it
-- SlingshotLaunch sets SlingshotRide.flying while you're on the band or in the air (Ride.client
-- then doesn't throw you off for an animal under you: you're not on foot).

local SlingshotRide = {}

SlingshotRide.bestPet = nil :: (() -> Model?)?
SlingshotRide.ride = nil :: ((x: number, z: number, biome: number?) -> boolean)?
SlingshotRide.flying = false
SlingshotRide.pet = nil :: Model?
SlingshotRide.menu = nil :: ((pet: Model, rideHere: () -> ()) -> ())?

return SlingshotRide
