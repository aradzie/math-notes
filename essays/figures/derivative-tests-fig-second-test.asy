// Second derivative test: at a horizontal tangent, f'' > 0 puts the graph
// above it and f'' < 0 below it; without f'(c) = 0, f''(c) > 0 says nothing.
import _essayfigs;

setup(8);
setScale(1);

pen tangentPen = accent + linewidth(0.9pt) + linetype(new real[] {4, 3});

void finish(Window w, string title, string note) {
    axes(w);
    put("$x$", (w.x1, 0), E);
    put(title, (0, w.y1), N);
    put("\parbox{4.4cm}{\centering " + note + "}", (w.center().x, w.y0), S);
}

Window wa = Window(-1.6, 1.6, -0.5, 5.8);

// (a) x^2 + 3
panel((-5.2, 0), wa, 1.35, 0.5);
seg((-1, 3), (1, 3), tangentPen);
drawParam(wa, new pair(real t) { return (t, t^2 + 3); }, -1.5, 1.5, thickPen);
blackDot((0, 3));
put("$y=3$", (1, 3), E);
finish(wa, "$f(x)=x^{2}+3$",
       "$f'(0)=0$, $f''(0)=2>0$:\\ strict minimum");

// (b) 5 - x^2
panel((0, 0), wa, 1.35, 0.5);
seg((-1, 5), (1, 5), tangentPen);
drawParam(wa, new pair(real t) { return (t, 5 - t^2); }, -1.5, 1.5, thickPen);
blackDot((0, 5));
put("$y=5$", (1, 5), E);
finish(wa, "$f(x)=5-x^{2}$",
       "$f'(0)=0$, $f''(0)=-2<0$:\\ strict maximum");

// (c) x^2 + x: f''(0) > 0 but the tangent at 0 is not horizontal.
Window wc = Window(-1.6, 1.2, -0.75, 2.35);
panel((5.0, 0), wc, 1.35, 1.0);
seg((-0.65, -0.65), (1.1, 1.1), tangentPen);
seg((-0.9, -0.25), (-0.1, -0.25), dashPen);
drawParam(wc, new pair(real t) { return (t, t^2 + t); }, -1.5, 1.05, thickPen);
blackDot((0, 0));
blackDot((-0.5, -0.25));
put("$f'(0)=1$", (0.1, 0), SE);
tickX(-0.5, "$-\tfrac12$", N);
finish(wc, "$f(x)=x^{2}+x$",
       "$f''(0)=2>0$ but $f'(0)\neq0$:\\ no extremum at $0$");
