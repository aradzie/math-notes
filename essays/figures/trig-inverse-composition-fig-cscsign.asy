// x = sec(theta) changes sign at pi/2 while sin(theta) >= 0 on all of
// [0, pi]. Two panels share the theta axis; the colour of each half
// (blue / gray) is the same in both, as in the secant figure.
import _essayfigs;

setup(8);
setScale(4.4, 0.4);

real eps = 2e-3;
real k = 3;                    // bottom panel plots k*sin(theta); the tick "1" sits at k
real gap = 0.8;

Window wb = Window(-0.1, pi + 0.25, -0.4, 3.7);
Window wt = Window(-0.1, pi + 0.25, -4.4, 4.4);
Window cwb = Window(0, pi, -0.4, 3.7);
Window cwt = Window(0, pi, -4, 4);
real top = wb.y1 + gap - wt.y0;                  // offset of the top panel

pen leftPen = accent + linewidth(1.6pt);
pen rightPen = gray(0.4) + linewidth(1.6pt);
pen leftFill = accent + opacity(0.12);
pen rightFill = gray(0.85);

transform Tb = identity();
transform Tt = shift((0, top));

real over(real a, real b) { return b == 0 ? 1e9 : a / b; }
real sec(real t) { return over(1, cos(t)); }
void branch(Window cw, real f(real), real a, real b, pen p) {
    drawParam(cw, new pair(real t) { return (t, f(t)); }, a, b, p, 3000);
}
// region under k*sin(theta) over [a, b]
path under(real a, real b) {
    path p = (a, 0);
    for (int i = 0; i <= 200; ++i) { real t = a + (b - a) * i / 200; p = p--(t, k * sin(t)); }
    return p--(b, 0)--cycle;
}

// gridlines and the shared asymptote
for (int i = 0; i <= 4; ++i) {
    real x = i * pi / 4;
    T = Tb; draw(T * ((x, wb.y0)--(x, wb.y1)), gridPen);
    T = Tt; draw(T * ((x, wt.y0)--(x, wt.y1)), gridPen);
}
draw((pi/2, wb.y0)--(pi/2, top + wt.y1), dashPen);

// ---- bottom panel: sin(theta) -------------------------------------------
T = Tb;
fill(T * under(0, pi/2), leftFill);
fill(T * under(pi/2, pi), rightFill);
branch(cwb, new real(real t) { return k * sin(t); }, 0, pi/2, leftPen);
branch(cwb, new real(real t) { return k * sin(t); }, pi/2, pi, rightPen);
axes(wb);
for (int i = 0; i <= 4; ++i) tickX(i * pi/4, i == 0 ? "$0$" : i == 1 ? "$\pi/4$" : i == 2 ? "$\pi/2$" : i == 3 ? "$3\pi/4$" : "$\pi$", S, wb.y0);
tickY(k, "$1$");
put("$\theta$", (wb.x1, 0), E);
put("$\sin\theta \ge 0$ on all of $[0, \pi]$", (pi - 0.05, 3.4), SW);

// ---- top panel: x = sec(theta) -------------------------------------------
T = Tt;
fill(T * ((0,1)--(pi/2,1)--(pi/2,4)--(0,4)--cycle), leftFill);
fill(T * ((pi/2,-4)--(pi,-4)--(pi,-1)--(pi/2,-1)--cycle), rightFill);
draw(T * ((0, 1)--(pi, 1)), guidePen + dotted);
draw(T * ((0, -1)--(pi, -1)), guidePen + dotted);
branch(cwt, sec, 0, pi/2 - eps, leftPen);
branch(cwt, sec, pi/2 + eps, pi, rightPen);
axes(wt);
tickX(0); tickX(pi/2); tickX(pi);
tickY(1, "$1$"); tickY(-1, "$-1$");
put("$x$", (0, wt.y1), N);
put("$\theta$", (wt.x1, 0), E);
closedDot((0, 1)); closedDot((pi, -1));
put("$x = \sec\theta$ changes sign at $\pi/2$", (pi - 0.05, 3.6), SW);
