// y = sec theta = 1/cos theta over -2pi..2pi: U-shaped branches opening up
// with vertices (2k pi, 1) and opening down with vertices ((2k+1) pi, -1),
// between the vertical asymptotes theta = pi/2 + k pi at the zeros of
// cosine. One y unit is drawn 1.2 times as long as one x unit.
import _trig;

real sec(real t) { return 1 / cos(t); }

windowSetup(-2pi - 0.35, 2pi + 0.35, -3.5, 3.5, ystretch=1.2);
piGrid(2, 1);
for (int k = -2; k <= 1; ++k) asymptoteV(pi/2 + k * pi);
piTicksX(2);
numTicksY(1);
drawFunction(sec, -2pi, 2pi);
trigAxes("\theta");
originLabel(SW);
