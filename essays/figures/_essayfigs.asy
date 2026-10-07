// Shared helpers for the figures of trig-inverse-composition.tex: plain black
// curves, gray guides, one blue accent, Computer Modern labels (as set by
// essay.cls). Standalone on purpose: texlive.sh mounts only the current
// directory, so a figure built from essays/ cannot import flashcards/_common.
//
// Figure files are named <essay>-fig-<name>; the PDF lands next to its source.
// Build (from essays/):
//
//   ../texlive.sh asy -dir figures -f pdf -o figures/trig-inverse-composition-fig-ranges figures/trig-inverse-composition-fig-ranges.asy
//
// Figures are about 15.9cm wide (the essay's text width), so \includegraphics
// at \textwidth keeps labels at their nominal size.
//
// Skeleton:
//
//   import _essayfigs;
//   setup(8);                       // 1. label size (pt)
//   setScale(0.8);                  // 2. cm per user unit (or setScale(cx, cy))
//   T = shift(cell - windowCenter); // 3. optional: place a panel (default identity)
//   Window w = Window(x0, x1, y0, y1);
//   axes(w);                        // 4. axes through the origin
//   drawParam(w, new pair(real t) { return (t, sin(t)); }, a, b, thinPen);
//
// Every helper takes positions in the panel's own coordinates and applies T.

texpreamble("\usepackage{amsmath,xcolor}");
texpreamble("\DeclareMathOperator{\arcsec}{arcsec}");
texpreamble("\DeclareMathOperator{\arccsc}{arccsc}");
texpreamble("\DeclareMathOperator{\arccot}{arccot}");

pen accent = blue;
pen thinPen = black + linewidth(0.6pt);
pen thickPen = accent + linewidth(1.5pt);
pen axisPen = black + linewidth(0.5pt);
pen guidePen = gray(0.55) + linewidth(0.5pt);
pen dashPen = guidePen + linetype(new real[] {3, 3});
pen gridPen = gray(0.9) + linewidth(0.4pt);
pen faintPen = gray(0.8) + linewidth(1.0pt);

transform T = identity();
real UX = cm, UY = cm;   // bp per user unit

void setup(real fs=8) {
    defaultpen(fontsize(fs));
}

void setScale(real cmx, real cmy=cmx) {
    unitsize(cmx * cm, cmy * cm);
    UX = cmx * cm;
    UY = cmy * cm;
}

// bp expressed in user units along each axis.
real px(real bp) { return bp / UX; }
real py(real bp) { return bp / UY; }

struct Window {
    real x0, x1, y0, y1;
    void operator init(real x0, real x1, real y0, real y1) {
        this.x0 = x0; this.x1 = x1; this.y0 = y0; this.y1 = y1;
    }
    pair center() { return ((x0 + x1) / 2, (y0 + y1) / 2); }
    path box() { return (x0, y0)--(x1, y0)--(x1, y1)--(x0, y1)--cycle; }
}

// ---- primitives -------------------------------------------------------

void seg(pair a, pair b, pen p=thinPen) { draw(T * a--T * b, p); }
void drawArc(pair c, real r, real a0, real a1, pen p=thinPen) {
    draw(T * arc(c, r, degrees(a0), degrees(a1)), p);
}
void put(string s, pair p, align a=NoAlign, pen q=currentpen, filltype f=NoFill) {
    label(s, T * p, a, q, f);
}
// Dots stay round under unequal axis scales (r in bp).
path dotPath(pair p, real r) { return shift(T * p) * scale(px(r), py(r)) * unitcircle; }
void closedDot(pair p, real r=2.4) { filldraw(dotPath(p, r), accent, accent); }
void blackDot(pair p, real r=2.4) { filldraw(dotPath(p, r), black, black); }
void openDot(pair p, real r=2.4) { filldraw(dotPath(p, r), white, black + linewidth(0.6pt)); }

// ---- axes and ticks ---------------------------------------------------

void axes(Window w, real ox=0, real oy=0) {
    draw(T * ((w.x0, oy)--(w.x1, oy)), axisPen, Arrow(TeXHead, size=2.2));
    draw(T * ((ox, w.y0)--(ox, w.y1)), axisPen, Arrow(TeXHead, size=2.2));
}

// Tick on the x-axis (at height y) with an optional label below (align S) or above (N).
void tickX(real x, string s="", align a=S, real y=0) {
    pair q = T * (x, y);
    draw((q.x, q.y - py(2))--(q.x, q.y + py(2)), axisPen);
    if (s != "") label(s, q + (0, a.dir.y < 0 ? -py(3.5) : py(3.5)), a);
}
// Tick on the y-axis (at abscissa x) with an optional label left (W) or right (E).
void tickY(real y, string s="", align a=W, real x=0) {
    pair q = T * (x, y);
    draw((q.x - px(2), q.y)--(q.x + px(2), q.y), axisPen);
    if (s != "") label(s, q + (a.dir.x < 0 ? -px(3.5) : px(3.5), 0), a);
}

string piLabel(int k, int d=2) {   // k*pi/d as a TeX string, d in {1,2}
    if (k == 0) return "0";
    string sgn = k < 0 ? "-" : "";
    int m = abs(k);
    if (d == 1) return "$" + sgn + (m == 1 ? "" : string(m)) + "\pi$";
    if (m % 2 == 0) { int n = m # 2; return "$" + sgn + (n == 1 ? "" : string(n)) + "\pi$"; }
    return "$" + sgn + (m == 1 ? "" : string(m)) + "\pi/2$";
}

// ---- curves -----------------------------------------------------------

// Draw g(t), t in [t0,t1], keeping only the parts inside w; the curve is cut
// exactly at the window boundary (works across poles such as tan).
void drawParam(Window w, pair g(real), real t0, real t1, pen p=thinPen, int n=1200) {
    path bx = w.box();
    real lim = 1e3;
    bool in(pair z) { return z.x >= w.x0 - 1e-9 && z.x <= w.x1 + 1e-9 && z.y >= w.y0 - 1e-9 && z.y <= w.y1 + 1e-9; }
    pair clamp(pair z) { return (min(max(z.x, -lim), lim), min(max(z.y, -lim), lim)); }
    pair boundary(pair a, pair b) {
        pair[] I = intersectionpoints(a--b, bx);
        return I.length > 0 ? I[0] : a;
    }
    path run;
    bool going = false;
    pair prev = clamp(g(t0));
    if (in(prev)) { run = prev; going = true; }
    for (int i = 1; i <= n; ++i) {
        pair z = clamp(g(t0 + (t1 - t0) * i / n));
        if (in(z)) {
            if (!going) { run = boundary(prev, z)--z; going = true; }
            else run = run--z;
        } else if (going) {
            draw(T * (run--boundary(prev, z)), p);
            going = false;
        }
        prev = z;
    }
    if (going) draw(T * run, p);
}

// y = f(x) and its reflection x = f(y), as parametric curves.
pair graphOf(real f(real), real t) { return (t, f(t)); }

// The line y = x across the window, as a dashed gray guide.
void identityLine(Window w) {
    real a = max(w.x0, w.y0), b = min(w.x1, w.y1);
    draw(T * ((a, a)--(b, b)), dashPen);
}
