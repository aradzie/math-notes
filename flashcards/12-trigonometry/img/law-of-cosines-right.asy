// The law-of-cosines triangle with C a right angle: c is the hypotenuse.
// See law-of-cosines.asy for the generic case.
import _common;

size(5cm);
mathdefaults();

pair B = (0,0), C = (4,0), A = (4,3);
draw(A--B--C--cycle, linewidth(0.8pt));
real s = 0.4;
draw((C + (-s,0))--(C + (-s,s))--(C + (0,s)), blue);
real r = 0.5;
draw(arc(A, r, degrees(B-A), degrees(C-A)), blue);
draw(arc(B, r, 0, degrees(A-B)), blue);

label("$A$", A, N);
label("$B$", B, SW);
label("$C$", C, SE);
label("$a$", (B+C)/2, S);
label("$b$", (A+C)/2, E);
label("$c$", (A+B)/2, NW);
