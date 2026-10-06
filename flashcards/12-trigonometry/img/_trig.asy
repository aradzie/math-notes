// Shared helpers for the figures of this directory, in their own look --
// gray axes and grid, 8pt labels, black curves, a fixed 7cm window clipped
// at its edges -- separate from the look of the root _common.asy figures.
// Two kinds of figure use it.
//
// Function graphs (graph-*.asy):
//
//   import _trig;
//   windowSetup(-2pi-0.35, 2pi+0.35, -1.6, 1.6, ystretch=2.5);
//   piGrid(2, 1);                      // 1. grid: x every pi/2, y every 1
//   asymptoteV(pi/2);                  // 2. asymptotes
//   piTicksX(2, sin); numTicksY(1);    // 3. ticks, before the curve: their
//                                      //    labels clear the grid under them
//   drawFunction(sin, -2pi, 2pi);      // 4. the curve
//   trigAxes("\theta");                // 5. axes
//   originLabel(SW);
//
// An inverse graph adds mirrorLine() before the curves, draws the base
// branch with cp=otherPen, its ends with baseEnd, and names both curves last
// with inverseLegend. Its quiz copy (graph-*-quiz.asy, for a card asking
// which function the graph shows) repeats only the inverse curve's commands:
// no mirror line, base branch or legend to give the answer away.
//
// Reference-angle pictures (invtrig-*.asy, range-*.asy) for theta =
// arcfoo(x): the unit circle (gray) with the range of arcfoo drawn thick, its
// endpoints as filled (in the range) or open (not in the range) dots, and for
// each sample value of x the point P on the terminal side of theta with its
// reference triangle O-(P.x,0)-P (blue), the legs labeled with their signed
// lengths (the coordinates of P) and the hypotenuse with the distance OP > 0.
//
//   import _trig;
//   windowSetup(-1.35, 1.35, -1.35, 1.35);
//   unitCircle();                          // 1. the unit circle
//   rangeArc(0, pi);                       // 2. the range of the inverse
//   refTriangle((0.6,0.8), "x", "\sqrt{1-x^2}", "1");   // 3. triangles
//   angleMark((0.6,0.8), 0.22);            //    and the angle theta
//   trigAxes();                            // 4. axes
//   arcEnd(0, true); arcEnd(pi, true);     // 5. range endpoints
//   angleLabel(pi, "\pi", NW);             // 6. labels
//   ptLabel((0.6,0.8), "x>0", NE);
//
// Conversion triangles (conversion-triangle-*.asy) for expressing every trig
// function in terms of one given function: a free-standing right triangle
// (no axes, no circle) with acute angle theta at the origin, the given
// function on one side, 1 on another, and the third side from Pythagoras.
// Each target function is then a ratio of two sides. All of them draw the
// same triangle in the same window (conversionTriangle), so the figures
// overlay exactly and differ only in their side labels.
//
//   import _trig;
//   conversionTriangle("\sqrt{1-\sin^2\theta}", "\sin\theta", "1");
//
// Colors: black curve, gray axes/grid/asymptotes, blue (accentColor)
// triangles and angle marks.

import _common;

pen gridpen = gray(0.85) + linewidth(0.4pt);
pen curvePen = black + linewidth(1.1pt);
// A secondary curve (the given curve whose inverse is drawn in black).
pen otherColor = gray(0.55);
pen otherPen = otherColor + linewidth(1.1pt);
pen axisPen = gray(0.35) + linewidth(0.5pt);
pen asymptotePen = gray + dashed + linewidth(0.5pt);
pen mirrorPen = gray(0.55) + linetype(new real[] {1, 3}) + linewidth(0.6pt);
pen labelPen = fontsize(8pt);
pen tickPen = labelPen + gray(0.2);
pen accentColor = rgb(0.10, 0.25, 0.80);
pen circlePen = gray(0.6) + linewidth(0.6pt);
pen rangePen = black + linewidth(1.8pt);
pen trianglePen = accentColor + linewidth(0.8pt);

// --- the window --------------------------------------------------------------

// The window [wx0,wx1] x [wy0,wy1], set by windowSetup.
real wx0, wx1, wy0, wy1;
// Length of one x unit of the window, in bp, and the factor by which one y
// unit is longer (1: equal scale; set by windowSetup).
real wunit;
real wys = 1;

