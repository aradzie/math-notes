// x^3: concave down for x < 0 (tangents above the graph), concave up for
// x > 0 (tangents below); at the inflection point 0 the tangent crosses.
import _essayfigs;

setup(8);
setScale(1);

Window w = Window(-1.5, 1.5, -1.6, 1.6);
panel((0, 0), w, 2.1);

fill(T * ((w.x0, w.y0)--(0, w.y0)--(0, w.y1)--(w.x0, w.y1)--cycle), gray(0.93));
fill(T * ((0, w.y0)--(w.x1, w.y0)--(w.x1, w.y1)--(0, w.y1)--cycle), accent + opacity(0.07));

real f(real x) { return x^3; }
void tangent(real a, real h=0.28) {
    real m = 3a^2;
    seg((a - h, f(a) - h * m), (a + h, f(a) + h * m), black + linewidth(0.7pt));
    blackDot((a, f(a)), 1.8);
}

seg((-0.9, 0), (0.9, 0), accent + linewidth(0.9pt) + linetype(new real[] {4, 3}));
drawParam(w, new pair(real t) { return (t, f(t)); }, -1.2, 1.2, thickPen);
tangent(-0.8);
tangent(0.8);
blackDot((0, 0));

axes(w);
tickX(1, "$1$"); tickX(-1, "$-1$");
put("$x$", (w.x1, 0), E);
put("$f(x)=x^{3}$", (0, w.y1), N);

put("\parbox{2.6cm}{\centering concave down\\ $f''(x)=6x<0$}", (-0.75, 1.15));
put("\parbox{2.6cm}{\centering concave up\\ $f''(x)=6x>0$}", (0.75, -1.15));
put("inflection point", (-0.08, 0.08), NW);
