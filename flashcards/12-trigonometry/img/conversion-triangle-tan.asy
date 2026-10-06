// The conversion triangle for a given tan(theta): adjacent leg 1 and opposite leg tan(theta),
// so the hypotenuse is sqrt(1 + tan^2(theta)) by Pythagoras.
// Every other function of theta is a ratio of two of its sides (magnitudes
// only: the triangle shows an acute theta).
import _trig;

conversionTriangle("1", "\tan\theta", "\sqrt{1+\tan^2\theta}");
