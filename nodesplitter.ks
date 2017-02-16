parameter dv_max is 500.

run once koslib.

clearscreen.

set nd_orig to nextnode.
set dv_orig to nd_orig:deltav.
set n_burns to ceiling(dv_orig:mag / dv_max).
print round(dv_orig:mag, 1) + "m/s to be done in " + n_burns + " burns".

set burn_num to 0.
set burn_t to time:seconds + nd_orig:eta.
remove nd_orig.

set periods to stack().

until burn_num = n_burns - 1 {
    set burn_num to burn_num + 1.
    set f to burn_num / n_burns.
    print "Testing a burn for " + burn_num + "/" + n_burns + " of the total".
    set nd to node(burn_t, nd_orig:radialout * f, nd_orig:normal * f, nd_orig:prograde * f).
    add nd.
    wait 0.
    print "It had a period of " + sec2timestr(nd:orbit:period).
    periods:push(nd:orbit:period).
    remove nd.
}

set burn_num to n_burns.
until burn_num = 0 {
    print "Adding a node at " + sec2timestr(burn_t).
    add node(burn_t, nd_orig:radialout / n_burns, nd_orig:normal / n_burns, nd_orig:prograde / n_burns).
    wait 0.
    set burn_num to burn_num - 1.
    if not periods:empty {
        set per to periods:pop().
        set burn_t to burn_t - per.
        print "Backing up by " + sec2timestr(per).
    }
}
