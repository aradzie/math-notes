// f'(0) = f''(0) = 0 is compatible with all three outcomes: x^4 (minimum),
// -x^4 (maximum), x^3 (neither). Dashed gray: +-x^2, to show how flat the
// quartics are at 0.
import _essayfigs;

setup(8);
setScale(1);

Window w = Window(-1.35, 1.35, -1.35, 1.35);
real s = 1.75;

void quad(real sign) {
    drawParam(w, new pair(real t) { return (t, sign * t^2); }, w.x0, w.x1, dashPen);
}
void graph(real f(real)) {
    drawParam(w, new pair(real t) { return (t, f(t)); }, w.x0, w.x1, thickPen);
    blackDot((0, 0));
}
void finish(string title, string note) {
    axes(w);
    tickX(1, "$1$"); tickX(-1, "$-1$");
    put("$x$", (w.x1, 0), E);
    put(title, (0, w.y1), N);
    put(note, (0, w.y0), S);
}

panel((-5.3, 0), w, s);
quad(1);
graph(new real(real x) { return x^4; });
put("$x^{2}$", (1.17, 1.3), E, gray(0.4));
finish("$f(x)=x^{4}$", "strict minimum");

panel((0, 0), w, s);
quad(-1);
graph(new real(real x) { return -x^4; });
put("$-x^{2}$", (1.17, -1.3), E, gray(0.4));
finish("$f(x)=-x^{4}$", "strict maximum");

panel((5.3, 0), w, s);
graph(new real(real x) { return x^3; });
finish("$f(x)=x^{3}$", "neither (inflection point)");
