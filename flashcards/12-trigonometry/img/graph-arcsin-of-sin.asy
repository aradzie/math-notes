// y = arcsin(sin x) over -2pi..2pi: a triangle wave of period 2pi and slopes
// +-1 between the peaks pi/2 + 2k pi (value pi/2) and the troughs 3pi/2 +
// 2k pi (value -pi/2). It agrees with the identity line y = x (faint dotted)
// only on [-pi/2, pi/2]. Equal scale, so the slopes read as +-1.
import _trig;

windowSetup(-2pi - 0.35, 2pi + 0.35, -2.2, 2.2);
vgrid(seq(-2pi, 2pi, pi/2), wy0, wy1);
hgrid(seq(-pi/2, pi/2, pi/2), wx0, wx1);
mirrorLine();
piTicksX(2, new real(real x) { return asin(sin(x)); });
piTicksY(2);
drawFunction(new real(real x) { return asin(sin(x)); }, -2pi, 2pi);
trigAxes();
originLabel(SE);
