//#define TEXTURE_GRADS

//#define USE_NOISE

#define COMPUTE_SKY_FOR_REFLECTION

// foam
#define NO_FOAM 0
#define USE_JACOBIAN 1
#define USE_VERTICAL_ACCELERATION 2
#define FOAM USE_JACOBIAN

//#define TESTING_COLOR_DEPTHS
//#define TESTING_COLORS	


#define M_PI 3.1415926535897932384626433832795
#define G 9.81

#define RANDOM_UNIFORM 0
// normal dist can be computed with Box-Muller transform
#define RANDOM_NORMAL 1
// if X is from a normal distribution, then exp(X) follows a log distribution
#define RANDOM_LOG 2
// if X is uniform on [0,1] then −log(X) follows an exponential distribution
#define RANDOM_EXP 3


#define DISPERSION_DEEP 0
#define DISPERSION_SHALLOW 1
#define DISPERSION_ CAPILLARY 2 


#define DIRECTIONAL_COS_POWER 0
#define DIRECTIONAL_MITSUYASU 1
#define DIRECTIONAL_HASSELMANN 2
#define DIRECTIONAL_DONNELAN_BANNER 3
#define DIRECTIONAL_HORVATH_MITSUYASU 4
#define DIRECTIONAL_HORVATH_HASSELMANN 5
#define DIRECTIONAL_HORVATH_DONNELAN_BANNER 6

#define SPECTRUM_PHILLIPS 0
#define SPECTRUM_PIERSON_MOSKOWITZ 1
#define SPECTRUM_JONSWAP 2
#define SPECTRUM_DONNELAN_JONSWAP 3
#define SPECTRUM_TMA 4
#define SPECTRUM_UNIFIED 5
#define SPECTRUM_PIERSON_MOSKOWITZ_HS 6
#define SPECTRUM_BRETSCHNEIDER 7
#define SPECTRUM_OCHI 8
#define SPECTRUM_OCHI_HS 9
