// Shader downloaded from https://www.shadertoy.com/view/XdVGWt
// written by shadertoy user nimitz
//
// Name: Homecomputer
// Description: Soundcloud track by Dubmood: https://soundcloud.com/dubmood

uniform vec3      iResolution;           // viewport resolution (in pixels)
uniform float     iGlobalTime;           // shader playback time (in seconds)
uniform float     iChannelTime[4];       // channel playback time (in seconds)
uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
uniform sampler2D iChannel0;             // input channel. XX = 2D/Cube
uniform sampler2D iChannel1;             // input channel. XX = 2D/Cube
uniform vec4      iDate;                 // (year, month, day, time in secs)
uniform float     iSampleRate;           // sound sample rate (i.e., 44100)

//Homecomputer by nimitz (twitter: @stormoid)

//Code is in the other tabs:
//Buf A = Velocity and position handling
//Buf B = Rendering
//Buf C = Soundcloud filtering and propagation

#define time iTime

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 q = fragCoord.xy / iResolution.xy;
	vec3 col = texture(iChannel0, q).rgb;
    col *= sin(gl_FragCoord.y*350.+time)*0.04+1.;//Scanlines
    col *= sin(gl_FragCoord.x*350.+time)*0.04+1.;
    col *= pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1)*0.35+0.65; //Vign
	fragColor = vec4(col,1.0);
}

void main (void)
{
  vec4 color = vec4 (0.0, 0.0, 0.0, 1.0);
  mainImage (color, gl_FragCoord.xy);
  color.w = 1.0;
  gl_FragColor = color;
}
