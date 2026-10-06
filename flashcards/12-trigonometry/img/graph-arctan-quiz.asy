// graph-arctan.asy reduced to the curve y = arctan x alone -- no legend,
// base curve or mirror line -- for the card asking which function the graph
// shows.
import _trig;

windowSetup(-4, 4, -4, 4);
vgrid(seq(-4, 4, 1), wy0, wy1);
hgrid(seq(-pi, pi, pi/2), wx0, wx1);
asymptoteH(-pi/2);
asymptoteH(pi/2);
numTicksX(1);
piTicksY(2);
drawFunction(atan, -4, 4);
trigAxes();
originLabel(SE);
