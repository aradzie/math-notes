// Concave up (convex), two ways: the graph lies on or below each chord, and
// on or above each tangent line.
import _essayfigs;

setup(8);
setScale(1);

real f(real x) { return 0.28x^2 + 0.3; }
real df(real x) { return 0.56x; }

Window w = Window(-1.75, 2.45, -0.15, 1.8);
real s = 1.6;

void base(string title, string rule) {
    drawParam(w, new pair(real t) { return (t, f(t)); }, -1.55, 2.2, thickPen);
    axes(w, w.x0, 0);
    put(title, (w.center().x, w.y1 + 0.25), N);
    put(rule, (w.center().x, w.y1), N);
}

// Chord from (x, f(x)) to (y, f(y)), with the gap at z = tx + (1-t)y.
panel((-3.7, 0), w, s);
real x = -1.3, y = 2.0, t = 0.55, z = t * x + (1 - t) * y;
real cz = t * f(x) + (1 - t) * f(y);
base("graph on or below each chord", "$f(tx+(1-t)y)\le tf(x)+(1-t)f(y)$");
seg((x, f(x)), (y, f(y)), black + linewidth(0.8pt));
seg((x, 0), (x, f(x)), dashPen);
seg((y, 0), (y, f(y)), dashPen);
draw(T * ((z, f(z))--(z, cz)), black + linewidth(0.6pt), Arrows(TeXHead, size=2));
blackDot((x, f(x))); blackDot((y, f(y)));
blackDot((z, f(z)), 1.8); blackDot((z, cz), 1.8);
tickX(x, "$x$"); tickX(y, "$y$"); tickX(z, "$tx+(1-t)y$");
put("$tf(x)+(1-t)f(y)$", (z, cz), NW);
put("$f(tx+(1-t)y)$", (z, f(z)), S);

// Tangent line at a, lying below the graph.
panel((3.5, 0), w, s);
real a = 1.1;
base("graph on or above each tangent line", "$f(x)\ge f(a)+f'(a)(x-a)$");
draw(T * ((a, f(a))--(a, 0)), dashPen);
seg((0.15, f(a) + (0.15 - a) * df(a)), (2.1, f(a) + (2.1 - a) * df(a)),
    black + linewidth(0.8pt));
blackDot((a, f(a)));
tickX(a, "$a$");
put("tangent at $a$", (2.1, f(a) + (2.1 - a) * df(a)), SE);
put("$y=f(x)$", (-1.2, f(-1.2)), NE);
