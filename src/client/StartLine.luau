-- Walking over the start line on foot (WalkLimit.client) rides a random Meadow
-- animal from the spot (QM, Oct 6). Ride.client sets StartLine.ride(x, z): it
-- starts the ride and returns true, or false when it can't (already riding, the
-- tutorial's ending), and WalkLimit holds you at the line with its notice instead.

local StartLine = {}

StartLine.ride = nil :: ((x: number, z: number) -> boolean)?

return StartLine
