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

const float zoomSpeed			= 2.0;	// how fast to zoom (negative to zoom out)
const float zoomScale			= 0.1;	// how much to multiply overall zoom (closer to zero zooms in)
const int recursionCount		= 5;	// how deep to recurse
const float recursionFadeDepth	= 3.0;	// how deep to fade out
const int glyphSize				= 5;	// width & height of glyph in pixels
const int glyphCount			= 2;	// how many glyphs total
const float glyphMargin			= 0.5;	// how much to center the glyph in each pixel
const int glyphs[glyphSize*glyphCount] = int[]
(	// glyph sheet
	0x01110, 0x01110, 
	0x11011, 0x11110,
	0x11011, 0x01110, 
	0x11011, 0x01110,
	0x01110, 0x11111
);	//  0        1

//////////////////////////////////////////////////////////////////////////////////
// Precached values and math

const float glyphSizeF = float(glyphSize) + 2.0*glyphMargin;
const float glyphSizeLog = log(glyphSizeF);
const int powTableCount = 10;
const float gsfi = 1.0 / glyphSizeF;
const float powTable[powTableCount] = float[]( 1.0, gsfi, pow(gsfi,2.0), pow(gsfi,3.0), pow(gsfi,4.0), pow(gsfi,5.0), pow(gsfi,6.0), pow(gsfi,7.0), pow(gsfi,8.0), pow(gsfi,9.0));
const float e = 2.718281828459;
const float pi = 3.14159265359;

float RandFloat(int i) { return (fract(sin(float(i)) * 43758.5453)); }
int RandInt(int i) { return int(100000.0*RandFloat(i)); }

vec3 HsvToRgb(vec3 c) 
{
    float s = c.y * c.z;
    float s_n = c.z - s * .5;
    return vec3(s_n) + vec3(s) * cos(2.0 * pi * (c.x + vec3(1.0, 0.6666, .3333)));
}

//////////////////////////////////////////////////////////////////////////////////
// Color and image manipulation

float GetRecursionFade(int r, float timePercent)
{
    if (r > recursionCount)
        return timePercent;
    
    // fade in and out recusion
    float rt = max(float(r) - timePercent - recursionFadeDepth, 0.0);
    float rc = float(recursionCount) - recursionFadeDepth;
    return rt / rc;
}

vec3 InitPixelColor() { return vec3(0); }
vec3 CombinePixelColor(vec3 color, float timePercent, int i, int r, vec2 pos, ivec2 glyphPos, ivec2 glyphPosLast)
{
    vec3 myColor = vec3(0.6);
        
    myColor.r *= mix(0.0, 0.7, RandFloat(i + r + 11*glyphPosLast.x + 13*glyphPosLast.y));
    myColor.b *= mix(0.0, 0.7, RandFloat(i + r + 17*glyphPosLast.x + 19*glyphPosLast.y));
    myColor *= mix(0.3, 1.0, RandFloat(i + r + 31*glyphPosLast.x + 37*glyphPosLast.y));

    // combine with my color
    float f = GetRecursionFade(r, timePercent);
    color += myColor*f;
    return color;
}

vec3 FinishPixel(vec3 color, vec2 uv)
{
    // brighten
    color += vec3(0.07);
    
    // noise
	vec3 noise = vec3(1.0);	
    noise += mix( -0.2, 0.4, texture(iChannel0, 0.00111*uv*iResolution.y + vec2(-23.3*iTime, 37.5*iTime)).x);
    noise += mix( -0.2, 0.4, texture(iChannel0, 0.00182*uv*iResolution.y + vec2(13.1*iTime, -20.1*iTime)).x);
	color *= noise;
    
    // make green
    color *= vec3(0.8, 1.0, 0.8);
    return color;
}

vec2 InitUV(vec2 uv)
{
	// wave
	uv.x += 0.1*sin(2.0*uv.y + 1.0*iTime);
	uv.y += 0.1*sin(2.0*uv.x + 0.8*iTime);
    return uv;
}


//////////////////////////////////////////////////////////////////////////////////
// Fractal functions

int GetFocusGlyph(int i) { return RandInt(i) % glyphCount; }
int GetGlyphPixelRow(int y, int g) { return glyphs[g + (glyphSize - 1 - y)*glyphCount]; }
int GetGlyphPixel(ivec2 pos, int g)
{
	if (pos.x >= glyphSize || pos.y >= glyphSize)
		return 0;

    // pull glyph out of hex
	int glyphRow = GetGlyphPixelRow(pos.y, g);
    return 1 & (glyphRow >> (glyphSize - 1 - pos.x) * 4);
}

ivec2 focusList[max(powTableCount, recursionCount) + 2];
ivec2 GetFocusPos(int i) { return focusList[i+2]; }

