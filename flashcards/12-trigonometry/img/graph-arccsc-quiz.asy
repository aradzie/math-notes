// graph-arccsc.asy reduced to the curve y = arccsc x alone -- no legend,
// base curve or mirror line -- for the card asking which function the graph
// shows. The branch for x <= -1 runs just below the axis, so the negative
// x-tick labels go above it.
import _trig;

real arccsc(real x) { return asin(1 / x); }

windowSetup(-4, 4, -4, 4);
vgrid(seq(-4, 4, 1), wy0, wy1);
hgrid(seq(-pi, pi, pi/2), wx0, wx1);
numTicksX(1, negDir=N);
piTicksY(2);
drawFunction(arccsc, 1, 4);
drawFunction(arccsc, -4, -1);
trigAxes();
originLabel(SE);
closedEnd((1, pi/2));
closedEnd((-1, -pi/2));
