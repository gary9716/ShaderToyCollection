// Shader downloaded from https://www.shadertoy.com/view/XlSGzD
// written by shadertoy user mpcomplete
//
// Name: Acid Kaleidoscope
// Description: Playing with transitions between transformations.
//    
//    Mixing ideas from
//    - https://www.shadertoy.com/view/XlXGW2 and
//    - https://www.shadertoy.com/view/XlfGDf

uniform vec3      iResolution;           // viewport resolution (in pixels)
uniform float     iGlobalTime;           // shader playback time (in seconds)
uniform float     iChannelTime[4];       // channel playback time (in seconds)
uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
uniform sampler2D iChannel0;             // input channel. XX = 2D/Cube
uniform sampler2D iChannel1;             // input channel. XX = 2D/Cube
uniform vec4      iDate;                 // (year, month, day, time in secs)
uniform float     iSampleRate;           // sound sample rate (i.e., 44100)

//#define DEBUG 1

#define time (iTime*.3)

float _evaluateCubic(float a, float b, float m) {
	return 3. * a * (1. - m) * (1. - m) * m +
           3. * b * (1. - m) *            m * m +
                                          m * m * m;
}

float _kCubicErrorBound = 0.001;
float _transformCubic(float t, float a, float b, float c, float d) {
    float start = 0.0;
    float end = 1.0;
    while (true) {
        float midpoint = (start + end) / 2.;
        float estimate = _evaluateCubic(a, c, midpoint);
        if (abs(t - estimate) < _kCubicErrorBound)
            return _evaluateCubic(b, d, midpoint);
        if (estimate < t)
            start = midpoint;
        else
            end = midpoint;
    }
}


// A cubic animation curve that starts slowly and ends quickly.
float easeIn(float t) {
    return _transformCubic(t, 0.42, 0.0, 1.0, 1.0);
}

// A cubic animation curve that starts slowly, speeds up, and then and ends slowly.
float easeInOut(float t) {
    return _transformCubic(t, 0.42, 0.0, 0.58, 1.0);
}

// A curve that starts quickly and eases into its final position.
float fastOutSlowIn(float t) {
    return _transformCubic(t, 0.4, 0.0, 0.2, 1.0);
}

// 2D rotation matrix.
mat2 rotate(float angle)
{
    return mat2(
        vec2( cos(angle), sin(angle)),
        vec2(-sin(angle), cos(angle)));
}

// Transform a point on square to a circle.
vec2 mapSquare(in vec2 p)
{
    vec2 ap = abs(p);
    float r = max(ap.x, ap.y);
    float angle = atan(p.y, p.x);

    return r*vec2(cos(angle), sin(angle));
}

// Make a pattern of squares in a repeating grid.
vec2 dupSquares(in vec2 p)
{
    vec2 ap = abs(sin(p*3.));
    float r = max(ap.x, ap.y);
    float angle = atan(p.y, p.x);

    return r*vec2(cos(angle), sin(angle));
}

// Duplicate pattern in dupSquaresConcentric squares.
vec2 dupSquaresConcentric(in vec2 p)
{
    vec2 ap = abs(p);
    float r = max(ap.x, ap.y);
    float angle = atan(p.y, p.x);

    return sin(3.*r)*vec2(cos(angle), sin(angle));
}

// Duplicate pattern in a repeating grid.
vec2 dupGrid(in vec2 p)
{
    return abs(sin(p*4.));
}

float numPhases = 4.;
vec2 getTransform(in vec2 p, float t)
{
    int which = int(mod(t, numPhases));

    if (which == 0) {
        p = rotate(time*.3)*p*.7;
        p = dupSquares(p);
    } else if (which == 1) {
        p = dupSquares(p);
        p = rotate(time*.2)*p;
        p = dupSquares(p);
    } else if (which == 2) {
        p = dupSquares(p);
        p = rotate(time*.3)*p;
        p = dupSquaresConcentric(p);
    } else {
        p = dupSquaresConcentric(p*1.5);
    }
    return p;
}

vec2 applyTransform(in vec2 p)
{
    float t = time*.35;
#ifdef DEBUG
    if (iMouse.z > .001) t = iMouse.x/iResolution.x * numPhases;
#endif
    float pct = smoothstep(0., 1., mod(t, 1.));
    pct = fastOutSlowIn(pct);
    return mix(getTransform(p, t), getTransform(p, t+1.), pct);
}


mat3 rotation(float angle, vec3 axis)
{
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return mat3(oc * a.x * a.x + c,        oc * a.x * a.y - a.z * s,  oc * a.z * a.x + a.y * s,
                oc * a.x * a.y + a.z * s,  oc * a.y * a.y + c,        oc * a.y * a.z - a.x * s,
                oc * a.z * a.x - a.y * s,  oc * a.y * a.z + a.x * s,  oc * a.z * a.z + c);
}

vec4 gradient(float f)
{
    vec3 col1 = 0.5 + 0.5*sin(f*0.908 + vec3(0.941,1.000,0.271));
	vec3 col2 = 0.5 + 0.5*sin(f*7.240 + vec3(0.611,0.556,1.000));
	vec3 c = 1.888*pow(col1*col2, vec3(0.800,0.732,0.660));

    vec3 axis = vec3(0.454,0.725,1.072);
    c = rotation(2.0*length(axis)*sin(time), axis)*c;
    
    return vec4(c, 1.0);
}

float offset(float th)
{
    return .2*sin(25.*th)*sin(time);
}

vec4 tunnel(float th, float radius)
{
	return gradient(offset(th) + 2.*log(radius) - time);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = -1.0 + 2.0 * fragCoord.xy / iResolution.xy;
    p.x *= iResolution.x/iResolution.y;
    p *= 2.0;

    p = applyTransform(p);

	fragColor = tunnel(atan(p.y, p.x), 2.0 * length(p));
}

void main (void)
{
  vec4 color = vec4 (0.0, 0.0, 0.0, 1.0);
  mainImage (color, gl_FragCoord.xy);
  color.w = 1.0;
  gl_FragColor = color;
}