// Call first. The longer window side is drawn `side` long and both axes
// share one scale, so circles stay round and every figure has about the
// same size. ystretch (default 1, equal scale) draws one y unit ystretch
// times as long as an x unit, for graphs whose x and y ranges differ a lot.
void windowSetup(real x0, real x1, real y0, real y1, real side=7cm,
                 real ystretch=1) {
    mathdefaults();
    defaultpen(black + linewidth(0.5pt));
    wx0 = x0; wx1 = x1; wy0 = y0; wy1 = y1;
    wys = ystretch;
    real span = max(x1 - x0, (y1 - y0) * wys);
    wunit = side / span;
    unitsize(wunit, wunit * wys);
    // An invisible frame, the window plus an equal margin on every side:
    // the axis labels at the arrow tips would otherwise stretch the image
    // on the right and top only, leaving the picture off-center.
    real m = 0.07 * span;
    draw(box((x0 - m, y0 - m / wys), (x1 + m, y1 + m / wys)), invisible);
}

// Half-length of a tick mark along x: the same physical size in every
// figure (along y, divide by wys).
real tickSize() { return 0.012 * max(wx1 - wx0, (wy1 - wy0) * wys); }

// {lo, lo+step, lo+2*step, ..., <= hi}. A value landing extremely close to
// 0 in floating point (e.g. -1 + 5*0.2) is snapped to exactly 0, so the
// `x == 0` origin checks below catch it.
real[] seq(real lo, real hi, real step) {
    real[] r;
    for (real x = lo; x <= hi + sqrt(realEpsilon); x += step) {
        r.push(abs(x) < 1e-9 ? 0 : x);
    }
    return r;
}

// Vertical grid lines at each x in xs, spanning y in [ylo, yhi], and
// horizontal ones at each y in ys, spanning x in [xlo, xhi]. Layer 1.
void vgrid(real[] xs, real ylo, real yhi) {
    for (real x : xs) draw((x,ylo)--(x,yhi), gridpen);
}
void hgrid(real[] ys, real xlo, real xhi) {
    for (real y : ys) draw((xlo,y)--(xhi,y), gridpen);
}

// Grid lines at the multiples of pi/xd (vertical) and every ystep
// (horizontal); pass yd > 0 for horizontal lines at multiples of pi/yd
// instead. Layer 1.
void piGrid(int xd, real ystep=1, int yd=0) {
    real u = pi / xd;
    vgrid(seq(ceil(wx0 / u) * u, wx1, u), wy0, wy1);
    if (yd > 0) {
        real v = pi / yd;
        hgrid(seq(ceil(wy0 / v) * v, wy1, v), wx0, wx1);
    } else {
        hgrid(seq(ceil(wy0 / ystep) * ystep, wy1, ystep), wx0, wx1);
    }
}

// --- clipping to the window ------------------------------------------------

// Clip the polyline p to the window (Liang-Barsky per segment). Returns the
// pieces inside the window.
pair[][] clipRun(pair[] p) {
    pair[][] out;
    pair[] cur;
    for (int i = 0; i < p.length - 1; ++i) {
        pair a = p[i], b = p[i+1];
        real dx = b.x - a.x, dy = b.y - a.y;
        real[] pp = {-dx, dx, -dy, dy};
        real[] qq = {a.x - wx0, wx1 - a.x, a.y - wy0, wy1 - a.y};
        real t0 = 0, t1 = 1;
        bool ok = true;
        for (int k = 0; k < 4; ++k) {
            if (pp[k] == 0) {
                if (qq[k] < 0) ok = false;
            } else {
                real t = qq[k] / pp[k];
                if (pp[k] < 0) {
                    if (t > t1) ok = false; else if (t > t0) t0 = t;
                } else {
                    if (t < t0) ok = false; else if (t < t1) t1 = t;
                }
            }
        }
        if (!ok) {
            if (cur.length > 0) { out.push(cur); cur = new pair[]; }
            continue;
        }
        pair c = a + t0 * (b - a), d = a + t1 * (b - a);
        if (cur.length == 0) cur.push(c);
        else if (length(cur[cur.length-1] - c) > 1e-9) {
            out.push(cur);
            cur = new pair[];
            cur.push(c);
        }
        cur.push(d);
    }
    if (cur.length > 0) out.push(cur);
    return out;
}

bool onEdge(pair z) {
    real e = 1e-6;
    return abs(z.x - wx0) < e || abs(z.x - wx1) < e
        || abs(z.y - wy0) < e || abs(z.y - wy1) < e;
}

