#include "optixParams.h" // our launch params



extern "C" {
    __constant__ LaunchParams optixLaunchParams;
}
//  a single ray type
enum { PHONG=0, SHADOW, RAY_TYPE_COUNT };

struct colorPRD{
    float3 color;
    unsigned int seed;
} ;

struct shadowPRD{
    float shadowAtt;
    unsigned int seed;
} ;





// -------------------------------------------------------
// closest hit computes color based lolely on the triangle normal

extern "C" __global__ void __closesthit__radiance() {

    colorPRD &prd = *(colorPRD *)getPRD<colorPRD>();

    const TriangleMeshSBTData &sbtData
      = *(const TriangleMeshSBTData*)optixGetSbtDataPointer();  

    // retrieve primitive id and indexes
    const int   primID = optixGetPrimitiveIndex();
    const uint3 index  = sbtData.index[primID];

    // get barycentric coordinates
    const float u = optixGetTriangleBarycentrics().x;
    const float v = optixGetTriangleBarycentrics().y;

    // compute normal
    const float4 n
        = (1.f-u-v) * sbtData.vertexD.normal[index.x]
        +         u * sbtData.vertexD.normal[index.y]
        +         v * sbtData.vertexD.normal[index.z];

    // intersection position
    const float3 pos = optixGetWorldRayOrigin() + optixGetRayTmax()*optixGetWorldRayDirection();

    // direction towards light
    float3 lPos = make_float3(optixLaunchParams.global->lightPos);
    float3 lDir = normalize(lPos - pos);
    float3 nn = normalize(make_float3(n));
    float intensity = max(dot(lDir, nn),0.0f);
    

    // ray payload
    shadowPRD shadowAttPRD;
    shadowAttPRD.shadowAtt = 1.0f;
    shadowAttPRD.seed = prd.seed;
    uint32_t u0, u1;
    packPointer( &shadowAttPRD, u0, u1 );  
  
    // trace shadow ray
    int squaredShadowRays = optixLaunchParams.global->shadowRays;
    float shadowTotal = 0.0f;
    for (int i = 0; i < squaredShadowRays; ++i) {
        for (int j = 0; j < squaredShadowRays; ++j) {

            //uint32_t seed = tea<4>(  , i * squaredShadowRays + j );

            //const float2 subpixel_jitter = make_float2( i * delta.x + delta.x *  rnd( seed ), j * delta.y + delta.y * rnd( seed ) );
            //const float2 subpixel_jitter = make_float2( rnd( seed )-0.5f, rnd( seed )-0.5f );
            lPos.x = -0.2 + i * 1.0/squaredShadowRays * 0.4f + rnd(prd.seed) * 1.0/squaredShadowRays * 0.4;
            lPos.z = -0.2 + j * 1.0/squaredShadowRays * 0.4f + rnd(prd.seed) * 1.0/squaredShadowRays * 0.4;
            lDir = normalize(lPos - pos);
            optixTrace(optixLaunchParams.traversable,
                pos,
                lDir,
                0.00001f,           // tmin
                10,                 // tmax
                0.0f,               // rayTime
                OptixVisibilityMask( 255 ),
                OPTIX_RAY_FLAG_NONE, //OPTIX_RAY_FLAG_NONE,
                SHADOW,             // SBT offset
                RAY_TYPE_COUNT,     // SBT stride
                SHADOW,             // missSBTIndex 
                u0, u1 );

                shadowTotal += shadowAttPRD.shadowAtt;
        }
    }
    shadowTotal /= (squaredShadowRays * squaredShadowRays);

    if (sbtData.hasTexture && sbtData.vertexD.texCoord0) {  
        // get barycentric coordinates
        // compute pixel texture coordinate
        const float4 tc
          = (1.f-u-v) * sbtData.vertexD.texCoord0[index.x]
          +         u * sbtData.vertexD.texCoord0[index.y]
          +         v * sbtData.vertexD.texCoord0[index.z];
        // fetch texture value
        
        float4 fromTexture = tex2D<float4>(sbtData.texture,tc.x,tc.y);
        prd.color = make_float3(fromTexture) * min(intensity * shadowTotal + 0.0, 1.0);
    }
    else
        prd.color = sbtData.diffuse * min(intensity * shadowTotal + 0.0, 1.0);
}


