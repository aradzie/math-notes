// The range of arcsec, [0, pi/2) U (pi/2, pi], on the unit circle: the upper
// semicircle with both ends included and its top excluded (cos theta = 0
// there, so sec theta is undefined).
import _trig;

windowSetup(-1.35, 1.35, -1.35, 1.35);
unitCircle();
rangeArc(0, pi);
trigAxes();
arcEnd(0, true);
arcEnd(pi, true);
arcEnd(pi/2, false);
angleLabel(0, "0", SE);
angleLabel(pi, "\pi", SW);
angleLabel(pi/2, "\tfrac\pi2", NE);