path polyline(pair[] p) {
    // a guide, joined lazily: adding a point to a path copies the whole path
    guide g = p[0];
    for (int i = 1; i < p.length; ++i) g = g--p[i];
    return g;
}

// Draw one run of curve points, clipped to the window. A piece that leaves
// the window gets an arrowhead at the cut end: the curve goes on.
void drawRun(pair[] pts, pen cp=curvePen) {
    pair[][] pieces = clipRun(pts);
    for (pair[] q : pieces) {
        path g = polyline(q);
        bool closed = pieces.length == 1 && length(q[0] - q[q.length-1]) < 1e-9;
        bool b = onEdge(q[0]), e = onEdge(q[q.length-1]);
        if (closed) draw(g--cycle, cp);
        else if (b && e) draw(g, cp, Arrows(TeXHead));
        else if (b) draw(g, cp, BeginArrow(TeXHead));
        else if (e) draw(g, cp, Arrow(TeXHead));
        else draw(g, cp);
    }
}

// --- curves and lines ----------------------------------------------------------

// The graph of y=f(x) for x in [x0,x1], clipped to the window; a piece that
// reaches the window edge gets a "continues" arrowhead (see drawRun). The
// curve is split at a pole (non-finite value, or a jump of more than three
// window heights), so no line is drawn across a vertical asymptote. Pass a
// range inside the domain (sqrt of a negative number stops the build);
// for a vertical asymptote at a sampled x start slightly off it. cp is the pen
// (otherPen for a secondary curve).
void drawFunction(real f(real), real x0, real x1, int n=3000,
                  pen cp=curvePen) {
    real big = 3 * (wy1 - wy0);
    pair[] run;
    real prev = 0;
    for (int i = 0; i <= n; ++i) {
        // inner samples are nudged off the grid, so none lands exactly on a
        // pole like x=-10 for 1/(x+10) (a division by zero stops the build)
        real x = x0 + (x1 - x0) * (i == 0 || i == n ? i : i + 0.0007) / n;
        real y = f(x);
        if (!(abs(y) < 1e9)) {
            if (run.length > 1) drawRun(run, cp);
            run = new pair[];
            continue;
        }
        if (run.length > 0 && abs(y - prev) > big) {
            if (run.length > 1) drawRun(run, cp);
            run = new pair[];
        }
        run.push((x, y));
        prev = y;
    }
    if (run.length > 1) drawRun(run, cp);
}

// A dashed horizontal/vertical asymptote across the whole window. Layer 2.
void asymptoteH(real y) { draw((wx0, y)--(wx1, y), asymptotePen); }
void asymptoteV(real x) { draw((x, wy0)--(x, wy1), asymptotePen); }

// The mirror line y = x across the window, dotted gray. Layer 2.
void mirrorLine() {
    for (pair[] q : clipRun(new pair[] {(-1000, -1000), (1000, 1000)}))
        draw(polyline(q), mirrorPen);
}

// --- axes and ticks ----------------------------------------------------------

// The plain arrowed axes across the window, labeled at the tips (the
// strings go in $...$).
void trigAxes(string xl="x", string yl="y") {
    draw((wx0, 0)--(wx1, 0), axisPen, Arrow(TeXHead));
    draw((0, wy0)--(0, wy1), axisPen, Arrow(TeXHead));
    label("$" + xl + "$", (wx1, 0), E, tickPen);
    label("$" + yl + "$", (0, wy1), N, tickPen);
}

// The shared "$0$" label at the origin, where an x-tick and y-tick would
// otherwise both try to place one.
void originLabel(pair align=SW, pen labelpen=tickPen) {
    label("$0$", (0,0), align, labelpen);
}

int gcdInt(int a, int b) { return b == 0 ? a : gcdInt(b, a % b); }

// "k\pi/d" in lowest terms, with its sign: 0, \tfrac{\pi}{2}, -\pi,
// -\tfrac{3\pi}{2}, 2\pi, ...
string piLabel(int k, int d) {
    if (k == 0) return "0";
    int n = abs(k), g = gcdInt(n, d);
    n = quotient(n, g);
    int m = quotient(d, g);
    string num = (n == 1 ? "" : string(n)) + "\pi";
    return (k < 0 ? "-" : "") + (m == 1 ? num : "\tfrac{" + num + "}{" + string(m) + "}");
}

