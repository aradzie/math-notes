// The range of arccot, (0, pi), on the unit circle: the upper semicircle
// without its ends (sin theta = 0 there, so cot theta is undefined).
import _trig;

windowSetup(-1.35, 1.35, -1.35, 1.35);
unitCircle();
rangeArc(0, pi);
trigAxes();
arcEnd(0, false);
arcEnd(pi, false);
angleLabel(0, "0", SE);
angleLabel(pi, "\pi", SW);
