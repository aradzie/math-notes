// y = arccot x, range (0, pi): the reflection across y = x of cot restricted
// to that range (faint gray). Decreasing through (0, pi/2), approaching the
// asymptotes y = pi as x -> -oo and y = 0 (the x-axis) as x -> +oo. Equal
// scale, so the two graphs are true mirror images.
import _trig;

real cot(real t) { return cos(t) / sin(t); }
real arccot(real x) { return pi/2 - atan(x); }

windowSetup(-4, 4, -3.5, 4);
vgrid(seq(-4, 4, 1), wy0, wy1);
hgrid(seq(-pi, pi, pi/2), wx0, wx1);
mirrorLine();
asymptoteH(pi);
numTicksX(1);
piTicksY(2, arccot);
drawFunction(cot, 0.01, pi - 0.01, cp=otherPen);
drawFunction(arccot, -4, 4);
trigAxes();
originLabel(SE);
inverseLegend((-3.75, -0.85), "\operatorname{arccot} x", "\cot x");
