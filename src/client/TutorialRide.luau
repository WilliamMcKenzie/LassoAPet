-- The tutorial's first ride, shared between Ride.client (which runs it) and
-- Client/Tutorial (which steers it). QM, Oct 11.
--
-- Tutorial sets:
--   active        the tutorial's ride is on
--   timeScale     its slow motion (1: none), on top of Ride's own
--   holdFrozen    no BOSS IN timer (and no bar) yet
--   bossSeconds   BOSS IN's length once it's let go (the bar shows that many seconds)
--   invulnerable  nothing crashes you
-- Ride sets:
--   canLasso      an animal's in reach of your lasso right now
--   mounts        how many animals you've been on (each lasso is one more)
--   throws        how many lassoes you've thrown (hit or miss)
--   sprinting     you're sprinting
return {
	active = false,
	timeScale = 1,
	holdFrozen = false,
	bossSeconds = nil,
	invulnerable = false,
	canLasso = false,
	mounts = 0,
	throws = 0,
	sprinting = false,
}
