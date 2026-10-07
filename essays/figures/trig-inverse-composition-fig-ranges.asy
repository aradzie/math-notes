// Principal ranges of the six inverse trig functions on the unit circle.
import _essayfigs;

setup(9);
setScale(2.3);

void circlePanel(pair c, string title, real a0, real a1, string[] ends,
                 pair[] endPts, align[] endAl, string[] ticks, string q1,
                 string q2, pair q2pos, string note) {
    T = shift(c);
    // thin gray full circle, thick blue range arc on top
    draw(T * circle((0,0), 1), guidePen);
    draw(T * arc((0,0), 1, degrees(a0), degrees(a1)), thickPen);
    // axes through the centre
    draw(T * ((-1.3,0)--(1.3,0)), axisPen, Arrow(TeXHead, size=2.2));
    draw(T * ((0,-1.3)--(0,1.3)), axisPen, Arrow(TeXHead, size=2.2));
    put("$x$", (1.3,0), E); put("$y$", (0,1.3), N);
    for (int i = 0; i < endPts.length; ++i) {
        closedDot(endPts[i]);
        put(ends[i], endPts[i], endAl[i]);
    }
    put("I", (0.5,0.5), black);
    put(q2, q2pos, black);
    put(title, (0,1.5), N);
    put("\parbox{6cm}{\centering\footnotesize " + note + "}", (0,-1.55), S);
}

// Left: closed right half; ticks 1,-1 on both axes.
circlePanel((-1.95,0), "$\arcsin$, $\arctan$, $\arccsc$", -pi/2, pi/2,
    new string[] {"$\pi/2$", "$-\pi/2$"}, new pair[] {(0,1), (0,-1)},
    new align[] {NE, SE}, new string[] {}, "I", "IV", (0.5,-0.5),
    "$\arcsin$: closed arc. $\arctan$: open arc, endpoints excluded. $\arccsc$: closed arc minus the point at angle $0$.");
T = shift((-1.95,0));
tickX(1); tickX(-1); put("$1$", (1,0), SW); put("$-1$", (-1,0), SE);

// Right: closed upper half.
circlePanel((1.95,0), "$\arccos$, $\arccot$, $\arcsec$", 0, pi,
    new string[] {"$0$", "$\pi$"}, new pair[] {(1,0), (-1,0)},
    new align[] {NE, NW}, new string[] {}, "I", "II", (-0.5,0.5),
    "$\arccos$: closed arc. $\arccot$: open arc. $\arcsec$: closed arc minus the point at angle $\pi/2$.");
T = shift((1.95,0));
tickY(1); tickY(-1); put("$1$", (0,1), SE); put("$-1$", (0,-1), NE);
