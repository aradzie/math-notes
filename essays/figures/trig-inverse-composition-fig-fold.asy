// The folding compositions f^{-1}(f(x)) on [-2pi, 2pi]: identity on the
// principal range (thick blue), folded back into it elsewhere (thin).
import _essayfigs;

setup(8);
setScale(1.1);

real L = 2pi;

// Reduce x into the principal range by the fold of each function.
real foldSin(real x) {
    real y = x - 2pi * floor((x + pi/2) / (2pi));   // [-pi/2, 3pi/2)
    return y <= pi/2 ? y : pi - y;
}
real foldCos(real x) { return abs(x - 2pi * floor((x + pi) / (2pi))); }

void curve(Window w, real f(real), real a, real b, pen p) {
    drawParam(w, new pair(real t) { return (t, f(t)); }, a, b, p, 3000);
}
void hline(Window w, real y, string s) {
    draw(T * ((w.x0, y)--(w.x1, y)), dashPen);
    put(s, (w.x0, y), W);
}
void grid(Window w) {
    for (int k = -4; k <= 4; ++k) {
        real x = k * pi / 2;
        draw(T * ((x, w.y0)--(x, w.y1)), gridPen);
        tickX(x, piLabel(k), S, w.y0);
    }
}
void begin(Window w, real cy) {
    T = shift((0, cy) - w.center());
    grid(w);
    identityLine(w);
}
void finish(Window w, string title) {
    axes(w);
    put(title, (w.x0, w.y1), NE);
}
void note(pair p, string s, pair at) {
    closedDot(p);
    seg(p, at, guidePen);
    put(s, at, E);
}

// Top: arcsin(sin x)
Window w1 = Window(-L - 0.3, L + 0.3, -1.9, 1.9);
begin(w1, 0);
hline(w1, pi/2, "$\pi/2$"); hline(w1, -pi/2, "$-\pi/2$");
curve(w1, foldSin, -L, L, thinPen);
curve(w1, foldSin, -pi/2, pi/2, thickPen);
note((3, pi - 3), "$\arcsin(\sin 3) = \pi - 3$", (3.5, 0.8));
finish(w1, "$y = \arcsin(\sin x)$");

// Middle: arccos(cos x)
Window w2 = Window(-L - 0.3, L + 0.3, -0.5, 3.7);
begin(w2, -5.7);
hline(w2, 0, "$0$"); hline(w2, pi, "$\pi$");
curve(w2, foldCos, -L, L, thinPen);
curve(w2, foldCos, 0, pi, thickPen);
note((-1, 1), "$\arccos(\cos(-1)) = 1$", (-3.7, 0.5));
finish(w2, "$y = \arccos(\cos x)$");

// Bottom: arctan(tan x), a sawtooth with jumps at pi/2 + k pi
Window w3 = Window(-L - 0.3, L + 0.3, -2.3, 2.0);
begin(w3, -11.6);
hline(w3, pi/2, "$\pi/2$"); hline(w3, -pi/2, "$-\pi/2$");
for (int k = -2; k <= 2; ++k) {
    real a = max(k * pi - pi/2, -L), b = min(k * pi + pi/2, L);
    drawParam(w3, new pair(real t) { return (t, t - k * pi); }, a, b,
              k == 0 ? thickPen : thinPen);
}
for (int k = -2; k <= 1; ++k) {
    real x = pi/2 + k * pi;
    draw(T * ((x, w3.y0)--(x, w3.y1)), dashPen);
    openDot((x, pi/2)); openDot((x, -pi/2));
}
note((2, 2 - pi), "$\arctan(\tan 2) = 2 - \pi$", (2.5, -1.95));
finish(w3, "$y = \arctan(\tan x)$");
