run suicideburn(1500, -10).

run once koslib.
lock throttle to 0.
killengines().
stage.
gear on.
wait until stage:ready.

ship:partstagged("landingCore")[0]:controlfrom().
lock steering to srfretrograde.
