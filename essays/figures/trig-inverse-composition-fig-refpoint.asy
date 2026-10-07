// Reference triangle vs signed reference point for theta = arcsec x,
// x = 2 (quadrant I) and x = -2 (quadrant II).
import _essayfigs;

setup(8);
setScale(1.35);

Window w = Window(-2.5, 2.5, -0.5, 2.5);
real r = 2;

// s = +1: x = 2, theta = pi/3.  s = -1: x = -2, theta = 2pi/3.
void panel(real cx, int s, string title, string below) {
    real th = s > 0 ? pi/3 : 2pi/3;
    pair P = (s, sqrt(3));
    T = shift((cx, 0));

    draw(T * arc((0,0), r, 0, 180), faintPen);
    axes(w);

    if (s < 0) {   // the naive first-quadrant triangle, faint
        pen g = gray(0.7) + linewidth(0.6pt);
        draw(T * ((0,0)--(1,0)--(1,sqrt(3))--cycle), g);
        put("\parbox{2.4cm}{\raggedright\scriptsize\color{gray} naive triangle: would give $+\sqrt3$}",
            (1.12, 2.1), E);
    }

    seg((0,0), (s,0), black + linewidth(1.1pt));         // horizontal leg X
    seg((0,0), P, black + linewidth(1.1pt));             // hypotenuse r
    seg(P, (s,0), dashPen);                              // vertical leg Y
    drawArc((0,0), 0.45, 0, th);
    put("$\theta$", 0.68 * (cos(th/2), sin(th/2)));

    string xs = s > 0 ? "$X = 1$" : "$X = {\color{blue}-}1$";
    put(xs, (s/2, 0), S, s > 0 ? black : accent);
    put("$Y = \sqrt{3}$", (s, sqrt(3)/2), s > 0 ? E : W);
    label(rotate(s > 0 ? 60 : -60) * "$r = 2$", T * (P/2 + 0.17 * (-s * 0.87, 0.5)));
    put("$(X,Y) = (" + (s > 0 ? "" : "-") + "1, \sqrt{3})$", P, s > 0 ? NE : NW, UnFill(1));

    closedDot(P);
    put(title, (0, w.y1), N);
    put(below, (0, w.y0 - 0.12), S);
}

panel(-3.1, 1, "$x = 2$: $\theta = \pi/3$", "$\tan\theta = Y/X = \sqrt{3} > 0$");
panel(3.1, -1, "$x = -2$: $\theta = 2\pi/3$", "$\tan\theta = Y/X = -\sqrt{3} < 0$");
