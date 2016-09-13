// Match a desired inclination. If asap is true, will do so at the nearest
// rather than highest an/dn.

// Parameters
parameter target_inclination.
parameter asap is false.

local position is ship:position - ship:body:position.
local velocity is ship:velocity:orbit.
local ang_vel is 4 * ship:obt:inclination / ship:obt:period.

local equatorial_position is V(position:x, 0, position:z).
local angle_to_equator is vang(position,equatorial_position).
local flip is false.

if position:y > 0 {
    // Planning a burn at DN
	if velocity:y > 0 {
		// above & traveling away from equator; need to rise to inc, then fall back to 0
		set angle_to_equator to 2 * ship:obt:inclination - abs(angle_to_equator).
	}
    if abs(ship:obt:argumentofperiapsis) < 180 and not asap {
        set angle_to_equator to angle_to_equator + 180.
        set flip to true.
    }
} else {
    // Planning a burn at AN
	if velocity:y < 0 {
		// below & traveling away from the equator; need to fall to inc, then rise back to 0
		set angle_to_equator to 2 * ship:obt:inclination - abs(angle_to_equator).
	}
    if abs(ship:obt:argumentofperiapsis) > 180 and not asap {
        set angle_to_equator to angle_to_equator + 180.
        set flip to true.
    }
}

local frac is (angle_to_equator / (4 * ship:obt:inclination)).
local dt is frac * ship:obt:period.
local t is time + dt.

local relative_inclination is abs(ship:obt:inclination - target_inclination).
local v is velocityat(ship, T):orbit.
local dv is 2 * v:mag * sin(relative_inclination / 2).

if flip {
    set dv to -dv.
}

if v:y > 0 {
  // burn anti-normal at ascending node
	add node(T:seconds, 0, -dv, 0).
} else {
  // burn normal at descending node
	add node(T:seconds, 0, dv, 0).
}