// any hit to ignore intersections with back facing geometry
extern "C" __global__ void __anyhit__radiance() {

}


// miss sets the background color
extern "C" __global__ void __miss__radiance() {

    colorPRD &prd = *(colorPRD*)getPRD<colorPRD>();
    // set blue as background color
    prd.color = make_float3(0.0f, 0.0f, 1.0f);
}


// -----------------------------------------------
// Shadow rays

extern "C" __global__ void __closesthit__shadow() {

    shadowPRD &prd = *(shadowPRD*)getPRD<shadowPRD>();
    prd.shadowAtt = 0.0f;
}


// any hit for shadows
extern "C" __global__ void __anyhit__shadow() {

}


// miss for shadows
extern "C" __global__ void __miss__shadow() {

    shadowPRD &prd = *(shadowPRD*)getPRD<shadowPRD>();
    prd.shadowAtt = 1.0f;
}


// -----------------------------------------------
// Light material


extern "C" __global__ void __closesthit__light() {

    colorPRD &prd = *(colorPRD*)getPRD<colorPRD>();
    prd.color = make_float3(1.0f);
}


extern "C" __global__ void __anyhit__light() {
}


extern "C" __global__ void __miss__light() {
}


extern "C" __global__ void __closesthit__light_shadow() {

    const TriangleMeshSBTData &sbtData
      = *(const TriangleMeshSBTData*)optixGetSbtDataPointer();  

    // retrieve primitive id and indexes
    const int   primID = optixGetPrimitiveIndex();
    const uint3 index  = sbtData.index[primID];

    // get barycentric coordinates
    const float u = optixGetTriangleBarycentrics().x;
    const float v = optixGetTriangleBarycentrics().y;

    // compute normal
    const float4 n
        = (1.f-u-v) * sbtData.vertexD.normal[index.x]
        +         u * sbtData.vertexD.normal[index.y]
        +         v * sbtData.vertexD.normal[index.z];

    float3 intersectionPoint = optixGetWorldRayOrigin() + optixGetRayTmax()*optixGetWorldRayDirection();
    float ndotl = max(0.0f, dot(normalize(make_float3(n)), -normalize(intersectionPoint-optixGetWorldRayOrigin())));
    shadowPRD &prd = *(shadowPRD*)getPRD<shadowPRD>();
    prd.shadowAtt = ndotl;
}


// any hit to ignore intersections based on alpha transparency
extern "C" __global__ void __anyhit__light_shadow() {
}


// miss sets the background color
extern "C" __global__ void __miss__light_shadow() {
}




// -----------------------------------------------
// Metal Phong rays

