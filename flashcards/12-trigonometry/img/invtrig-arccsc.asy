// theta = arccsc x lies in [-pi/2, 0) U (0, pi/2], the right half of the unit
// circle without the point at angle 0: sin theta = 1/x, so P = (sqrt(x^2-1), 1)
// for x >= 1 and P = (sqrt(x^2-1), -1) for x <= -1, at distance |x| from O.
// The vertical leg carries the sign of x, the horizontal leg is never
// negative. Samples x = 1.8 and x = -1.8 share the horizontal leg.
import _trig;

real a = sqrt(1.8^2 - 1);
windowSetup(-1.3, 1.95, -1.4, 1.4);
unitCircle();
rangeArc(-pi/2, pi/2);
pair P1 = (a, 1), P2 = (a, -1);
refTriangle(P1, "", "1", "x", rpos=0.75);
refTriangle(P2, "", "-1", "-x", rpos=0.75);
angleMark(P1, 0.16);
angleMark(P2, 0.16);
trigAxes();
// the shared horizontal leg, labeled once, inside the upper triangle
ptLabel((0.62, 0), "\sqrt{x^2-1}", N, accentColor);
arcEnd(pi/2, true);
arcEnd(-pi/2, true);
arcEnd(0, false);
angleLabel(pi/2, "\tfrac\pi2", NW);
angleLabel(-pi/2, "-\tfrac\pi2", SW);
angleLabel(0, "0", SE);
ptLabel(P1, "x=\csc\theta\ge1", NE);
ptLabel(P2, "x=\csc\theta\le-1", SE);
