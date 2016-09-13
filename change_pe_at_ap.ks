// Parameters
parameter alt.

local mu is body:mu.
local br is body:radius.

// Current orbit properties
local vom is ship:obt:velocity:orbit:mag.      // actual velocity
local r is br + altitude.                      // actual distance to body
local ra is br + apoapsis.                     // radius at burn apsis
local v1 is sqrt( vom^2 + 2*mu*(1/ra - 1/r) ). // velocity at burn apsis
local sma1 is (periapsis + 2*br + apoapsis)/2. // semi major axis present orbit

// Desired orbit properties
local r2 is br + apoapsis.               // distance after burn at apoapsis
local sma2 is (alt + 2*br + apoapsis)/2. // semi major axis target orbit
local v2 is sqrt( vom^2 + (mu * (2/r2 - 2/r + 1/sma1 - 1/sma2 ) ) ).

// Make node
local deltav is v2 - v1.
local nd is node(time:seconds + eta:apoapsis, 0, 0, deltav).
add nd.
