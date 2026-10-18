// Critical point vs extremum: x^3 has f'(0)=0 but no extremum; |x| has a
// minimum at 0 where f'(0) does not exist.
import _essayfigs;

setup(8);
setScale(1);

Window w = Window(-1.5, 1.5, -1.5, 1.5);
real s = 1.8;   // cm per unit

void finish(string title, string note) {
    axes(w);
    tickX(1, "$1$"); tickX(-1, "$-1$");
    tickY(1, "$1$"); tickY(-1, "$-1$");
    put("$x$", (w.x1, 0), E);
    put(title, (0, w.y1), N);
    put(note, (0, w.y0), S);
}

// x^3: the horizontal tangent at 0 is the x-axis itself, and the graph crosses it.
panel((-3.6, 0), w, s);
seg((-0.9, 0), (0.9, 0), accent + linewidth(0.9pt) + linetype(new real[] {4, 3}));
drawParam(w, new pair(real t) { return (t, t^3); }, -1.2, 1.2, thickPen);
blackDot((0, 0));
put("$f'(0)=0$", (-0.15, 0), NW);
put("$f<0$", (-0.95, -0.35), W);
put("$f>0$", (0.95, 0.35), E);
finish("$f(x)=x^{3}$", "critical point, not an extremum");

// |x|: a corner minimum.
panel((3.6, 0), w, s);
drawParam(w, new pair(real t) { return (t, abs(t)); }, -1.3, 1.3, thickPen);
blackDot((0, 0));
put("$f'(0)$ does not exist", (0.12, -0.45), E);
finish("$f(x)=|x|$", "strict minimum, not a stationary point");
