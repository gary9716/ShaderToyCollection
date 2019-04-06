// Shader downloaded from https://www.shadertoy.com/view/MllGRX
// written by shadertoy user Flyguy
//
// Name: 2D DFT Test
// Description: Testing a basic 2d fft function, probably not the optimal way of doing it.
//    Increase FFT_SIZE to get a higher quality image.

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

#define FFT_SIZE 48
#define PI 3.14159265359

#define avg(v) ((v.x+v.y+v.z)/3.0)

vec2 fft(vec2 uv)
{
    vec2 complex = vec2(0,0);
    
    uv *= float(FFT_SIZE);
    
    float size = float(FFT_SIZE);
    
    for(int x = 0;x < FFT_SIZE;x++)
    {
    	for(int y = 0;y < FFT_SIZE;y++)
    	{
            float a = 2.0 * PI * (uv.x * (float(x)/size) + uv.y * (float(y)/size));
            vec3 samplev = texture(iChannel0,mod(vec2(x,y)/size,1.0)).rgb;
            complex += avg(samplev)*vec2(cos(a),sin(a));
        }
    }
    
    return complex;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 res = iResolution.xy / iResolution.y;
	vec2 uv = fragCoord.xy / iResolution.y;
    uv.x += (1.0-res.x)/2.0;
    uv.y = 1.0-uv.y;
    
    vec3 color = vec3(0.0);
    
    color = texture(iChannel0,uv).rgb;
    
    if(uv.x < 1.0 && uv.x > 0.0)
    {
    	color = vec3(length(fft(uv-0.5))/float(FFT_SIZE));
    }
    
	fragColor = vec4(color,1.0);
}

void main ()
{
  vec4 color = vec4 (0.0, 0.0, 0.0, 1.0);
  mainImage (color, gl_FragCoord.xy);
  color.w = 1.0;
  fragColor = color;
}
