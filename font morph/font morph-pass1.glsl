// Shader downloaded from https://www.shadertoy.com/view/ltcXzs
// written by shadertoy user FabriceNeyret2
//
// Name: font morph
// Description: trying the new font texture https://www.shadertoy.com/view/llcXRl

layout (location = 0) out vec4 fragColor;
uniform vec3      iResolution;           // viewport resolution (in pixels)
uniform float     iGlobalTime;           // shader playback time (in seconds)
uniform float     iChannelTime[4];       // channel playback time (in seconds)
uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
uniform vec4      iDate;                 // (year, month, day, time in secs)
uniform float     iSampleRate;           // sound sample rate (i.e., 44100)
#define iChannel0 sTD2DInputs[0]
#define iChannel1 sTD2DInputs[1]
#define iChannel2 sTD2DInputs[2]
#define iChannel3 sTD2DInputs[3]
#define iTime iGlobalTime
//if it's cube texture, then replace sTD2DInputs with sTDCubeInputs

 // --- access to the image of ascii code c
vec4 asciiChar(vec2 p, int C) {
    if (p.x<0.|| p.x>1. || p.y<0.|| p.y>1.) return vec4(0,0,0,1e5);
  //return texture   ( iChannel0, p/16. + fract( vec2(C, 15-C/16) / 16. ) );
  //return textureLod( iChannel0, p/16. + fract( vec2(C, 15-C/16) / 16. ) , 
  //                   log2(length(fwidth(p/16.*iResolution.xy))) );
    return textureGrad( iChannel0, p/16. + fract( vec2(C, 15-C/16) / 16. ) , 
                       dFdx(p/16.),dFdy(p/16.) );
    // possible variants: (but better separated in an upper function) 
    //     - inout pos and include pos.x -= .5 + linefeed mechanism
    //     - flag for bold and italic 
}

// --- display int4
vec4 pInt(vec2 p, float n) {
    vec4 v = vec4(0);
    if (n < 0.) 
        v += asciiChar(p - vec2(-.5,0), 45 ),
        n = -n;

    for (float i = 3.; i>=0.; i--) 
        n /= 10.,
        v += asciiChar(p - vec2(.5*i,0), 48+ int(fract(n)*10.) );
    return v;
}

void mainImage( out vec4 O,  vec2 U )
{
    U /= iResolution.y;
    float t = 3.*iTime;

    O = asciiChar(U,int(t));     // try .xxxx for mask, .wwww for distance field.
 // return;                 // uncomment to just see the letter count.
    
    vec4 O2 = asciiChar(U,int(++t));
    O = mix(O,O2,fract(t));             // linear morphing 
 // O = sqrt(mix(O*O,O2*O2,fract(t)));  // quadratic morphing
    
    
    O =  smoothstep(.5,.49,O.wwww)
       * O.yzww;                        // comment for B&W

  
  U *= 8.; O+=pInt(U,t).xxxx;           // ascii code
  U.x -=9.; 
  O += asciiChar(U,64+13   ).x; U.x-=.5;     // text
  O += asciiChar(U,64+15+32).x; U.x-=.5;
  O += asciiChar(U,64+18+32).x; U.x-=.5;
  O += asciiChar(U,64+16+32).x; U.x-=.5;
  O += asciiChar(U,64+ 8+32).x; U.x-=.5;
  O += asciiChar(U,64+ 9+32).x; U.x-=.5;
  O += asciiChar(U,64+14+32).x; U.x-=.5;
  O += asciiChar(U,64+ 7+32).x; U.x-=.5;
}

void main ()
{
  vec4 color = vec4 (0.0, 0.0, 0.0, 1.0);
  mainImage (color, gl_FragCoord.xy);
  color.w = 1.0;
  fragColor = color;
}