ivec2 CalculateFocusPos(int iterations)
{
    // count valid pixels in glyph
    int g = GetFocusGlyph(iterations-1);
    int c = 18;	// OPT - 1 and 0 glyps both have 18 pixels
    /*int c = 0;
    for (int y = glyphCount*(glyphSize - 1); y >= 0; y -= glyphCount)
    {
		int glyphRow = glyphs[g + y];
        for (int x = 0; x < glyphSize; ++x)
            c += (1 & (glyphRow >> 4*x));
    }*/

    // find a random valid pixel in glyph
    c -= RandInt(iterations) % c;
    for (int y = glyphCount*(glyphSize - 1); y >= 0; y -= glyphCount)
    {
		int glyphRow = glyphs[g + y];
        for (int x = 0; x < glyphSize; ++x)
        {
            c -= (1 & (glyphRow >> 4*x));
            if (c == 0)
                return ivec2(glyphSize - 1 - x, glyphSize - 1 - y/glyphCount);
        }
    }
}
  
int GetGlyph(int iterations, ivec2 glyphPos, int glyphLast, ivec2 glyphPosLast, ivec2 focusPos)
{ 
    if (glyphPos == focusPos)
        return GetFocusGlyph(iterations); // inject correct glyph     
            
    int seed = iterations + glyphPos.x * 313 + glyphPos.y * 411 + glyphPosLast.x * 557 + glyphPosLast.y * 121;
    return RandInt(seed) % glyphCount; 
}
      
// get color of pos, where pos is 0-1 point in the glyph
vec3 GetPixelFractal(vec2 pos, int iterations, float timePercent)
{
    int glyphLast = GetFocusGlyph(iterations-1);
	ivec2 glyphPosLast = GetFocusPos(-2);
	ivec2 glyphPos =     GetFocusPos(-1);
    
	bool isFocus = true;
    ivec2 focusPos = glyphPos;
    
	vec3 color = InitPixelColor();
	for (int r = 0; r <= recursionCount + 1; ++r)
	{
        color = CombinePixelColor(color, timePercent, iterations, r, pos, glyphPos, glyphPosLast);
        
        //if (r == 1 && glyphPos == GetFocusPos(r-1))
	    //    color.z = 1.0; // debug - show focus
        
        if (r > recursionCount)
			return color;
           
        // update pos
        pos -= vec2(glyphMargin*gsfi);
        pos *= glyphSizeF;

        // get glyph and pos within that glyph
        glyphPosLast = glyphPos;
        glyphPos = ivec2(pos);

        // check pixel
        int glyphValue = GetGlyphPixel(glyphPos, glyphLast);
		if (glyphValue == 0 || pos.x < 0.0 || pos.y < 0.0)
			return color;
        
        // next glyph
		pos -= vec2(floor(pos));
        focusPos = isFocus? GetFocusPos(r) : ivec2(-10);
        glyphLast = GetGlyph(iterations + r, glyphPos, glyphLast, glyphPosLast, focusPos);
        isFocus = isFocus && (glyphPos == focusPos);
	}
}
 
//////////////////////////////////////////////////////////////////////////////////
	
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	// use square aspect ratio
	vec2 uv = fragCoord;
	uv = fragCoord / iResolution.y;
	uv -= vec2(0.5*iResolution.x / iResolution.y, 0.5);
    uv = InitUV(uv);
	
	// get time 
	float timePercent = iTime*zoomSpeed;
	int iterations = int(floor(timePercent));
	timePercent -= float(iterations);
	
	// update zoom, apply pow to make rate constant
	float zoom = pow(e, -glyphSizeLog*timePercent);
	zoom *= zoomScale;
    
    // cache focus positions
    for(int i = 0; i  < powTableCount + 2; ++i)
      focusList[i] = CalculateFocusPos(iterations+i-2);
    
	// get offset
	vec2 offset = vec2(0);
	for (int i = 0; i < powTableCount; ++i)
		offset += ((vec2(GetFocusPos(i)) + vec2(glyphMargin)) * gsfi) * powTable[i];
    
	// apply zoom & offset
    vec2 uvFractal = uv * zoom + offset;
	
	// check pixel recursion depth
	vec3 pixelFractalColor = GetPixelFractal(uvFractal, iterations, timePercent);
    pixelFractalColor = FinishPixel(pixelFractalColor, uv);
    
	// apply final color
	fragColor = vec4(pixelFractalColor, 1.0);
}

void main (void)
{
  vec4 color = vec4 (0.0, 0.0, 0.0, 1.0);
  mainImage (color, gl_FragCoord.xy);
  color.w = 1.0;
  gl_FragColor = color;
}