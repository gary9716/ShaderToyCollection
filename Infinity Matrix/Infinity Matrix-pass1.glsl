// Shader downloaded from https://www.shadertoy.com/view/Md2fRR
// written by shadertoy user KilledByAPixel
//
// Name: Infinity Matrix
// Description: Endless non repeating pixel fractal zoom made to feel like flying through binary code.

uniform vec3      iResolution;           // viewport resolution (in pixels)
uniform float     iGlobalTime;           // shader playback time (in seconds)
uniform float     iChannelTime[4];       // channel playback time (in seconds)
uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
uniform sampler2D iChannel0;             // input channel. XX = 2D/Cube
uniform sampler2D iChannel1;             // input channel. XX = 2D/Cube
uniform vec4      iDate;                 // (year, month, day, time in secs)
uniform float     iSampleRate;           // sound sample rate (i.e., 44100)

//////////////////////////////////////////////////////////////////////////////////
// Infinity Matrix - Copyright 2017 Frank Force
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//////////////////////////////////////////////////////////////////////////////////

const float blurSize = 1.0/512.0;
const float blurIntensity = 0.2;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
   vec2 uv = fragCoord.xy/iResolution.xy;
   vec4 sum = vec4(0);
   sum += texture(iChannel0, vec2(uv.x - blurSize, uv.y)) * 0.5;
   sum += texture(iChannel0, vec2(uv.x + blurSize, uv.y)) * 0.5;
   sum += texture(iChannel0, vec2(uv.x, uv.y - blurSize)) * 0.5;
   sum += texture(iChannel0, vec2(uv.x, uv.y + blurSize)) * 0.5;
   sum += texture(iChannel0, vec2(uv.x - blurSize, uv.y - blurSize)) * 0.3;
   sum += texture(iChannel0, vec2(uv.x + blurSize, uv.y - blurSize)) * 0.3;
   sum += texture(iChannel0, vec2(uv.x - blurSize, uv.y + blurSize)) * 0.3;
   sum += texture(iChannel0, vec2(uv.x + blurSize, uv.y + blurSize)) * 0.3;    

   fragColor = blurIntensity*sum + texture(iChannel0, uv);
}

void main (void)
{
  vec4 color = vec4 (0.0, 0.0, 0.0, 1.0);
  mainImage (color, gl_FragCoord.xy);
  color.w = 1.0;
  gl_FragColor = color;
}