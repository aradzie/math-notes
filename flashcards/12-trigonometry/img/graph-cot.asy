// y = cot theta over -2pi..2pi: decreasing branches between the vertical
// asymptotes theta = k pi, with zeros at pi/2 + k pi. One y unit is drawn
// 1.2 times as long as one x unit.
import _trig;

real cot(real t) { return cos(t) / sin(t); }

windowSetup(-2pi - 0.35, 2pi + 0.35, -3.5, 3.5, ystretch=1.2);
piGrid(2, 1);
for (int k = -2; k <= 2; ++k) asymptoteV(k * pi);
piTicksX(2, cot);
numTicksY(1, negDir=E);
drawFunction(cot, -2pi, 2pi);
trigAxes("\theta");
originLabel(SE);
