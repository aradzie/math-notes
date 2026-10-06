// y = arcsin x, range [-pi/2, pi/2]: the reflection across y = x of sin
// restricted to that range (faint gray). Increasing from (-1, -pi/2) through
// the origin to (1, pi/2). Equal scale, so the two graphs are true mirror
// images.
import _trig;

windowSetup(-2.2, 2.2, -2.2, 2.2);
vgrid(seq(-2, 2, 1), wy0, wy1);
hgrid(seq(-pi/2, pi/2, pi/2), wx0, wx1);
mirrorLine();
numTicksX(1);
piTicksY(2);
drawFunction(sin, -pi/2, pi/2, cp=otherPen);
drawFunction(asin, -1, 1);
trigAxes();
originLabel(SE);
baseEnd((-pi/2, -1));
baseEnd((pi/2, 1));
closedEnd((-1, -pi/2));
closedEnd((1, pi/2));
inverseLegend((-2.0, 1.2), "\arcsin x", "\sin x");
