// y = arctan(tan x) over -2pi..2pi: a sawtooth of period pi, equal to x - k pi
// on each interval (k pi - pi/2, k pi + pi/2), with open ends at the points
// (pi/2 + k pi, +-pi/2) and no value at x = pi/2 + k pi. It agrees with the
// identity line y = x (faint dotted) only on (-pi/2, pi/2). Equal scale, so
// the slopes read as 1.
import _trig;

windowSetup(-2pi - 0.35, 2pi + 0.35, -2.2, 2.2);
vgrid(seq(-2pi, 2pi, pi/2), wy0, wy1);
hgrid(seq(-pi/2, pi/2, pi/2), wx0, wx1);
mirrorLine();
asymptoteV(-3pi/2);
asymptoteV(-pi/2);
asymptoteV(pi/2);
asymptoteV(3pi/2);
piTicksX(2, new real(real x) { return x - pi * round(x / pi); });
piTicksY(2);
for (int k = -2; k <= 2; ++k) {
    real c = k * pi;
    drawFunction(new real(real x) { return x - c; }, max(c - pi/2, -2pi), min(c + pi/2, 2pi));
}
for (int k = -2; k <= 1; ++k) {
    openEnd((k * pi + pi/2, pi/2));
    openEnd((k * pi + pi/2, -pi/2));
}
trigAxes();
originLabel(SE);
