// Restricted trig functions (thin) and their inverses (thick blue), with the
// unrestricted function in light gray behind. Six panels in a 3x2 grid, all the same window so the axes align.
import _essayfigs;

setup(7);
setScale(0.6);

real eps = 2e-3;

// y = f(x) on [a,b] and its reflection x = f(y).
void pairOf(Window w, real f(real), real a, real b, bool dots=false) {
    drawParam(w, new pair(real t) { return (t, f(t)); }, a, b, thinPen);
    drawParam(w, new pair(real t) { return (f(t), t); }, a, b, thickPen);
}
void natural(Window w, real f(real)) {
    drawParam(w, new pair(real t) { return (t, f(t)); }, w.x0, w.x1, faintPen, 2400);
}
void vline(Window w, real x) { draw(T * ((x, w.y0)--(x, w.y1)), dashPen); }
void hline(Window w, real y) { draw(T * ((w.x0, y)--(w.x1, y)), dashPen); }
// Closed endpoint (a, f(a)) of the restricted function (black) and its mirror image (blue).
void endPair(real a, real fa) { blackDot((a, fa)); closedDot((fa, a)); }

void begin(pair cell, Window w) {
    T = shift(cell - w.center());
    identityLine(w);
}

void finish(Window w, string title) {
    axes(w);
    for (int k = -4; k <= 4; ++k) {
        real v = k * pi / 2;
        if (k == 0) continue;
        if (v > w.x0 + 0.5 && v < w.x1 - 0.5) tickX(v, piLabel(k), S);
        if (v > w.y0 + 0.5 && v < w.y1 - 0.5) tickY(v, piLabel(k), W);
    }
    tickX(1, "$1$", N); tickX(-1, "$-1$", N);
    tickY(1, "$1$", E); tickY(-1, "$-1$", E);
    put(title, (w.center().x, w.y1), N);
}

// Division that returns a huge value, not an error, at a pole.
real over(real a, real b) { return b == 0 ? 1e9 : a / b; }
real cot(real t) { return over(cos(t), sin(t)); }
real sec(real t) { return over(1, cos(t)); }
real csc(real t) { return over(1, sin(t)); }

// Every panel shares one window, so all axes sit on common grid lines.
Window W = Window(-4, 4, -4, 4);
real[] cx = {-8.8, 0, 8.8};
pair cell(int row, int col) { return (cx[col], row == 0 ? 4.9 : -4.9); }

// Row 1: arcsin, arctan, arcsec.  Row 2: arccos, arccot, arccsc.

// arcsin
begin(cell(0, 0), W); natural(W, sin);
pairOf(W, sin, -pi/2, pi/2);
endPair(-pi/2, -1); endPair(pi/2, 1);
finish(W, "$\arcsin$");

// arctan
begin(cell(0, 1), W); natural(W, tan);
vline(W, -pi/2); vline(W, pi/2); hline(W, -pi/2); hline(W, pi/2);
pairOf(W, tan, -pi/2 + eps, pi/2 - eps);
finish(W, "$\arctan$");

// arcsec
begin(cell(0, 2), W); natural(W, sec);
vline(W, pi/2); hline(W, pi/2);
pairOf(W, sec, 0, pi/2 - eps);
pairOf(W, sec, pi/2 + eps, pi);
endPair(0, 1); endPair(pi, -1);
finish(W, "$\arcsec$");

// arccos
begin(cell(1, 0), W); natural(W, cos);
pairOf(W, cos, 0, pi);
endPair(0, 1); endPair(pi, -1);
finish(W, "$\arccos$");

// arccot
begin(cell(1, 1), W); natural(W, cot);
vline(W, 0); vline(W, pi); hline(W, 0); hline(W, pi);
pairOf(W, cot, eps, pi - eps);
finish(W, "$\arccot$");

// arccsc
begin(cell(1, 2), W); natural(W, csc);
vline(W, 0); hline(W, 0);
pairOf(W, csc, -pi/2, -eps);
pairOf(W, csc, eps, pi/2);
endPair(-pi/2, -1); endPair(pi/2, 1);
finish(W, "$\arccsc$");
