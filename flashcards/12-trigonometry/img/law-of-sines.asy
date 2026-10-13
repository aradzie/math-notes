// A generic triangle ABC: each side a, b, c is opposite the vertex angle of
// the same letter, which is marked with an arc.
import _common;

size(5cm);
mathdefaults();

pair B = (0,0), C = (5,0), A = (1.7,3.2);
draw(A--B--C--cycle, linewidth(0.8pt));

real r = 0.55;
draw(arc(A, r, degrees(B-A), degrees(C-A)), blue);
draw(arc(B, r, 0, degrees(A-B)), blue);
draw(arc(C, r, degrees(A-C), 180), blue);

label("$A$", A, N);
label("$B$", B, SW);
label("$C$", C, SE);
label("$a$", (B+C)/2, S);
label("$b$", (A+C)/2, NE);
label("$c$", (A+B)/2, NW);
