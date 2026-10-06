// The conversion triangle for a given csc(theta): opposite leg 1 and hypotenuse csc(theta),
// so the adjacent leg is sqrt(csc^2(theta) - 1) by Pythagoras.
// Every other function of theta is a ratio of two of its sides (magnitudes
// only: the triangle shows an acute theta).
import _trig;

conversionTriangle("\sqrt{\csc^2\theta-1}", "1", "\csc\theta");
