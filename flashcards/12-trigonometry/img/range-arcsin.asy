// The range of arcsin, [-pi/2, pi/2], on the unit circle: the right
// semicircle with both ends included.
import _trig;

windowSetup(-1.35, 1.35, -1.35, 1.35);
unitCircle();
rangeArc(-pi/2, pi/2);
trigAxes();
arcEnd(pi/2, true);
arcEnd(-pi/2, true);
angleLabel(pi/2, "\tfrac\pi2", NE);
angleLabel(-pi/2, "-\tfrac\pi2", SE);
