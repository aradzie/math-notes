// y = sin theta over two periods, -2pi..2pi: rising through the origin, peaks
// 1 at pi/2 + 2k pi, troughs -1 at 3pi/2 + 2k pi, zeros at the multiples of
// pi. One y unit is drawn 2.5 times as long as one x unit.
import _trig;

windowSetup(-2pi - 0.35, 2pi + 0.35, -1.6, 1.6, ystretch=2.5);
piGrid(2, 1);
piTicksX(2, sin);
numTicksY(1);
drawFunction(sin, -2pi, 2pi);
trigAxes("\theta");
originLabel(SE);
