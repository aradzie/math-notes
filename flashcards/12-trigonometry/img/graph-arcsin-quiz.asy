// graph-arcsin.asy reduced to the curve y = arcsin x alone -- no legend,
// base curve or mirror line -- for the card asking which function the graph
// shows.
import _trig;

windowSetup(-2.2, 2.2, -2.2, 2.2);
vgrid(seq(-2, 2, 1), wy0, wy1);
hgrid(seq(-pi/2, pi/2, pi/2), wx0, wx1);
numTicksX(1);
piTicksY(2);
drawFunction(asin, -1, 1);
trigAxes();
originLabel(SE);
closedEnd((-1, -pi/2));
closedEnd((1, pi/2));
