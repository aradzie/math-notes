// y = arctan x, range (-pi/2, pi/2): the reflection across y = x of the
// central tan branch (faint gray). Increasing through the origin, approaching
// the asymptotes y = -pi/2 and y = pi/2 as x -> -oo and x -> +oo. Equal
// scale, so the two graphs are true mirror images.
import _trig;

windowSetup(-4, 4, -4, 4);
vgrid(seq(-4, 4, 1), wy0, wy1);
hgrid(seq(-pi, pi, pi/2), wx0, wx1);
mirrorLine();
asymptoteH(-pi/2);
asymptoteH(pi/2);
numTicksX(1);
piTicksY(2);
drawFunction(tan, -pi/2 + 0.01, pi/2 - 0.01, cp=otherPen);
drawFunction(atan, -4, 4);
trigAxes();
originLabel(SE);
inverseLegend((-3.75, 2.7), "\arctan x", "\tan x");
