// Acute triangle ABC with base BC = a, side CA = b and angle C; the altitude
// from A meets line BC at D, so h = b sin C.
import _common;

size(6cm);
mathdefaults();

pair B = (0,0), C = (5,0), A = (3.6,3);
pair D = (A.x, 0);
draw(A--B--C--cycle, linewidth(0.8pt));
draw(A--D, blue + dashed);

real s = 0.3;
draw((D + (-s,0))--(D + (-s,s))--(D + (0,s)), blue);
draw(arc(C, 0.7, degrees(A-C), 180), blue);

label("$A$", A, N);
label("$B$", B, SW);
label("$C$", C, SE);
label("$D$", D, S);
label("$a$", (B+D)/2, S);
label("$b$", (A+C)/2, NE);
label("$h$", (A+D)/2, E, blue);
