// theta = arccos x lies in [0, pi], the upper half of the unit circle:
// P = (cos theta, sin theta) = (x, sqrt(1-x^2)), so the y-coordinate is never
// negative whatever the sign of x. Samples x = 0.4 and x = -0.4.
import _trig;

windowSetup(-1.35, 1.35, -1.35, 1.35);
unitCircle();
rangeArc(0, pi);
real b = sqrt(1 - 0.4^2);
pair P1 = (0.4, b), P2 = (-0.4, b);
refTriangle(P1, "x=\cos\theta", "\sqrt{1-x^2}", "1", hdir=SE, vpos=0.3);
refTriangle(P2, "x=\cos\theta", "\sqrt{1-x^2}", "1", hdir=SW, vpos=0.3);
angleMark(P1, 0.22);
angleMark(P2, 0.32);
trigAxes();
arcEnd(0, true);
arcEnd(pi, true);
angleLabel(0, "0", SE);
angleLabel(pi, "\pi", SW);
ptLabel(P1, "\cos\theta>0", NE);
ptLabel(P2, "\cos\theta<0", NW);