// Tick labels clear a thin margin around themselves, so the grid and the
// dashed asymptotes running through a tick position don't cross the text.
void tickLabelX(real x, string lbl, pair d=S) {
    label("$" + lbl + "$", (x, 0), d, tickPen, UnFill(0.5pt));
}
void tickLabelY(real y, string lbl, pair d=W) {
    label("$" + lbl + "$", (0, y), d, tickPen, UnFill(0.5pt));
}

// Ticks strictly inside the window, origin skipped (originLabel puts the 0
// there): at the multiples of pi/d labeled with piLabel, or every step
// labeled with the number.
//
// Pass the figure's curve as f (y = f(x)) and a label sits clear of it where
// the curve crosses the axis right at that tick, in a quadrant the curve
// leaves free: an x-label above the axis (NW of a rising crossing, NE of a
// falling one -- not beside it, where it would run into the next label), a
// y-label NW of a rising crossing and SW of a falling one.
// numTicksX/numTicksY/piTicksY put the labels of the negative ticks on the side
// negDir instead (N/E when a curve hugs the negative half of the axis).

// The side of the curve's crossing of an axis at z that it leaves free, or
// `usual` when f is null or doesn't pass through z.
pair freeSide(real f(real), pair z, pair usual, pair rising, pair falling) {
    if (f == null) return usual;
    real h = 1e-4, y = f(z.x);
    if (!(abs(y - z.y) < 0.02 * (wy1 - wy0))) return usual;
    return f(z.x + h) > f(z.x - h) ? rising : falling;
}

void piTicksX(int d, real f(real)=null) {
    real u = pi / d, len = tickSize() / wys;
    for (int k = ceil(wx0 / u + 1e-9); k * u < wx1 - 1e-6; ++k) {
        if (k == 0) continue;
        draw((k * u, -len)--(k * u, len), axisPen);
        tickLabelX(k * u, piLabel(k, d), freeSide(f, (k * u, 0), S, NW, NE));
    }
}
void piTicksY(int d, real f(real)=null, pair negDir=W) {
    real u = pi / d, len = tickSize();
    for (int k = ceil(wy0 / u + 1e-9); k * u < wy1 - 1e-6; ++k) {
        if (k == 0) continue;
        draw((-len, k * u)--(len, k * u), axisPen);
        tickLabelY(k * u, piLabel(k, d), freeSide(f, (0, k * u), k < 0 ? negDir : W, NW, SW));
    }
}
void numTicksX(real step, pair negDir=S) {
    real len = tickSize() / wys;
    for (real x : seq((floor(wx0 / step + 1e-9) + 1) * step, wx1 - 1e-6, step)) {
        if (x == 0) continue;
        draw((x, -len)--(x, len), axisPen);
        tickLabelX(x, string(x), x < 0 ? negDir : S);
    }
}
void numTicksY(real step, pair negDir=W) {
    real len = tickSize();
    for (real y : seq((floor(wy0 / step + 1e-9) + 1) * step, wy1 - 1e-6, step)) {
        if (y == 0) continue;
        draw((-len, y)--(len, y), axisPen);
        tickLabelY(y, string(y), y < 0 ? negDir : W);
    }
}

// --- points and labels -------------------------------------------------------

// A filled dot, e.g. a point of the figure or a curve endpoint that belongs
// to the curve.
void keyDot(pair z, pen p=black) { dot(z, p + linewidth(4.2pt)); }
void closedEnd(pair z) { keyDot(z); }
// A curve endpoint that doesn't belong to the curve: an open circle that
// clears whatever is under it, so the curve stops at its edge.
void openEnd(pair z) {
    path c = circle(z, 2.4 / wunit);
    if (wys != 1) c = shift(z) * yscale(1 / wys) * shift(-z) * c;
    unfill(c);
    draw(c, black + linewidth(0.8pt));
}
// An end of the faint base branch of an inverse graph that belongs to it: a
// smaller gray dot.
void baseEnd(pair z) { dot(z, otherColor + linewidth(3.2pt)); }

// The legend of an inverse graph: "y = <inv>" in black over "y = <base>" in
// gray, the colors of the two curves, left-aligned at z (the top line) in a
// free part of the window. Clears the grid under it.
void inverseLegend(pair z, string inv, string base) {
    real dy = 12pt / (wunit * wys);
    label("$y=" + inv + "$", z, E, labelPen + black, UnFill(1pt));
    label("$y=" + base + "$", z - (0, dy), E, labelPen + otherColor, UnFill(1pt));
}

