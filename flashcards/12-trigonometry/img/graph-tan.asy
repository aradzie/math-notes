// y = tan theta over two periods' worth of window, -2pi..2pi: increasing
// branches through the multiples of pi, between the vertical asymptotes
// theta = pi/2 + k pi. One y unit is drawn 1.2 times as long as one x unit.
import _trig;

windowSetup(-2pi - 0.35, 2pi + 0.35, -3.5, 3.5, ystretch=1.2);
piGrid(2, 1);
for (int k = -2; k <= 1; ++k) asymptoteV(pi/2 + k * pi);
piTicksX(2, tan);
numTicksY(1);
drawFunction(tan, -2pi, 2pi);
trigAxes("\theta");
originLabel(SE);
