// y = cos theta over two periods, -2pi..2pi: value 1 at the origin, zeros at
// pi/2 + k pi, troughs -1 at pi + 2k pi. One y unit is drawn 2.5 times as
// long as one x unit.
import _trig;

windowSetup(-2pi - 0.35, 2pi + 0.35, -1.6, 1.6, ystretch=2.5);
piGrid(2, 1);
piTicksX(2, cos);
numTicksY(1);
drawFunction(cos, -2pi, 2pi);
trigAxes("\theta");
originLabel(SW);
