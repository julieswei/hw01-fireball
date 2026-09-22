#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself
uniform float u_Time;
uniform float u_SpiritAnger;
uniform float u_SpiritEmbarassment;
uniform float u_SpiritHyperness;



in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.

out vec3 fs_Pos;

const vec4 lightPos = vec4(2, 3, 7, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader. 5,5,3,1

out float vs_vDisp;

// === NOISE LIBRARY =====
// plug and play noise library with noises I like

vec3 hash(vec3 p) // hash
{
	p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
			  dot(p,vec3(269.5,183.3,246.1)),
			  dot(p,vec3(113.5,271.9,124.6)));

	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

// 3D perlin Noise surflet and loop
float surflet(vec3 p, vec3 gridPoint) {
    vec3 t2 = abs(p - gridPoint);

    vec3 t = vec3(1.f)
           - 6.f * pow(t2, vec3(5.f))
           + 15.f * pow(t2, vec3(4.f))
           - 10.f * pow(t2, vec3(3.f));

    vec3 gradient = hash(gridPoint);
    vec3 diff = p - gridPoint;

    float height = dot(diff, gradient);

    return height * t.x * t.y * t.z;
}


float perlinNoise3D(vec3 p) {
    float surfletSum = 0.f;

    for(int dx = 0; dx <= 1; dx++) {
        for(int dy = 0; dy <= 1; dy++) {
            for(int dz = 0; dz <= 1; dz++) {

                surfletSum += surflet(p, floor(p) + vec3(dx, dy, dz));

            }
        }
    }

    return surfletSum;
}


float fbm3D(vec3 p) {
    float total = 0.0;
    float persistence = 0.5; // 0.5 og fine detail
    int octaves = 4; // 8 og
    float freq = 0.45; // 2 og starting size
    float amp = 1.6; // 0.5 og first layer noise strength

    for(int i = 1; i <= octaves; i++) {

        total += perlinNoise3D(p * freq) * amp;

        freq *= 2.0;
        amp *= persistence;
    }

    return total;
}

// ===== Toolbox ======

// t= value im reshaping (between 0 and 1)
// b = how i want tto bias the value
float bias(float b, float t) {
    return pow(t, log(b) / log(0.5));
}

// t= value im reshaping (between 0 and 1)
// g = how i want tto bias the value (0.5 = no change)
float gain(float g, float t){
    if (t < 0.5f) return bias(1.0 - g, 2.0 * t) / 2.0;
    else return 1.0 - bias(1.0 - g, 2.0 - 2.0 * t) / 2.0;
}



void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.
    // =========================================
    // SPIRIT FLAME VERTEX DEFORMATION
    // =========================================

    // transformation
    // brainstorming: general globbiness, flames go up, mostly skewed up, 
    vec4 deformedPos = vs_Pos;



    // ROOTING (bottom section from y = -1 to -0.5-ish, moves less than top)
    // our sphere radius is 1, at 0,0,0, so bottom is -1
    float groundMask = smoothstep(-1.0, -0.5, vs_Pos.y);
    

    // ======= LARGE SCALE DEFORMATIONS =======
    // sin(POSITION * frequency + TIME * speed)
    // use mostly vs_pos.y because i want the globbiness to go vertically
    // utime * how fast it is (currently this is the lower speed)
    // use - u_ttime because i want the "wave" to go upwards

    // directional warp
    deformedPos.x += sin(vs_Pos.y * 3.6 + vs_Pos.z * 2.0 - u_Time * 2.0) * 0.03 * groundMask; // 0.05
    deformedPos.y += cos(vs_Pos.y * 2.0 + vs_Pos.z * 2.0 - u_Time * 1.0) * 0.06 * groundMask; // 0.08
    deformedPos.z += sin(vs_Pos.y * 2.4 + vs_Pos.x * 2.0 - u_Time * 1.3) * 0.03 * groundMask; // 0.05
    
    // large surface bulges using f(x,y,z) = h
    // still using - utime to make it go upwards
    float h = sin(deformedPos.y * 4.0 + deformedPos.z * 1.5 - u_Time * 1.2) * 0.06;

    deformedPos.xyz += vs_Nor.xyz * (h * 1.1);


    // ======== SMALLER SCALE DEFORMATIONS ========


    vec3 noisePos = deformedPos.xyz;
    // animate 

    
    noisePos.y -= u_Time * 0.5; //0.6 is roil

    // use fbm
    float v = fbm3D(noisePos);
    vs_vDisp = v;

    deformedPos.xyz += vs_Nor.xyz * v * 0.2 * groundMask;

    // =========== SHAPING =============
    // skew the top ones to stretch up like flame tongues
    // smoothstep(a, b, vs_Pos.y) a = how far down the ball the tongues start
    float topMask = smoothstep(0.2, 0.85, vs_Pos.y);

    // sharpen the top here to make a pointy shape
    // positions near center (the center axis) get amplified
    // use a center "mask"

    // a sphere, the nearer it is to the top and middle, the more the x and z values are closer to 0
    // how far is this vert from ceenter axis (using length() aka the magnitude)
    // the larger the centerDist, the further away from center axis it is
    float centerDist1 = length(vs_Pos.xz);
    float centerDist2 = length(vs_Pos.xz - vec2(0.52, -0.3)); // adding another point for more tonguey flamey thingies
    float centerDist3 = length(vs_Pos.xz - vec2(-0.5, 0.55)); // adding yet another point for more tonguey flamey thingies

    // smoothstep and inverse because i want smaller centerDist values to be bigger
    // closer to center, boost more
    float centerMask1 = 1.0 - smoothstep(0.0, 0.5, centerDist1); // tongue widths. smaller = sharper tongue
    float centerMask2 = 1.0 - smoothstep(0.0, 0.6, centerDist2);
    float centerMask3 = 1.0 - smoothstep(0.0, 0.55, centerDist3);


    topMask = bias(0.06, topMask); // value lower = sharper tips


    float tipMask1 = topMask * centerMask1;
    float tipMask2 = topMask * centerMask2;
    float tipMask3 = topMask * centerMask3;

    // ==== Embarassmnet =====, tongues are lower

    // stretch tongues upward
    // have all three tongues pull the y up, include fbm scaled value
    // 1 to 0.5
    // as embarrassment goes from 0 to 1, change height multiplier from 1.0 to 0.5.
    float embarassHeight = mix(1.0, 0.7, u_SpiritEmbarassment);

    deformedPos.y += tipMask1 * (0.78 + v * 0.35) * embarassHeight;
    deformedPos.y += tipMask2 * (0.48 + v * 0.35) * embarassHeight;
    deformedPos.y += tipMask3 * (0.50 + v * 0.35) * embarassHeight;





    // sway tongues go wee woo
    deformedPos.x += tipMask1 * sin(u_Time * 2.0) * 0.09;
    deformedPos.x += tipMask2 * sin(u_Time * 2.5 + 1.1) * 0.07;
    deformedPos.x += tipMask3 * sin(u_Time * 1.7 + 2.2) * 0.08;

   

    // ===== ANGER ======
    float angerMovement = u_SpiritAnger * 2.0;

    deformedPos.x += tipMask1 * sin(u_Time * 3.1) * 0.18 * angerMovement;
    deformedPos.x += tipMask2 * sin(u_Time * 4.2) * 0.16 * angerMovement;
    deformedPos.x += tipMask3 * sin(u_Time * 2.7) * 0.145 * angerMovement;


    // ===== HYPER ======
    float hyperTongueMovement = u_SpiritHyperness * 2.0;

    deformedPos.x += tipMask1 * sin(u_Time * 10.5 + 1.0) * 0.015 * hyperTongueMovement;
    deformedPos.x += tipMask2 * sin(u_Time * 11.8 + 0.4) * 0.019 * hyperTongueMovement;
    deformedPos.x += tipMask3 * sin(u_Time * 9.7 + 0.7) * 0.012 * hyperTongueMovement;


    // add to pos.y (up) with topmask value * base value * fbm-scaled-value
    //deformedPos.y += tipMask * (0.75 + v * 0.2);

    // ====== POLISH and extras ========
    // BREATHING
    // rhythm = inhale(expand) -- hold ---- exhale ----- repeat
    float breathFrequency = mix(0.5, 1.5, u_SpiritHyperness);
    float breath = sin(u_Time * breathFrequency);

    breath = (breath + 1.0) * 0.5;

    // use gain
    breath = gain(0.4, breath);

    // smoothstep 
    breath = smoothstep(0.0, 1.0, breath);

    // want negatives
    breath = breath - 0.5;
    breath = breath * 0.35; // how big it breathes

    float embarassBreath = mix(1.0, 0.3, u_SpiritEmbarassment);
    float hyperBreathSize = mix(1.0, 0.75, u_SpiritHyperness);


    deformedPos.xyz += vs_Nor.xyz * breath * groundMask * embarassBreath * hyperBreathSize;


    // =========================================
    // send position (to frag shader

    vec4 modelposition = u_Model * deformedPos;   // Temporarily store the transformed vertex positions for use below

    // send fs_pos with updated transformed model position
    fs_Pos = modelposition.xyz;
    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies
    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
