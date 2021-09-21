tChanged = function()

	local od = {}
	local dt = {}
	local lat = {}
	local lon = {}
	local mer = {}
	local year = {}
	local month = {}
	local day = {}
	
	getAttr("RENDERER", "CURRENT", "year", 0, year)
	getAttr("RENDERER", "CURRENT", "month", 0, month)
	getAttr("RENDERER", "CURRENT", "day", 0, day)
	getAttr("RENDERER", "CURRENT", "decimalHour", 0, dt)
	getAttr("RENDERER", "CURRENT", "latitude", 0, lat)
	getAttr("RENDERER", "CURRENT", "longitude", 0, lon)
	getAttr("RENDERER", "CURRENT", "meridian", 0, mer)

	local sunAngles = {}
	
	-- Lua adaptation from the code at http://www.psa.es/sdg/sunpos.htm
	
	-- Main variables
	local dElapsedJulianDays = 0;
	local dDecimalHours = 0;
	local dEclipticLongitude = 0;
	local dEclipticObliquity;
	local dRightAscension = 0;
	local dDeclination = 0;

	-- Auxiliary variables
	local dY;
	local dX;
	
	-- Calculate difference in days between the current Julian Day 
	-- and JD 2451545.0, which is noon 1 January 2000 Universal Time
	-- https://quasar.as.utexas.edu/BillInfo/JulianDatesG.html
    local A = year[1]//100
    local B = A//4
    local C = 2-A+B
    local E = math.floor(365.25 * (year[1]+4716))
    local F = math.floor(30.6001 * (month[1]+1))
    local dJulianDate = C + day[1] + E + F - 1524.5 + dt[1]/24 
	-- Calculate difference between current Julian Day and JD 2451545.0 
	local dElapsedJulianDays = dJulianDate - 2451545.0;

	-- Calculate ecliptic coordinates (ecliptic longitude and obliquity of the 
	-- ecliptic in radians but without limiting the angle to be less than 2*Pi 
	-- (i.e., the result may be greater than 2*Pi)
	
	local dMeanLongitude = 0;
	local dMeanAnomaly = 0;
	local dOmega = 0;
	dOmega= 2.1429 - 0.0010394594 * dElapsedJulianDays;
	dMeanLongitude = 4.8950630 + 0.017202791698 * dElapsedJulianDays; -- Radians
	dMeanAnomaly = 6.2400600 + 0.0172019699 * dElapsedJulianDays;
	dEclipticLongitude = dMeanLongitude + 0.03341607 * math.sin( dMeanAnomaly ) 
		+ 0.00034894 * math.sin(2 * dMeanAnomaly) - 0.0001134
		- 0.0000203 * math.sin(dOmega);
	dEclipticObliquity = 0.4090928 - 6.2140e-9 * dElapsedJulianDays
		+ 0.0000396 * math.cos(dOmega);

	-- Calculate celestial coordinates ( right ascension and declination ) in radians 
	-- but without limiting the angle to be less than 2*Pi (i.e., the result may be 
	-- greater than 2*Pi)
		
	local dSin_EclipticLongitude;
	dSin_EclipticLongitude= math.sin( dEclipticLongitude );
	dY = math.cos( dEclipticObliquity ) * dSin_EclipticLongitude;
	dX = math.cos( dEclipticLongitude );
	dRightAscension = math.atan2( dY,dX );
	if( dRightAscension < 0.0 ) then 
		dRightAscension = dRightAscension + (2*math.pi);
	end		
	dDeclination = math.asin( math.sin( dEclipticObliquity ) * dSin_EclipticLongitude );
		
	-- Calculate local coordinates ( azimuth and zenith angle ) in degrees
	local dGreenwichMeanSiderealTime;
	local dLocalMeanSiderealTime;
	local dLatitudeInRadians;
	local dHourAngle;
	local dCos_Latitude;
	local dSin_Latitude;
	local dCos_HourAngle;
	local dParallax;
	dGreenwichMeanSiderealTime = 6.6974243242 + 0.0657098283 * dElapsedJulianDays + dt[1];
	dLocalMeanSiderealTime = (dGreenwichMeanSiderealTime * 15 + lon[1]) * (math.pi/180);
	dHourAngle = dLocalMeanSiderealTime - dRightAscension;
	dLatitudeInRadians = lat[1] * (math.pi/180);
	dCos_Latitude = math.cos( dLatitudeInRadians );
	dSin_Latitude = math.sin( dLatitudeInRadians );
	dCos_HourAngle= math.cos( dHourAngle );
	local dZenithAngle = (math.acos( dCos_Latitude * dCos_HourAngle
		* math.cos(dDeclination) + math.sin( dDeclination ) * dSin_Latitude));
	dY = -math.sin( dHourAngle );
	dX = math.tan( dDeclination ) * dCos_Latitude - dSin_Latitude * dCos_HourAngle;
	local dAzimuth = math.atan2( dY, dX );
	if ( dAzimuth < 0.0 ) then
		dAzimuth = dAzimuth + (2 * math.pi);
	end	
	sunAngles[1] = dAzimuth/(math.pi/180);
	-- Parallax Correction
	dParallax=(6371.01/149597890) * math.sin(dZenithAngle);
	sunAngles[2] = 90 - (dZenithAngle + dParallax)/(math.pi/180);
		
	setAttr("RENDERER", "CURRENT", "sunAngles", 0, sunAngles)
		
	local debug = {0,1,2}
	debug[1] = dDeclination;
	debug[2] = dParallax;
	debug[3] = dt[1]/24
	setAttr("RENDERER", "CURRENT", "debug", 0, debug);
end


tChanged2 = function()

	local od = {}
	local dt = {}
	local lat = {}
	local lon = {}
	local mer = {}
	getAttr("RENDERER", "CURRENT", "ordinalDay", 0, od)
	getAttr("RENDERER", "CURRENT", "decimalHour", 0, dt)
	getAttr("RENDERER", "CURRENT", "latitude", 0, lat)
	getAttr("RENDERER", "CURRENT", "longitude", 0, lon)
	getAttr("RENDERER", "CURRENT", "meridian", 0, mer)
	
	local latR = lat[1] * math.pi/180
	local lonR = lon[1] * math.pi/180
	local merR = mer[1] * math.pi/180
	
	local lstm = mer --math.pi/12 * (merR)
	
	local b = 360.0/365 * (od[1] - 81) * math.pi/180
	local eot = 9.87 * math.sin(2*b) - 7.53*math.cos(b) - 1.5*math.sin(b)
	
	local tc = 4.0 * (lon[1] - mer[1]) + eot
	local lst = dt[1] + tc/60.0
	local hra = math.pi/12 * (lst-12)
	local dec = 23.45 * math.sin(b) * math.pi/180
	
	local sunAngles = {}
		
	-- elevation angle
	local elevation = math.asin(math.sin(dec) * math.sin(latR) 
					+ math.cos(dec) * math.cos(latR) * math.cos(hra))
	-- azimuth relative to north				
	local azimuth = math.acos(
					(math.sin(dec) * math.cos(latR) - math.cos(dec) * math.sin(latR) * math.cos(hra))/
					math.cos(elevation)
				   )	
	if lst > 12 then
		azimuth = 2 * math.pi - azimuth
	end

	-- azimuth = math.pi - azimuth
	sunAngles[1] = 180.0/math.pi * azimuth
	sunAngles[2] = elevation * 180/math.pi
	
	
	setAttr("RENDERER", "CURRENT", "sunAngles", 0, sunAngles)
end


atmosConfigChanged = function()

	local p = {}
	local t = {}
	local ir = {}
	
	getAttr("RENDERER", "CURRENT", "pressure", 0, p)
	getAttr("RENDERER", "CURRENT", "temperature", 0, t)
	getAttr("RENDERER", "CURRENT", "indexOfRefraction", 0, ir)
	
	local n = p[1] / (1.38e-23 *(t[1]+273))
	local k = 2.0 * math.pow(math.pi,2) * math.pow(math.pow(ir[1],2) - 1, 2) / (3 * n)

	local wavelength = {}
	getAttr("RENDERER", "CURRENT", "waveLengths", 0, wavelength)
	
	local betaR = {}
	for i = 1, 3 do
		betaR[i] = k/math.pow(wavelength[i]*10e-10, 4)
	end
	setAttr("RENDERER", "CURRENT", "betaR",  0, betaR)
	
	local debug={}
	debug[1] = n
	debug[2] = k
	debug[3] = 0
	setAttr("RENDERER", "CURRENT", "debug", 0, debug)

end	


computePlank = function (wavelength, t)
	
	h = 6.62607004e-34 
	c = 299792458
	kb = 1.38064852e-23 
	
	top1 = 2 * math.pi * h * c * c
	bot1 = math.pow(wavelength, 5)
	bot2top = h * c
	bot2bot = wavelength * kb * t
	
	e = math.exp(bot2top/bot2bot)
	
	bot2 = e - 1
	
	return top1/(bot1 * bot2)
end
	local XYZ = {
		0.001368,0.000039,0.006450001,		-- 380
		0.002236,0.000064,0.01054999,
		0.004243,0.00012,0.02005001,
		0.00765,0.000217,0.03621,
		0.01431,0.000396,0.06785001,		-- 400
		0.02319,0.00064,0.1102,
		0.04351,0.00121,0.2074,
		0.07763,0.00218,0.3713,
		0.13438,0.004,0.6456,				-- 420
		0.21477,0.0073,1.0390501,
		0.2839,0.0116,1.3856,
		0.3285,0.01684,1.62296,
		0.34828,0.023,1.74706,				-- 440
		0.34806,0.0298,1.7826,
		0.3362,0.038,1.77211,
		0.3187,0.048,1.7441,
		0.2908,0.06,1.6692,					-- 460
		0.2511,0.0739,1.5281,
		0.19536,0.09098,1.28764,
		0.1421,0.1126,1.0419,
		0.09564,0.13902,0.8129501,			-- 480
		0.05795001,0.1693,0.6162,
		0.03201,0.20802,0.46518,
		0.0147,0.2586,0.3533,
		0.0049,0.323,0.272,					-- 500
		0.0024,0.4073,0.2123,
		0.0093,0.503,0.1582,
		0.0291,0.6082,0.1117,
		0.06327,0.71,0.07824999,			-- 520
		0.1096,0.7932,0.05725001,
		0.1655,0.862,0.04216,
		0.2257499,0.9148501,0.02984,
		0.2904,0.954,0.0203,				-- 540
		0.3597,0.9803,0.0134,
		0.4334499,0.9949501,0.008749999,
		0.5120501,1,0.005749999,
		0.5945,0.995,0.0039,				-- 560
		0.6784,0.9786,0.002749999,			
		0.7621,0.952,0.0021,
		0.8425,0.9154,0.0018,
		0.9163,0.87,0.001650001,			-- 580
		0.9786,0.8163,0.0014,
		1.0263,0.757,0.0011,
		1.0567,0.6949,0.001,
		1.0622,0.631,0.0008,				-- 600
		1.0456,0.5668,0.0006,
		1.0026,0.503,0.00034,
		0.9384,0.4412,0.00024,
		0.8544499,0.381,0.00019,			-- 620
		0.7514,0.321,0.0001,
		0.6424,0.265,5E-05,
		0.5419,0.217,0.00003,
		0.4479,0.175,0.00002,				-- 640
		0.3608,0.1382,0.00001,
		0.2835,0.107,0,
		0.2187,0.0816,0,
		0.1649,0.061,0,						-- 660
		0.1212,0.04458,0,
		0.0874,0.032,0,
		0.0636,0.0232,0,
		0.04677,0.017,0,					-- 680
		0.0329,0.01192,0,
		0.0227,0.00821,0,
		0.01584,0.005723,0,
		0.01135916,0.004102,0,				-- 700
		0.008110916,0.002929,0,
		0.005790346,0.002091,0,
		0.004109457,0.001484,0,
		0.002899327,0.001047,0,				-- 720
		0.00204919,0.00074,0,
		0.001439971,0.00052,0,
		0.000999949,0.0003611,0,
		0.000690079,0.0002492,0,			-- 740
		0.000476021,0.0001719,0,
		0.000332301,0.00012,0,
		0.000234826,0.0000848,0,
		0.000166151,0.00006,0,				-- 760
		0.000117413,0.0000424,0,
		8.30753E-05,0.00003,0,
		5.87065E-05,0.0000212,0,
		4.15099E-05,0.00001499,0 			-- 780
	}
	
local plankDist = {
		1.458406704, 1.487673332, 1.515508582, 1.541905864, -- 380-395
		1.566863811, 1.590385858, 1.612479829, 1.633157545, -- 400
		1.652434439, 1.670329188, 1.686863371, 1.702061136, -- 420
		1.715948888, 1.728554999, 1.739909530, 1.750043979, -- 440
		1.758991043, 1.766784394, 1.773458482, 1.779048341, -- 460
		1.783589425, 1.787117445, 1.789668232, 1.791277604, -- 480
		1.791981255, 1.791814644, 1.790812907, 1.789010772, -- 500
		1.786442488, 1.783141755, 1.779141677, 1.774474707, -- 520
		1.769172607, 1.763266416, 1.756786421, 1.749762131, -- 540
		1.742222261, 1.734194720, 1.725706596, 1.716784159, -- 560
		1.707452848, 1.697737282, 1.687661254, 1.677247743, -- 580
		1.666518919, 1.655496154, 1.644200029, 1.632650353, -- 600
		1.620866172, 1.608865787, 1.596666765, 1.584285961, -- 620
		1.571739532, 1.559042954, 1.546211043, 1.533257970, -- 640
		1.520197278, 1.507041907, 1.493804205, 1.480495950, -- 660
		1.467128369, 1.453712154, 1.440257480, 1.426774025, -- 680
		1.413270986, 1.399757093, 1.386240633, 1.372729459, -- 700
		1.359231011, 1.345752331, 1.332300076, 1.318880534, -- 720
		1.305499641, 1.292162992, 1.278875856, 1.265643190, -- 740
		1.252469650, 1.239359606, 1.226317155, 1.213346126, -- 760
		1.200450100} -- 780
		
local measuredDist = {
		 1.1912, 0.9786, 1.0464, 1.0623, -- 380-395
		 1.2320, 1.7515, 1.6946, 1.7043, -- 400		 
		 1.7568, 1.7242, 1.6532, 1.4769, -- 420
		 1.7482, 1.8788, 1.9451, 2.0325, -- 440
		 2.0370, 2.0476, 1.9932, 1.9956, -- 460
		 2.0486, 2.0423, 1.8253, 1.9508, -- 480
		 1.9654, 1.8832, 1.9505, 1.9060, -- 500
		 1.7536, 1.8786, 1.8584, 1.8922, -- 520
		 1.8940, 1.8384, 1.8646, 1.8676, -- 540
		 1.8332, 1.8368, 1.8314, 1.8432, -- 560
		 1.8258, 1.8472, 1.7822, 1.7800, -- 580
		 1.7832, 1.7510, 1.7556, 1.7074, -- 600
		 1.6856, 1.6925, 1.6714, 1.6450, -- 620		
		 1.6481, 1.6142, 1.5954, 1.5806, -- 640
		 1.4623, 1.5624, 1.5500, 1.5198, -- 660
		 1.5028, 1.4832, 1.4648, 1.4632, -- 680
		 1.4332, 1.4124, 1.4080, 1.3870, -- 700 
		 1.3485, 1.3537, 1.3301, 1.3258, -- 720
		 1.3027, 1.2807, 1.2854, 1.2720, -- 740
		 1.2632, 1.2529, 1.2205, 1.2106, -- 760 
		 1.2058} -- 780
		

wavelengthDivisionsChanged = function()

	tChanged()
	-- values to set the matrix with the wavelengths 
	local XYZW = {}
	local betaR = {}	
	-- init the arrays to ensure that they have 16 values
	local divw = {}
	getAttr("RENDERER", "CURRENT", "wavelengthDivisions", 0, divw);
	for i = 1, divw[1] do
		XYZW[i] = {}
		for k = 1, 4 do
			XYZW[i][k] = 0
		end
	end
	
	local part = 81.0 / divw[1]
	
	local tSun = {}
	getAttr("RENDERER", "CURRENT", "temperature", 0, tSun);
	
	local p = {}
	local t = {}
	local ir = {}
	
	getAttr("RENDERER", "CURRENT", "pressure", 0, p)
	getAttr("RENDERER", "CURRENT", "temperature", 0, t)
	getAttr("RENDERER", "CURRENT", "indexOfRefraction", 0, ir)
	-- set the matrix with the wavelengths to be computed
	local incw = (780.0 - 380.0)/divw[1]
	local halfIncw = incw * 0.5

	local n = p[1] / (1.38e-23 *(t[1]+273))
	local k = 2.0 * math.pow(math.pi,2) * math.pow(math.pow(ir[1],2) - 1, 2) / (3 * n)

	-- local planck = {}
	-- local totalWeight = 0;
	-- for i = 1, divw[1] do
		-- local wavelength = 380 + (incw * (i)) + halfIncw
		-- local wav = math.floor((wavelength - 380) / 5) * 5 + 380
		-- planck[i] = computePlank(wav*10e-10, tSun[1])
		-- totalWeight = totalWeight + planck[i]
	-- end
	for i = 1, divw[1] do
		local wavelength = 380 + (incw * (i)) + halfIncw
		betaR[1] = k/math.pow(wavelength*10e-10, 4)
		local start = math.floor((i-1)*part) 
		local ende = math.floor(i*part)-1
		for j = start, ende do
			XYZW[i][1] = XYZW[i][1] + XYZ[j*3 + 1]
			XYZW[i][2] = XYZW[i][2] + XYZ[j*3 + 2]
			XYZW[i][3] = XYZW[i][3] + XYZ[j*3 + 3]
			XYZW[i][4] = XYZW[i][4] + measuredDist[j+1]
		end
		local coef = ende - start + 1
		XYZW[i][1] = XYZW[i][1] / coef
		XYZW[i][2] = XYZW[i][2] / coef 
		XYZW[i][3] = XYZW[i][3] / coef
		XYZW[i][4] = XYZW[i][4] / coef
		
		setBuffer("atmos::xyzw", (i-1)*16, "VEC4", XYZW[i]);
		setBuffer("atmos::betaR", (i-1)*4, "FLOAT", betaR);

	end
	
end
	
	
