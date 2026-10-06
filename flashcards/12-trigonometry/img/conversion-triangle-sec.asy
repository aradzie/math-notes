// The conversion triangle for a given sec(theta): adjacent leg 1 and hypotenuse sec(theta),
// so the opposite leg is sqrt(sec^2(theta) - 1) by Pythagoras.
// Every other function of theta is a ratio of two of its sides (magnitudes
// only: the triangle shows an acute theta).
import _trig;

conversionTriangle("1", "\sqrt{\sec^2\theta-1}", "\sec\theta");
