// Parameters
parameter final_ap.
parameter compass is 90.

// Imports
run once koslib.

// Autostaging logic
when anyflameout() then {
    handleflameout().
    return true.
}

// Launch and limit max G-force (G on Kerbin)
lock throttle to glimited_throttle(2).
print "LAUNCH!".

// Max G throttle straight up until Ap > 200
wait until apoapsis > 200.

// Point at heading(90, 45) and burn until Ap > final_ap
lock steering to heading(compass, 45).
//wait 5.
//lock steering to prograde.
wait until apoapsis > final_ap.
lock throttle to 0.

// Create circ node and execute
run change_pe_at_ap(apoapsis).
run execnode.
