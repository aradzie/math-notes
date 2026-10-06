// y = csc theta = 1/sin theta over -2pi..2pi: U-shaped branches opening up
// with vertices (pi/2 + 2k pi, 1) and opening down with vertices
// (3pi/2 + 2k pi, -1), between the vertical asymptotes theta = k pi at the
// zeros of sine. One y unit is drawn 1.2 times as long as one x unit.
import _trig;

real csc(real t) { return 1 / sin(t); }

windowSetup(-2pi - 0.35, 2pi + 0.35, -3.5, 3.5, ystretch=1.2);
piGrid(2, 1);
for (int k = -2; k <= 2; ++k) asymptoteV(k * pi);
piTicksX(2);
numTicksY(1, negDir=E);
drawFunction(csc, -2pi, 2pi);
trigAxes("\theta");
originLabel(SE);
