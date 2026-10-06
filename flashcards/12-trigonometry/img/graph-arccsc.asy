// y = arccsc x, range [-pi/2, 0) U (0, pi/2]: the reflection across y = x of
// csc restricted to that range (faint gray). Two branches, from (1, pi/2)
// and from (-1, -pi/2), both approaching the asymptote y = 0 (the x-axis)
// as |x| grows. The branch for x <= -1 runs just below the axis, so the
// negative x-tick labels go above it, and the negative y-tick labels right
// of the y-axis, clear of the base branch. Equal scale, so the two graphs are true
// mirror images.
import _trig;

real csc(real t) { return 1 / sin(t); }
real arccsc(real x) { return asin(1 / x); }

windowSetup(-4, 4, -4, 4);
vgrid(seq(-4, 4, 1), wy0, wy1);
hgrid(seq(-pi, pi, pi/2), wx0, wx1);
mirrorLine();
numTicksX(1, negDir=N);
piTicksY(2, negDir=E);
drawFunction(csc, -pi/2, -0.01, cp=otherPen);
drawFunction(csc, 0.01, pi/2, cp=otherPen);
drawFunction(arccsc, 1, 4);
drawFunction(arccsc, -4, -1);
trigAxes();
originLabel(SE);
baseEnd((-pi/2, -1));
baseEnd((pi/2, 1));
closedEnd((1, pi/2));
closedEnd((-1, -pi/2));
inverseLegend((-3.75, 2.7), "\operatorname{arccsc} x", "\csc x");