extern "C" __global__ void __closesthit__phong_metal() {

    const TriangleMeshSBTData &sbtData
      = *(const TriangleMeshSBTData*)optixGetSbtDataPointer();  

    // retrieve primitive id and indexes
    const int   primID = optixGetPrimitiveIndex();
    const uint3 index  = sbtData.index[primID];

    // get barycentric coordinates
    const float u = optixGetTriangleBarycentrics().x;
    const float v = optixGetTriangleBarycentrics().y;

    // compute normal
    const float4 n
        = (1.f-u-v) * sbtData.vertexD.normal[index.x]
        +         u * sbtData.vertexD.normal[index.y]
        +         v * sbtData.vertexD.normal[index.z];
    // ray payload

    float3 normal = normalize(make_float3(n));

    // entering glass
    //if (dot(optixGetWorldRayDirection(), normal) < 0)

    colorPRD &prd = *(colorPRD*)getPRD<colorPRD>();

    colorPRD afterPRD;
    afterPRD.color = make_float3(1.0f);
    afterPRD.seed = prd.seed;
    uint32_t u0, u1;
    packPointer( &afterPRD, u0, u1 );  

    const float3 pos = optixGetWorldRayOrigin() + optixGetRayTmax()*optixGetWorldRayDirection();
    //(1.f-u-v) * A + u * B + v * C;
    
    const float glossiness = optixLaunchParams.global->glossiness;
    const int glossy_rays = optixLaunchParams.global->glossyRays;
    float3 glossy = make_float3(0.0f);
    float3 rayDir;
    float3 reflectDir = reflect(optixGetWorldRayDirection(), normal);
    unsigned int seed = prd.seed;
    for (int i = 0; i < glossy_rays; ++i) {
        afterPRD.color = make_float3(1.0f);
        do {
            const float z1 = rnd(seed);
            const float z2 = rnd(seed);
            cosine_power_sample_hemisphere( z1, z2, rayDir, glossiness );
            Onb onb( reflectDir );
            onb.inverse_transform( rayDir );
        } while (dot(rayDir, normal) < 0.001);
        
        optixTrace(optixLaunchParams.traversable,
            pos,
            rayDir,
            0.04f,    // tmin is high to void self-intersection
            1e20f,  // tmax
            0.0f,   // rayTime
            OptixVisibilityMask( 255 ),
            OPTIX_RAY_FLAG_NONE, //OPTIX_RAY_FLAG_NONE,
            PHONG,             // SBT offset
            RAY_TYPE_COUNT,     // SBT stride
            PHONG,             // missSBTIndex 
            u0, u1 );
        glossy += afterPRD.color;
    }
    prd.seed = seed;
    prd.color = make_float3(0.8,0.8,0.8) * glossy / glossy_rays;
}





// -----------------------------------------------
// Glass Phong rays


extern "C" __global__ void __closesthit__phong_glass() {

    const TriangleMeshSBTData &sbtData
      = *(const TriangleMeshSBTData*)optixGetSbtDataPointer();  

    // retrieve primitive id and indexes
    const int   primID = optixGetPrimitiveIndex();
    const uint3 index  = sbtData.index[primID];

    // get barycentric coordinates
    const float u = optixGetTriangleBarycentrics().x;
    const float v = optixGetTriangleBarycentrics().y;

    // compute normal
    const float4 n
        = (1.f-u-v) * sbtData.vertexD.normal[index.x]
        +         u * sbtData.vertexD.normal[index.y]
        +         v * sbtData.vertexD.normal[index.z];

    float3 normal = normalize(make_float3(n));
    const float3 normRayDir = optixGetWorldRayDirection();

    // new ray direction
    float3 rayDir;
    // entering glass
    float dotP;
    if (dot(normRayDir, normal) < 0) {
        dotP = dot(normRayDir, -normal);
        rayDir = refract(normRayDir, normal, 0.66);
    }
    // exiting glass
    else {
        dotP = 0;
        rayDir = refract(normRayDir, -normal, 1.5);
    }

    const float3 pos = optixGetWorldRayOrigin() + optixGetRayTmax() * optixGetWorldRayDirection();
    
    // ray payload 
    colorPRD &prd = *(colorPRD*)getPRD<colorPRD>();

    colorPRD refractPRD;
    refractPRD.color = make_float3(0.0f);
    refractPRD.seed = prd.seed;
    uint32_t u0, u1;
    packPointer( &refractPRD, u0, u1 );  
    
    if (length(rayDir) > 0)
        optixTrace(optixLaunchParams.traversable,
            pos,
            rayDir,
            0.00001f,    // tmin
            1e20f,  // tmax
            0.0f,   // rayTime
            OptixVisibilityMask( 255 ),
            OPTIX_RAY_FLAG_NONE, //OPTIX_RAY_FLAG_NONE,
            PHONG,             // SBT offset
            RAY_TYPE_COUNT,     // SBT stride
            PHONG,             // missSBTIndex 
            u0, u1 );

 
    colorPRD reflectPRD;
    reflectPRD.color = make_float3(0.0f);
    reflectPRD.seed = prd.seed;
    if (dotP > 0) {
        float3 reflectDir = reflect(normRayDir, normal);        
        packPointer( &reflectPRD, u0, u1 );  
        optixTrace(optixLaunchParams.traversable,
            pos,
            reflectDir,
            0.00001f,    // tmin
            1e20f,  // tmax
            0.0f,   // rayTime
            OptixVisibilityMask( 255 ),
            OPTIX_RAY_FLAG_NONE, //OPTIX_RAY_FLAG_NONE,
            PHONG,             // SBT offset
            RAY_TYPE_COUNT,     // SBT stride
            PHONG,             // missSBTIndex 
            u0, u1 );
        float r0 = (1.5f - 1.0f)/(1.5f + 1.0f);
        r0 = r0*r0 + (1-r0*r0) * pow(1-dotP,5);
        prd.color =  refractPRD.color * (1-r0) + r0 * reflectPRD.color;
    }
    else
        prd.color =  refractPRD.color ;
}



