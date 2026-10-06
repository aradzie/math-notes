// y = arccos x, range [0, pi]: the reflection across y = x of cos restricted
// to that range (faint gray). Decreasing from (-1, pi) through (0, pi/2) to
// (1, 0). Equal scale, so the two graphs are true mirror images.
import _trig;

windowSetup(-1.8, 3.8, -1.8, 3.8);
vgrid(seq(-1, 3, 1), wy0, wy1);
hgrid(seq(-pi/2, pi, pi/2), wx0, wx1);
mirrorLine();
numTicksX(1);
piTicksY(2, acos);
drawFunction(cos, 0, pi, cp=otherPen);
drawFunction(acos, -1, 1);
trigAxes();
originLabel(SE);
baseEnd((0, 1));
baseEnd((pi, -1));
closedEnd((-1, pi));
closedEnd((1, 0));
inverseLegend((1.2, 3.65), "\arccos x", "\cos x");
