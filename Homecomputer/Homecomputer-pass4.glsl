// Shader downloaded from https://www.shadertoy.com/view/XdVGWt
// written by shadertoy user nimitz
//
// Name: Homecomputer
// Description: Soundcloud track by Dubmood: https://soundcloud.com/dubmood

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

/*
 	The goal of this Buffer is to prepare
	the sound data so that it can be used 
	by the other buffers

	Data output:
	x = fft
	y = waveform
	z = filtered waveform
	w = filtered fft summed over many bands
*/

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 q = fragCoord.xy/iResolution.xy;
    float fft  = texture( iChannel1, vec2(q.x,0.25) ).x;
	float nwave = texture( iChannel1, vec2(q.x,0.75) ).x;
    
    float owave = texture( iChannel0, vec2(q.x,0.25) ).z;
    float offt  = texture( iChannel0, vec2(q.x,0.25) ).w;
    
    
    float fwave = mix(nwave,owave, 0.85);
    
    
    /*
        get fft sum over many bands, this will allow
		to ge tthe current "intensity" of a track
	*/
    float nfft = 0.;
    for (float i = 0.; i < 1.; i += 0.05)
    {
        nfft += texture( iChannel1, vec2(i,0.25) ).x; 
    }
    nfft = clamp(nfft/30.,0.,1.);
    
    float ffts = mix(nfft, offt, 0.8);
    
    if (iFrame < 5) 
    {
        fft = 0.;
        fwave= .5;
        ffts = 0.;
    }
    
    fragColor = vec4(fft, nwave, fwave, ffts);
}

void main ()
{
  vec4 color = vec4 (0.0, 0.0, 0.0, 1.0);
  mainImage (color, gl_FragCoord.xy);
  color.w = 1.0;
  fragColor = color;
}
