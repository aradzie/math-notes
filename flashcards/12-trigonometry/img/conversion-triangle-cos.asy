// The conversion triangle for a given cos(theta): hypotenuse 1 and adjacent leg cos(theta),
// so the opposite leg is sqrt(1 - cos^2(theta)) by Pythagoras.
// Every other function of theta is a ratio of two of its sides (magnitudes
// only: the triangle shows an acute theta).
import _trig;

conversionTriangle("\cos\theta", "\sqrt{1-\cos^2\theta}", "1");
