// y = arcsec x, range [0, pi/2) U (pi/2, pi]: the reflection across y = x
// of sec restricted to that range (faint gray). Two branches, from (1, 0)
// and from (-1, pi), both approaching the asymptote y = pi/2 as |x| grows.
// Equal scale, so the two graphs are true mirror images.
import _trig;

real sec(real t) { return 1 / cos(t); }
real arcsec(real x) { return acos(1 / x); }

windowSetup(-4, 4, -3.5, 4);
vgrid(seq(-4, 4, 1), wy0, wy1);
hgrid(seq(-pi, pi, pi/2), wx0, wx1);
mirrorLine();
asymptoteH(pi/2);
numTicksX(1);
piTicksY(2);
drawFunction(sec, 0, pi, cp=otherPen);
drawFunction(arcsec, 1, 4);
drawFunction(arcsec, -4, -1);
trigAxes();
originLabel(SE);
baseEnd((0, 1));
baseEnd((pi, -1));
closedEnd((1, 0));
closedEnd((-1, pi));
inverseLegend((-3.75, -0.85), "\operatorname{arcsec} x", "\sec x");
