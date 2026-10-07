// x = sec(theta) on [0, pi]: the two branches map onto the two components of
// the x-domain; tan(theta) changes sign across pi/2.
import _essayfigs;

setup(8);
setScale(4.4, 0.68);

real eps = 2e-3;
Window cw = Window(0, pi, -4, 4);              // where curves are drawn
Window w = Window(-0.1, pi + 0.25, -4.4, 4.4); // axes extent

pen secPen = black + linewidth(1.6pt);
pen tanPen = gray(0.5) + linewidth(0.7pt);

// shaded regions behind everything
fill(T * ((0,1)--(pi/2,1)--(pi/2,4)--(0,4)--cycle), accent + opacity(0.12));
fill(T * ((pi/2,-4)--(pi,-4)--(pi,-1)--(pi/2,-1)--cycle), gray(0.85));

// vertical gridlines + labels at the bottom edge
string[] xl = {"$0$", "$\pi/4$", "$\pi/2$", "$3\pi/4$", "$\pi$"};
for (int i = 0; i <= 4; ++i) {
    real x = i * pi / 4;
    draw(T * ((x, w.y0)--(x, w.y1)), gridPen);
    tickX(x);
    tickX(x, xl[i], S, w.y0);
}
draw(T * ((pi/2, w.y0)--(pi/2, w.y1)), dashPen);                       // asymptote
draw(T * ((0, 1)--(pi, 1)), guidePen + dotted);
draw(T * ((0, -1)--(pi, -1)), guidePen + dotted);

void branch(real f(real), real a, real b, pen p) {
    drawParam(cw, new pair(real t) { return (t, f(t)); }, a, b, p, 3000);
}
real over(real a, real b) { return b == 0 ? 1e9 : a / b; }
real sec(real t) { return over(1, cos(t)); }
real tan2(real t) { return over(sin(t), cos(t)); }
for (real[] iv : new real[][] {{0, pi/2 - eps}, {pi/2 + eps, pi}}) {
    branch(tan2, iv[0], iv[1], tanPen);
    branch(sec, iv[0], iv[1], secPen);
}

axes(w);
for (int y = -4; y <= 4; ++y) if (y != 0) tickY(y, "$" + string(y) + "$");
put("$\theta$", (w.x1, 0), E);
put("$y$", (0, w.y1), N);

closedDot((0, 1)); closedDot((pi, -1));

put("\parbox{3.3cm}{\raggedright $x \ge 1$, $\tan\theta \ge 0$,\\ $\sqrt{x^2-1} = \tan\theta$}",
    (0, 4), SE);
put("\parbox{3.6cm}{\raggedleft $x \le -1$, $\tan\theta \le 0$,\\ $\sqrt{x^2-1} = -\tan\theta$}",
    (pi, -4), NW);

put("thick: $\sec\theta$", (pi + 0.15, 3.9), W);
put("\color{gray} thin grey: $\tan\theta$", (pi + 0.15, 3.3), W);