// A math-mode label next to z, on the side `dir` (N, NE, E, ...).
void ptLabel(pair z, string txt, pair dir, pen p=black) {
    label("$" + txt + "$", z, dir, labelPen + p);
}

// --- the unit circle -----------------------------------------------------------

// The whole unit circle, thin and gray.
void unitCircle() { draw(unitcircle, circlePen); }

// The arc of the unit circle for theta in [t0, t1] (radians), thick: the
// values the inverse function takes. Excluded points inside the arc get an
// arcEnd(t, false) later.
void rangeArc(real t0, real t1) {
    draw(arc((0, 0), 1, degrees(t0), degrees(t1)), rangePen);
}

// The point of the unit circle at angle t: a filled dot when t is in the
// range, an open circle when it is not (a limit point or a gap in the arc).
void arcEnd(real t, bool closed) {
    pair z = dir(degrees(t));
    if (closed) closedEnd(z); else openEnd(z);
}

// The value of theta at the point of the unit circle at angle t, written
// next to it on the side `d`.
void angleLabel(real t, string txt, pair d) {
    ptLabel(dir(degrees(t)), txt, d, gray(0.2));
}

// The reference triangle of the point P: O to (P.x, 0) along the x-axis, up
// or down to P, and back to O along the terminal side of theta, with a
// right-angle mark. The labels h (horizontal leg, the x-coordinate of P), v
// (vertical leg, the y-coordinate) and r (hypotenuse, OP) go outside the
// triangle unless a direction is given; "" leaves a label out. rpos moves the
// hypotenuse label along OP (0: at O, 1: at P) and vpos the vertical one up
// the leg (0: at the axis, 1: at P), off a crossing with the circle.
// dotP=false leaves out the dot at P (a conversion triangle has no point P
// on a circle to mark).
void refTriangle(pair P, string h, string v, string r,
                 pair hdir=(0, 0), pair vdir=(0, 0), pair rdir=(0, 0),
                 real rpos=0.5, real vpos=0.5, bool dotP=true) {
    pair F = (P.x, 0);
    draw((0, 0)--F--P--cycle, trianglePen);
    // right-angle mark at the foot, inside the triangle
    real s = 0.07;
    pair a = (-sgn(P.x) * s, 0), b = (0, sgn(P.y) * s);
    draw((F + a)--(F + a + b)--(F + b), trianglePen + linewidth(0.5pt));
    if (hdir == (0, 0)) hdir = (0, -sgn(P.y));
    if (vdir == (0, 0)) vdir = (sgn(P.x), 0);
    if (rdir == (0, 0)) rdir = unit(P / 2 - F);
    if (h != "") ptLabel(F / 2, h, hdir, accentColor);
    if (v != "") ptLabel(F + vpos * (P - F), v, vdir, accentColor);
    if (r != "") ptLabel(rpos * P, r, rdir, accentColor);
    if (dotP) keyDot(P, accentColor);
}

// The angle theta at the origin, from the positive x-axis to the terminal
// side through P (counterclockwise for P above the axis, clockwise below),
// as an arc of radius rad with the label at its middle. With several marks,
// the larger |theta| gets the smaller radius: a small angle's arc is then
// long enough to leave room for its label.
void angleMark(pair P, real rad, string txt="\theta") {
    real t = degrees(atan2(P.y, P.x));
    draw(arc((0, 0), rad, 0, t), accentColor + linewidth(0.6pt), EndArrow(TeXHead, size=1.5));
    ptLabel(rad * dir(t / 2), txt, dir(t / 2), accentColor);
}

// --- conversion triangles ----------------------------------------------------

// A whole conversion-triangle figure: one fixed triangle (theta = 35
// degrees, adjacent leg of length 1) in one fixed window, labeled h
// (adjacent leg), v (opposite leg) and r (hypotenuse). The window's
// invisible frame holds every figure's labels and is centered on the
// triangle's bounding box (0,0)-(1,tan 35), so all the figures have the
// same canvas with the triangle at the same spot.
void conversionTriangle(string h, string v, string r) {
    pair P = (1, Tan(35));
    windowSetup(-0.55, 1.55, -0.12, 0.82, side=6.2cm);
    refTriangle(P, h, v, r, dotP=false);
    angleMark(P, 0.25);
}

