// First derivative test: the graph of f near c above a sign chart of f'.
// Minimum (- to +), maximum (+ to -), and no extremum (+ to +, as for x^3).
import _essayfigs;

setup(8);
setScale(1);

Window w = Window(-1.25, 1.25, -0.75, 1.5);
real s = 1.95;     // cm per unit
real line = -0.4;  // height of the sign chart's number line

pen slopePen = black + linewidth(0.7pt);
pen signPen = fontsize(10pt);

// Short tangent segment at x = a, of half-width h.
void tangent(real f(real), real df(real), real a, real h=0.22) {
    seg((a - h, f(a) - h * df(a)), (a + h, f(a) + h * df(a)), slopePen);
}

void chart(real f(real), real df(real), string left, string right,
           string title, string rule) {
    // horizontal tangent at c, dropped to the number line
    seg((-0.45, f(0)), (0.45, f(0)), dashPen);
    draw(T * ((0, f(0))--(0, line)), dashPen);
    drawParam(w, new pair(real t) { return (t, f(t)); }, -1.1, 1.1, thickPen);
    tangent(f, df, -0.7);
    tangent(f, df, 0.7);
    blackDot((0, f(0)));

    draw(T * ((w.x0, line)--(w.x1, line)), axisPen);
    tickX(0, "$c$", S, line);
    put(left, (-0.6, line), N, signPen);
    put(right, (0.6, line), N, signPen);
    put("sign of $f'$", (w.x1, line), SW);

    put(title, (0, w.y1 + 0.2), N);
    put(rule, (0, w.y1), N);
}

real[] cx = {-5.3, 0, 5.3};

panel((cx[0], 0), w, s);
chart(new real(real x) { return 0.25 + x^2; }, new real(real x) { return 2x; },
      "$-$", "$+$", "local minimum", "$-\longrightarrow+$");

panel((cx[1], 0), w, s);
chart(new real(real x) { return 1.3 - x^2; }, new real(real x) { return -2x; },
      "$+$", "$-$", "local maximum", "$+\longrightarrow-$");

panel((cx[2], 0), w, s);
chart(new real(real x) { return 0.85 + 0.45x^3; }, new real(real x) { return 1.35x^2; },
      "$+$", "$+$", "no extremum", "$+\longrightarrow+$");
