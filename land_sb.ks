// Land on an airless body using a suicide burn with margin followed by a stage
// dump and softland.

// Parameters
parameter dump_stage is true.

run suicideburn(500, -10).

if dump_stage {
    run once koslib.
    killengines().
    stage.
    wait until stage:ready.
    stage.
}
wait until stage:ready.
gear on.

run softland(-2).
