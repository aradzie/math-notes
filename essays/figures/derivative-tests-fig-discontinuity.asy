// f(x) = x^2 for x != 0, f(0) = 1: the signs of f' look like a minimum, but
// without continuity at 0 the point is a strict maximum.
import _essayfigs;

setup(8);
setScale(1);

Window w = Window(-1.4, 1.4, -0.45, 1.5);
panel((0, 0), w, 2.4);

seg((-1.15, 1), (1.15, 1), dashPen);
drawParam(w, new pair(real t) { return (t, t^2); }, -1.15, 1.15, thickPen);
openDot((0, 0));
blackDot((0, 1));

axes(w);
tickX(1, "$1$"); tickX(-1, "$-1$");
tickY(1);
put("$x$", (w.x1, 0), E);
put("$f(0)=1$", (0.05, 1), NE);
put("$f(x)=x^{2}$, $x\neq0$", (0.62, 0.42), SE);
put("$f'<0$", (-0.6, 0), 2S);
put("$f'>0$", (0.6, 0), 2S);
