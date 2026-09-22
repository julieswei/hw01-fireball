#version 300 es


/*
Your fragment shader should apply a gradient of colors to your fireball's surface, 
where the fragment color is correlated in some way to the vertex shader's displacement.

*/

precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform vec3 u_CameraPos;
uniform float u_Time;
uniform float u_SpiritAnger;
uniform float u_SpiritEmbarassment;
uniform float u_SpiritHyperness;



in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec3 fs_Pos;
in float vs_vDisp;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.


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



void main()
{
    // Material base color (before shading)
        vec4 diffuseColor; // this is the final color
        vec4 pink = vec4(0.89, 0.243, 0.471, 0.7); // a = 0.7
        vec4 purple = vec4(0.6, 0.243, 0.89, 0.8); // a = 0.8
        vec4 blue = vec4(0.412, 0.278, 0.871, 0.8); // a = 0.85
        vec4 green = vec4(0.4, 0.878, 0.69, 0.8); // a = 0.85
        vec4 yellow = vec4(0.941, 0.882, 0.612, 0.8); // a = 0.85
        vec4 yellowPink = vec4(0.969, 0.812, 0.706, 0.8); // a = 0.85
        vec4 whiteish = vec4(1.0, 0.965, 0.945, 0.8);
        vec4 whiteish2 = vec4(1.0, 0.91, 0.851, 0.8);

        vec4 angryColor = vec4(1.0, 0.161, 0.0, 0.8); //
        vec4 angryColor2 = vec4(0.82, 0.0, 0.0, 0.8);
        
        vec4 blushColor = vec4(1.0, 0.537, 0.431, 0.8);
        vec4 lightPinkColor = vec4(0.922, 0.396, 0.557, 0.8);
        vec4 angryBlueColor = vec4(0.0, 0.616, 1.0, 0.8);




        // gradient upwards and outwards
        // radiating out from a point. if 0,0,0 is center of sphere, maybe... corePoint = (0, -0.2, 0)
        // currrent point gets compared to corePoint, color gradients (smooths) from color1 to color2
        vec3 corePoint = vec3(0.0, -0.5, 0.0);

        vec3 swirlPos = fs_Pos;

        // do swirly math to swirlPos using u_Time
        //
        //float angle = sin(u_Time) * 5.0;
        // sample 

        // get a point , start it with fs_pos, vary it with time
        // changing .y because i want swirls to go up
        vec3 noisePoint = fs_Pos;
        noisePoint.y -= u_Time * 0.2;

        // two different points
        float noiseX = perlinNoise3D(noisePoint);
        float noiseY = perlinNoise3D(noisePoint + vec3(3.0, 3.0, 3.0)); // some offset

        float strength1 = 0.4;
        swirlPos.x += noiseX * strength1;
        swirlPos.y += noiseY * strength1;

        float distanceToCore = distance(corePoint, swirlPos); // further = larger distanceToCore


        //float smoothedDistance = smoothstep(0.3, 2.2, distanceToCore);
        float innerBlend = smoothstep(0.0, 0.93, distanceToCore);
        float outerBlend = smoothstep(0.9, 2.2, distanceToCore);

        // pink --> purple --> ....blue...?
        vec4 color1 = mix(purple, pink, innerBlend);
        vec4 color2 = mix(color1, yellow, outerBlend);

        diffuseColor = color2;



        // "highlights"
        float vRemapped = (vs_vDisp + 1.0) * 0.5;

        float highlight = smoothstep(0.0, 0.9, vRemapped);

        vec4 color3 = mix(diffuseColor, yellowPink, highlight);

        diffuseColor = color3;

        // ====== EMBARASSMENT =======
        float embarassMask = smoothstep(0.1, 0.4, highlight);
        diffuseColor = mix(diffuseColor, pink, u_SpiritEmbarassment * embarassMask * 0.25);

        // SWIRLY BOIS
        vec3 swirlBoisPos = fs_Pos;

        vec3 swirlNoisePoint = fs_Pos;

        
        swirlNoisePoint.y -= u_Time * 0.4;

        // two different points
        float swirlNoiseX = perlinNoise3D(swirlNoisePoint);
        //float swirlNoiseY = perlinNoise3D(swirlNoisePoint + vec3(2.0, 2.0, 2.0)); // some offset
        //float swirlNoiseY = perlinNoise3D(swirlNoisePoint + vec3(3.0, 3.0, 3.0)); // some offset
        float swirlNoiseY = perlinNoise3D(swirlNoisePoint + vec3(4.0, 4.0, 4.0)); // some offset

        float strength2 = 2.4; //2.0
        swirlBoisPos.x += swirlNoiseX * strength2;
        swirlBoisPos.y += swirlNoiseY * strength2;

        // i now have a warped coordinate in swirlBoisPos
        // put it in perlinnoise to get a sample
        // grab the high parts and give them white
        float noiseSample = perlinNoise3D(swirlBoisPos);

        // only grab tthe high parts
        float swirlMask = smoothstep(0.1, 0.4, noiseSample);
        
        diffuseColor = mix(diffuseColor, whiteish2, swirlMask);

        float embarassSwirlMask = smoothstep(0.1, 0.6, swirlMask);
        diffuseColor = mix(diffuseColor, lightPinkColor, u_SpiritEmbarassment * embarassSwirlMask * 0.25);


        // ===== ANGER KNOB ======

        float angerMask = smoothstep(0.1, 0.6, innerBlend);
        diffuseColor = mix(diffuseColor, angryColor, u_SpiritAnger * angerMask);
        
        float angerMask2 = smoothstep(0.1, 0.6, highlight);
        diffuseColor = mix(diffuseColor, angryColor, u_SpiritAnger * angerMask2);



        // ====== LIGHTING ========

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

        float ambientTerm = 0.03; //0.06

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // fresnel, for ghosty ish effect
        vec3 viewDir = normalize(u_CameraPos - fs_Pos);
        float fresnel = 1.0 - abs(dot(normalize(fs_Nor.xyz), viewDir));
       
        // normal to embarrassed
        vec4 fresnelColor = mix(green, lightPinkColor, u_SpiritEmbarassment);

        // to angry
        fresnelColor = mix(fresnelColor, angryBlueColor, u_SpiritAnger);

        diffuseColor = mix(diffuseColor, fresnelColor, fresnel * 0.53);
        // Compute final shaded color
        out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
}
