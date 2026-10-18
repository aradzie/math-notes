// f(x) = e^{-1/x^2}, f(0) = 0: smooth, every derivative at 0 vanishes, yet 0
// is a strict minimum. Right: near 0 it lies below even x^6.
import _essayfigs;

setup(8);
setScale(1);

real f(real x) { return x == 0 ? 0 : exp(-1 / x^2); }
pen powPen = gray(0.45) + linewidth(0.7pt);

// Overall shape, with the zoom window marked.
Window wa = Window(-3.2, 3.2, -0.25, 1.3);
panel((-4.2, 0), wa, 0.95, 2.4);
seg((wa.x0, 1), (wa.x1, 1), dashPen);
drawParam(wa, new pair(real t) { return (t, f(t)); }, -3.1, 3.1, thickPen);
draw(T * box((-0.6, 0), (0.6, 0.07)), black + linewidth(0.5pt));
blackDot((0, 0));
axes(wa);
tickX(1, "$1$"); tickX(-1, "$-1$"); tickX(2, "$2$"); tickX(-2, "$-2$");
tickY(1, "$1$", NW);
put("$x$", (wa.x1, 0), E);
put("$f(x)=e^{-1/x^{2}}$, $f(0)=0$", (0, wa.y1), N);

// Zoom near 0: x^2 and x^4 leave quickly, x^6 stays above f near 0.
Window wb = Window(-0.65, 0.65, -0.008, 0.075);
panel((3.9, 0), wb, 5.4, 44);
for (int n : new int[] {2, 4, 6})
    drawParam(wb, new pair(real t) { return (t, t^n); }, wb.x0, wb.x1, powPen);
drawParam(wb, new pair(real t) { return (t, f(t)); }, -0.62, 0.62, thickPen);
blackDot((0, 0));
axes(wb);
tickX(0.5, "$0.5$"); tickX(-0.5, "$-0.5$");
tickY(0.05, "$0.05$");
put("$x$", (wb.x1, 0), E);
put("$x^{2}$", (0.27, 0.07), W, gray(0.35));
put("$x^{4}$", (0.51, 0.068), W, gray(0.35));
put("$x^{6}$", (0.62, 0.0568), E, gray(0.35));
put("$f$", (0.535, f(0.535)), W, accent);
put("zoom: $|x|\le 0.6$, $0\le y\le 0.07$", (0, wb.y1), N);
