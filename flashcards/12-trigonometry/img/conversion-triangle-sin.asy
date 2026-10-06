// The conversion triangle for a given sin(theta): hypotenuse 1 and opposite leg sin(theta),
// so the adjacent leg is sqrt(1 - sin^2(theta)) by Pythagoras.
// Every other function of theta is a ratio of two of its sides (magnitudes
// only: the triangle shows an acute theta).
import _trig;

conversionTriangle("\sqrt{1-\sin^2\theta}", "\sin\theta", "1");
