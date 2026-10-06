// theta = arcsec x lies in [0, pi/2) U (pi/2, pi], the upper half of the unit
// circle without its top: cos theta = 1/x, so P = (1, sqrt(x^2-1)) for x >= 1
// and P = (-1, sqrt(x^2-1)) for x <= -1, at distance |x| from O. The
// horizontal leg carries the sign of x, the vertical leg is never negative.
// Samples x = 1.8 and x = -1.8.
import _trig;

real b = sqrt(1.8^2 - 1);
windowSetup(-1.6, 1.6, -1.3, 1.85);
unitCircle();
rangeArc(0, pi);
pair P1 = (1, b), P2 = (-1, b);
refTriangle(P1, "1", "\sqrt{x^2-1}", "x", rpos=0.72);
refTriangle(P2, "-1", "\sqrt{x^2-1}", "-x", rpos=0.72);
angleMark(P1, 0.22);
angleMark(P2, 0.32);
trigAxes();
arcEnd(0, true);
arcEnd(pi, true);
arcEnd(pi/2, false);
angleLabel(0, "0", SE);
angleLabel(pi, "\pi", SW);
angleLabel(pi/2, "\tfrac\pi2", NE);
ptLabel(P1, "x=\sec\theta\ge1", NE);
ptLabel(P2, "x=\sec\theta\le-1", NW);
