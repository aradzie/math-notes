// The six trig functions of a first-quadrant angle theta as segments of the
// unit-circle picture: P = (cos t, sin t) on the arc, A = (cos t, 0) below
// it, B = (1, 0), T = (1, tan t) where ray OP meets the tangent x = 1,
// C = (0, 1), U = (cot t, 1) where it meets the tangent y = 1. Then
// AP = sin, OA = cos, BT = tan, CU = cot, OT = sec, OU = csc. The segments
// carry no names: the cards ask which is which. theta = 50 degrees.
import _trig;

real t = radians(50);
pair O = (0, 0), P = dir(50), A = (P.x, 0), B = (1, 0);
pair T = (1, tan(t)), C = (0, 1), U = (1 / tan(t), 1);

windowSetup(-0.3, 1.45, -0.3, 1.45);
// the two tangent lines, then the axes: drawn before the segments here,
// since OA and OB run along the x-axis and must stay on top of it
draw((1, 0)--(1, wy1), asymptotePen);
draw((0, 1)--(wx1, 1), asymptotePen);
trigAxes();
draw(arc(O, 1, 0, 90), circlePen);
draw(O--T, trianglePen);
draw(A--P, trianglePen);
draw(O--A, trianglePen);
draw(B--T, trianglePen);
draw(C--U, trianglePen);
draw(arc(O, 0.2, 0, 50), accentColor + linewidth(0.6pt));
ptLabel(0.2 * dir(25), "\theta", dir(25), accentColor);
pair[] pts = {O, P, A, B, T, C, U};
string[] names = {"O", "P", "A", "B", "T", "C", "U"};
pair[] dirs = {SW, W, S, SE, E, W, NW};
for (int i = 0; i < pts.length; ++i) {
    keyDot(pts[i]);
    ptLabel(pts[i], names[i], dirs[i]);
}