extern "C" __global__ void __anyhit__phong_glass() {

}


// miss sets the background color
extern "C" __global__ void __miss__phong_glass() {

    colorPRD &prd = *(colorPRD*)getPRD<colorPRD>();
    // set blue as background color
    prd.color = make_float3(0.0f, 0.0f, 1.0f);
}



// -----------------------------------------------
// Glass Shadow rays

extern "C" __global__ void __closesthit__shadow_glass() {

    shadowPRD &prd = *(shadowPRD*)getPRD<shadowPRD>();
    // ray payload
    shadowPRD afterPRD;
    afterPRD.shadowAtt = 1.0f;
    afterPRD.seed = prd.seed;
    uint32_t u0, u1;
    packPointer( &afterPRD, u0, u1 );  

    const float3 pos = optixGetWorldRayOrigin() + optixGetRayTmax()*optixGetWorldRayDirection();
    
    // trace primary ray
    optixTrace(optixLaunchParams.traversable,
        pos,
        optixGetWorldRayDirection(),
        0.01f,    // tmin
        1e20f,  // tmax
        0.0f,   // rayTime
        OptixVisibilityMask( 255 ),
        OPTIX_RAY_FLAG_NONE, //OPTIX_RAY_FLAG_NONE,
        SHADOW,             // SBT offset
        RAY_TYPE_COUNT,     // SBT stride
        SHADOW,             // missSBTIndex 
        u0, u1 );

    prd.shadowAtt = 0.95f * afterPRD.shadowAtt;
}


// any hit for shadows
extern "C" __global__ void __anyhit__shadow_glass() {

}


// miss for shadows
extern "C" __global__ void __miss__shadow_glass() {

    shadowPRD &prd = *(shadowPRD*)getPRD<shadowPRD>();
    // set blue as background color
    prd.shadowAtt = 1.0f;
}







// -----------------------------------------------
// Primary Rays


