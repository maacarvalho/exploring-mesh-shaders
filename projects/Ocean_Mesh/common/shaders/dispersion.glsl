// ------------------------------
// Dispersion
// ------------------------------

float getDispersionW(float k, float depth, int dispersionMode) {

	float tension = 0.074; // N/m
	float density = 1000; // Kg/m3
	
	// deep waters
	if (dispersionMode == DISPERSION_DEEP) 
		return sqrt(k * G);
	// shallow waters	
	else if (dispersionMode == DISPERSION_SHALLOW)	
		return sqrt(k * G * tanh(k*depth));
	else  // DISPERSION_ CAPILLARY
		return sqrt((G * k + pow(k,3) * tension/density) * tanh(k*depth));
}


float getDispersionDerivative(float k, float depth, int dispersionMode) {

	float tension = 0.074; // N/m
	float density = 1000; // Kg/m3
	float w = getDispersionW(k, depth, dispersionMode);
	
	// deep waters
	if (dispersionMode == DISPERSION_DEEP) 
		return G * 0.5f / w; 
	// shallow waters	
	else if (dispersionMode == DISPERSION_SHALLOW) {
		float dk = depth * k;
		float th = tanh(dk);
		return 0.5f * sqrt(9.81f / (k*th)) * (th + dk*(1 - th*th));
	}
	else { // DISPERSION_ CAPILLARY
		float dk = depth * k;
		float th = tanh(dk);
		float b = tension/density;
		return 0.5f * ((9.81f + 3 * b*k*k)*th + dk * (k*k*b + 9.81f) * pow(1.0f / cosh(dk), 2)) / w;
	}
}
