// Wait until target is some time behind

// Parameters
parameter lead_time is 0.

// Imports
run once koslib.

// Fixed parameters
set forward_search_resolution to 30.
set backtracking_resolution to 1.

// Make sure we're landed
//if status <> "LANDED" {
//    print "You need to be on the ground to use this".
//}
clearscreen.

// When will the target be overhead hit the ground?
function posang {
    parameter a.
    return mod(a + 360, 360).
}

function overhead_time {
    local guess_time is time:seconds.
    local our_lng is posang(body:geopositionof(positionat(ship, guess_time)):lng).
    local targ_lng is posang(body:geopositionof(positionat(target, guess_time)):lng).

    // Forward search.
    until targ_lng > our_lng {
        clearscreen.
        set guess_time to guess_time + forward_search_resolution.
        print "Checking t+" + (guess_time - time:seconds) at (0, 0).
        set targ_lng to posang(body:geopositionof(positionat(target, guess_time)):lng).
    }

    // Backtrack.
    until targ_lng < our_lng {
        clearscreen.
        set guess_time to guess_time - backtracking_resolution.
        print "Checking t+" + (guess_time - time:seconds) at (0, 0).
        set targ_lng to posang(body:geopositionof(positionat(target, guess_time)):lng).
    }

    if guess_time < time:seconds {
        set guess_time to guess_time + target:orbit:period.
    }

    print "Final t+" + (guess_time - time:seconds) at (0,1).
    return guess_time.
}

clearscreen.

set overhead_t to overhead_time().
print "Print waiting another " + sec2timestr(overhead_t - time:seconds - lead_time).

// Actually do the waiting
warpto(overhead_t - lead_time).
