// Parameters
parameter target_alt.

local mu is body:mu.
local br is body:radius.

// Current orbit properties
local vom is ship:obt:velocity:orbit:mag.      // actual velocity
local r is br + altitude.                      // actual distance to body
local ra is br + periapsis.                    // radius at burn apsis
local v1 is sqrt( vom^2 + 2*mu*(1/ra - 1/r) ). // velocity at burn apsis
local sma1 is obt:semimajoraxis.

// Desired orbit properties
local r2 is br + periapsis.                    // distance after burn at periapsis
local sma2 is (target_alt + 2*br + periapsis)/2. // semi major axis target orbit
local v2 is sqrt( vom^2 + (mu * (2/r2 - 2/r + 1/sma1 - 1/sma2 ) ) ).

// Create node
local deltav is v2 - v1.
local nd is node(time:seconds + eta:periapsis, 0, 0, deltav).
add nd.
