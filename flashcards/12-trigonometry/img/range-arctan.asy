// The range of arctan, (-pi/2, pi/2), on the unit circle: the right
// semicircle without its ends (cos theta = 0 there, so tan theta is
// undefined).
import _trig;

windowSetup(-1.35, 1.35, -1.35, 1.35);
unitCircle();
rangeArc(-pi/2, pi/2);
trigAxes();
arcEnd(pi/2, false);
arcEnd(-pi/2, false);
angleLabel(pi/2, "\tfrac\pi2", NE);
angleLabel(-pi/2, "-\tfrac\pi2", SE);
