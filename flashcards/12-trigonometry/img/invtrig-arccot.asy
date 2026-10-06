// theta = arccot x lies in (0, pi), the upper half of the unit circle
// without its ends: the terminal side meets the line y = 1 at P = (x, 1), at
// distance sqrt(1+x^2) from O, and the vertical leg 1 is always positive.
// Samples x = 1.2 and x = -1.2.
import _trig;

windowSetup(-1.65, 1.65, -1.35, 1.5);
asymptoteH(1);
unitCircle();
rangeArc(0, pi);
pair P1 = (1.2, 1), P2 = (-1.2, 1);
refTriangle(P1, "x=\cot\theta", "1", "\sqrt{1+x^2}");
refTriangle(P2, "x=\cot\theta", "1", "\sqrt{1+x^2}");
angleMark(P1, 0.22);
angleMark(P2, 0.32);
trigAxes();
arcEnd(0, false);
arcEnd(pi, false);
angleLabel(0, "0", SE);
angleLabel(pi, "\pi", SW);
ptLabel(P1, "\cot\theta>0", NE);
ptLabel(P2, "\cot\theta<0", NW);
