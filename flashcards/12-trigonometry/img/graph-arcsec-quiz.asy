// graph-arcsec.asy reduced to the curve y = arcsec x alone -- no legend,
// base curve or mirror line -- for the card asking which function the graph
// shows.
import _trig;

real arcsec(real x) { return acos(1 / x); }

windowSetup(-4, 4, -3.5, 4);
vgrid(seq(-4, 4, 1), wy0, wy1);
hgrid(seq(-pi, pi, pi/2), wx0, wx1);
asymptoteH(pi/2);
numTicksX(1);
piTicksY(2);
drawFunction(arcsec, 1, 4);
drawFunction(arcsec, -4, -1);
trigAxes();
originLabel(SE);
closedEnd((1, 0));
closedEnd((-1, pi));
