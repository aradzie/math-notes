// The range of arccsc, [-pi/2, 0) U (0, pi/2], on the unit circle: the right
// semicircle with both ends included and the point at angle 0 excluded
// (sin theta = 0 there, so csc theta is undefined).
import _trig;

windowSetup(-1.35, 1.35, -1.35, 1.35);
unitCircle();
rangeArc(-pi/2, pi/2);
trigAxes();
arcEnd(pi/2, true);
arcEnd(-pi/2, true);
arcEnd(0, false);
angleLabel(pi/2, "\tfrac\pi2", NE);
angleLabel(-pi/2, "-\tfrac\pi2", SE);
angleLabel(0, "0", SE);
