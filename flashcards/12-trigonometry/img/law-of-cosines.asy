// A generic triangle ABC with every vertex angle marked: sides a and b meet
// at angle C, opposite side c.
// See law-of-cosines-right.asy for the case where C is a right angle.
import _common;

size(5cm);
mathdefaults();

pair B = (0,0), C = (5,0), A = (4,3.2);
draw(A--B--C--cycle, linewidth(0.8pt));
real r = 0.5;
draw(arc(A, r, degrees(B-A), degrees(C-A)), blue);
draw(arc(B, r, 0, degrees(A-B)), blue);
draw(arc(C, r, degrees(A-C), 180), blue);

label("$A$", A, N);
label("$B$", B, SW);
label("$C$", C, E);
label("$a$", (B+C)/2, S);
label("$b$", (A+C)/2, NE);
label("$c$", (A+B)/2, NW);
