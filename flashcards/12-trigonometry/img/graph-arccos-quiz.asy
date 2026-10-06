// graph-arccos.asy reduced to the curve y = arccos x alone -- no legend,
// base curve or mirror line -- for the card asking which function the graph
// shows.
import _trig;

windowSetup(-1.8, 3.8, -1.8, 3.8);
vgrid(seq(-1, 3, 1), wy0, wy1);
hgrid(seq(-pi/2, pi, pi/2), wx0, wx1);
numTicksX(1);
piTicksY(2, acos);
drawFunction(acos, -1, 1);
trigAxes();
originLabel(SE);
closedEnd((-1, pi));
closedEnd((1, 0));
