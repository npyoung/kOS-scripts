// Land on an airless body using a suicide burn that corrects to hit a target
// followed by a vertical soft landing procedure.

run precise_suicideburn(1000, -10).

gear on.

run precise_softland(50, -2, 0, true).
