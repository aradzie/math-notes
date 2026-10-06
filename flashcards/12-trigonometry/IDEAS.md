# Trigonometry flashcard ideas

Candidate topics for new trig flashcards, to revisit and turn into `.note` files later.

## Already covered

- Pythagorean, sum/difference, double-angle, power-reduction and half-angle identities (`01-identities.note`, cloze notes).
- The six unit-circle segments for a first-quadrant angle (`02-unit-circle-segments.note`).
- Graphs of the six functions (`03-function-graphs.note`) and the six inverses (`04-inverse-function-graphs.note`).
- Single-function conversions (`05-function-conversions.note`).

## Gaps, in rough priority order

### 1. Unit circle and special-angle values

- Definition: \( (\cos\theta,\sin\theta) \) as the point on the unit circle at signed angle \( \theta \). Include why this extends the right-triangle definition, and what \( \tan\theta \) means as slope.
- Values of \( \sin \), \( \cos \) and \( \tan \) at \( 0, \pi/6, \pi/4, \pi/3, \pi/2 \). One note per angle, as a recognition family. Each note asks for all three values and, where relevant, the "undefined" case, e.g. \( \tan(\pi/2) \).
- Derive the \( \pi/4 \) values from an isosceles right triangle, and the \( \pi/6 \) and \( \pi/3 \) values from half of an equilateral triangle.
- Pattern note: \( \sin \) at \( 0, \pi/6, \pi/4, \pi/3, \pi/2 \) equals \( \tfrac{\sqrt{0}}2,\tfrac{\sqrt1}2,\tfrac{\sqrt2}2,\tfrac{\sqrt3}2,\tfrac{\sqrt4}2 \).
- Values at the quadrantal angles \( \pi, 3\pi/2, 2\pi \), and where each function is undefined.
- Figure: unit circle with the special angles marked (new `.asy` illustration).

### 2. Angle measure

- Radians as arc length over radius, and why radians are the natural unit for calculus: \( (\sin x)'=\cos x \) only holds in radians.
- Degree-radian conversion, arc length \( s=r\theta \), sector area \( \tfrac12 r^2\theta \).

### 3. Symmetry, reduction and reference angles

- Parity: \( \sin(-\theta)=-\sin\theta \), \( \cos(-\theta)=\cos\theta \), and the parity of the other four functions.
- Periodicity: \( 2\pi \) for \( \sin,\cos,\sec,\csc \) and \( \pi \) for \( \tan,\cot \).
- Supplementary and complementary angles: \( \sin(\pi-\theta) \), \( \sin(\pi/2-\theta)=\cos\theta \), \( \sin(\theta+\pi) \).
- Quadrant sign rules, and how a reference angle gives values in any quadrant.
- Recognition notes, e.g. "Evaluate \( \sin(5\pi/6) \)" and "Evaluate \( \cos(-2\pi/3) \)".

### 4. Inverse-function identities and values

- Why \( \arcsin(\sin x)=x \) only for \( x\in[-\pi/2,\pi/2] \). Include a counterexample, e.g. \( \arcsin(\sin\pi)=0 \).
- \( \sin(\arccos x)=\sqrt{1-x^2} \) and similar compositions, with the sign justified by the range.
- \( \arcsin x+\arccos x=\pi/2 \), and \( \arctan x+\operatorname{arccot}x \) with care about convention.
- Principal values at special inputs, e.g. \( \arccos(-1/2) \), \( \arctan(1) \).

### 5. Further identities

- Triple-angle formulas, and the product-to-sum and sum-to-product formulas.
- Derive the double-angle formulas from the sum formulas, and the sum formulas from the geometry (derivation note with `Let:` and `To prove:`).
- \( a\sin\theta+b\cos\theta=R\sin(\theta+\varphi) \), the amplitude-phase form.
- Euler's formula, \( \cos\theta=\tfrac{e^{i\theta}+e^{-i\theta}}2 \), and De Moivre's theorem, linking trig to complex numbers.

### 6. Triangle trigonometry

- Law of sines and law of cosines, including that the law of cosines generalizes Pythagoras.
- The ambiguous (SSA) case, as a recognition note.
- Triangle area as \( \tfrac12 ab\sin C \).

### 7. Calculus-flavored facts

- \( \lim\_{x\to0}\tfrac{\sin x}{x}=1 \), via the squeeze theorem on the unit-circle areas, and \( \tfrac{1-\cos x}{x}\to0 \).
- Derivatives of the six functions and of the inverses. These probably belong in the calculus directory, so only cross-reference them.
- \( |\sin x|\le|x| \), and \( \tan x>x \) on \( (0,\pi/2) \).