extern "C" __global__ void __raygen__renderFrame() {

    // compute a test pattern based on pixel ID
    const int ix = optixGetLaunchIndex().x;
    const int iy = optixGetLaunchIndex().y;
    const auto &camera = optixLaunchParams.camera;  
    

	if (optixLaunchParams.frame.frame == 0 && ix == 0 && iy == 0) {

		// print info to console
		printf("===========================================\n");
        printf("Nau Ray-Tracing Debug\n");
        const float4 &ld = optixLaunchParams.global->lightPos;
        printf("LightPos: %f, %f %f %f\n", ld.x,ld.y,ld.z,ld.w);
        printf("Launch dim: %u %u\n", optixGetLaunchDimensions().x, optixGetLaunchDimensions().y);
        printf("Rays per pixel squared: %d \n", optixLaunchParams.frame.raysPerPixel);
		printf("===========================================\n");
	}


    // ray payload
    colorPRD pixelColorPRD;
    pixelColorPRD.color = make_float3(1.f);

    float raysPerPixel = float(optixLaunchParams.frame.raysPerPixel);
    // half pixel
    float2 delta = make_float2(1.0f/raysPerPixel, 1.0f/raysPerPixel);

    // compute ray direction
    // normalized screen plane position, in [-1, 1]^2
  
    float red = 0.0f, blue = 0.0f, green = 0.0f;
    for (int i = 0; i < raysPerPixel; ++i) {
        for (int j = 0; j < raysPerPixel; ++j) {

            uint32_t seed = tea<4>( (ix * optixGetLaunchDimensions().x + iy) * optixLaunchParams.frame.subFrame, (i*raysPerPixel + j ) * optixLaunchParams.frame.subFrame);

            pixelColorPRD.seed = seed;
            uint32_t u0, u1;
            packPointer( &pixelColorPRD, u0, u1 );  
            const float2 subpixel_jitter = make_float2( i * delta.x + delta.x *  rnd( seed ), j * delta.y + delta.y * rnd( seed ) );
            //const float2 subpixel_jitter = make_float2( rnd( seed )-0.5f, rnd( seed )-0.5f );
            //const float2 subpixel_jitter = make_float2(i * delta.x, j * delta.y);
            const float2 screen(make_float2(ix + subpixel_jitter.x, iy + subpixel_jitter.y)
                            / make_float2(optixGetLaunchDimensions().x, optixGetLaunchDimensions().y) * 2.0 - 1.0);
        
            // note: nau already takes into account the field of view and ratio when computing 
            // camera horizontal and vertival
            float3 rayDir = normalize(camera.direction
                                + (screen.x ) * camera.horizontal
                                + (screen.y ) * camera.vertical);
            
            pixelColorPRD.seed = seed;                                
            // trace primary ray
            optixTrace(optixLaunchParams.traversable,
                    camera.position,
                    rayDir,
                    0.f,    // tmin
                    1e20f,  // tmax
                    0.0f,   // rayTime
                    OptixVisibilityMask( 255 ),
                    OPTIX_RAY_FLAG_NONE,//,OPTIX_RAY_FLAG_DISABLE_ANYHIT
                    PHONG,             // SBT offset
                    RAY_TYPE_COUNT,               // SBT stride
                    PHONG,             // missSBTIndex 
                    u0, u1 );

            red += pixelColorPRD.color.x / (raysPerPixel*raysPerPixel);
            green += pixelColorPRD.color.y / (raysPerPixel*raysPerPixel);
            blue += pixelColorPRD.color.z / (raysPerPixel*raysPerPixel);
        }
    }

    // compute index
    const uint32_t fbIndex = ix + iy*optixGetLaunchDimensions().x;

    optixLaunchParams.global->accumBuffer[fbIndex] = 
        (optixLaunchParams.global->accumBuffer[fbIndex] * optixLaunchParams.frame.subFrame +
        make_float4(red,green,blue,1)) /(optixLaunchParams.frame.subFrame+1);

    float4 rgbaf = optixLaunchParams.global->accumBuffer[fbIndex];
    //convert float (0-1) to int (0-255)
    //const int r = int(255.0f*red);
    //const int g = int(255.0f*green);
    //const int b = int(255.0f*blue);
    const int r = int(255.0f*rgbaf.x);
    const int g = int(255.0f*rgbaf.y);
    const int b = int(255.0f*rgbaf.z);
    // convert to 32-bit rgba value 
    const uint32_t rgba = 0xff000000
      | (r<<0) | (g<<8) | (b<<16);
    // write to output buffer
    optixLaunchParams.frame.colorBuffer[fbIndex] = rgba;
}
  

