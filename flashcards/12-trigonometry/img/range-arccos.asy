// The range of arccos, [0, pi], on the unit circle: the upper semicircle
// with both ends included.
import _trig;

windowSetup(-1.35, 1.35, -1.35, 1.35);
unitCircle();
rangeArc(0, pi);
trigAxes();
arcEnd(0, true);
arcEnd(pi, true);
angleLabel(0, "0", SE);
angleLabel(pi, "\pi", SW);
