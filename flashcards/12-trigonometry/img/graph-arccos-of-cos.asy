// y = arccos(cos x) over -2pi..2pi: an even triangle wave of period 2pi and
// slopes +-1 between the troughs 2k pi (value 0) and the peaks pi + 2k pi
// (value pi). It agrees with the identity line y = x (faint dotted) only on
// [0, pi]. Equal scale, so the slopes read as +-1.
import _trig;

windowSetup(-2pi - 0.35, 2pi + 0.35, -0.9, 3.9);
vgrid(seq(-2pi, 2pi, pi/2), wy0, wy1);
hgrid(seq(0, pi, pi), wx0, wx1);
mirrorLine();
piTicksX(2);
piTicksY(1);
drawFunction(new real(real x) { return acos(cos(x)); }, -2pi, 2pi);
trigAxes();
originLabel(SE);
