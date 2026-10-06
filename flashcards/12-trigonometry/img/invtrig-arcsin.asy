// theta = arcsin x lies in [-pi/2, pi/2], the right half of the unit circle:
// P = (cos theta, sin theta) = (sqrt(1-x^2), x), so the x-coordinate is never
// negative whatever the sign of x. Samples x = 0.5 and x = -0.5 share the
// horizontal leg.
import _trig;

windowSetup(-1.35, 1.35, -1.35, 1.35);
unitCircle();
rangeArc(-pi/2, pi/2);
real a = sqrt(1 - 0.5^2);
pair P1 = (a, 0.5), P2 = (a, -0.5);
refTriangle(P1, "", "", "1");
refTriangle(P2, "", "", "1");
angleMark(P1, 0.16);
angleMark(P2, 0.16);
trigAxes();
// the shared horizontal leg, labeled once, inside the upper triangle
ptLabel((0.53, 0), "\sqrt{1-x^2}", N, accentColor);
arcEnd(pi/2, true);
arcEnd(-pi/2, true);
angleLabel(pi/2, "\tfrac\pi2", NE);
angleLabel(-pi/2, "-\tfrac\pi2", SE);
ptLabel(P1, "\sin\theta>0", NE);
ptLabel(P2, "\sin\theta<0", SE);
