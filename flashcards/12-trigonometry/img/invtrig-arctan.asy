// theta = arctan x lies in (-pi/2, pi/2), the right half of the unit circle
// without its ends: the terminal side meets the line x = 1 at P = (1, x), at
// distance sqrt(1+x^2) from O, and the horizontal leg 1 is always positive.
// Samples x = 1.2 and x = -1.2 share the horizontal leg.
import _trig;

windowSetup(-1.35, 1.65, -1.5, 1.5);
asymptoteV(1);
unitCircle();
rangeArc(-pi/2, pi/2);
pair P1 = (1, 1.2), P2 = (1, -1.2);
refTriangle(P1, "1", "x=\tan\theta", "\sqrt{1+x^2}", hdir=N);
refTriangle(P2, "", "x=\tan\theta", "\sqrt{1+x^2}");
angleMark(P1, 0.22);
angleMark(P2, 0.22);
trigAxes();
arcEnd(pi/2, false);
arcEnd(-pi/2, false);
angleLabel(pi/2, "\tfrac\pi2", NW);
angleLabel(-pi/2, "-\tfrac\pi2", SW);
ptLabel(P1, "\tan\theta>0", NE);
ptLabel(P2, "\tan\theta<0", SE);
