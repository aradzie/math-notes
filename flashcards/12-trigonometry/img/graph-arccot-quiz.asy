// graph-arccot.asy reduced to the curve y = arccot x alone -- no legend,
// base curve or mirror line -- for the card asking which function the graph
// shows.
import _trig;

real arccot(real x) { return pi/2 - atan(x); }

windowSetup(-4, 4, -3.5, 4);
vgrid(seq(-4, 4, 1), wy0, wy1);
hgrid(seq(-pi, pi, pi/2), wx0, wx1);
asymptoteH(pi);
numTicksX(1);
piTicksY(2, arccot);
drawFunction(arccot, -4, 4);
trigAxes();
originLabel(SE);
