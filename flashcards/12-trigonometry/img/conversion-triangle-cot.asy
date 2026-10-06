// The conversion triangle for a given cot(theta): opposite leg 1 and adjacent leg cot(theta),
// so the hypotenuse is sqrt(1 + cot^2(theta)) by Pythagoras.
// Every other function of theta is a ratio of two of its sides (magnitudes
// only: the triangle shows an acute theta).
import _trig;

conversionTriangle("\cot\theta", "1", "\sqrt{1+\cot^2\theta}");
