// Shader downloaded from https://www.shadertoy.com/view/MtdXz7
// written by shadertoy user Ark
//
// Name: Sphere to Plane Transition
// Description: A transition by a homeomorphism between the sphere in R^3 with a single point removed and the set of all points in R^2.
//    「球面上から一点を取り除いた集合」と「平面上の点全体」の間の同相写像による遷移

uniform vec3      iResolution;           // viewport resolution (in pixels)
uniform float     iGlobalTime;           // shader playback time (in seconds)
uniform float     iChannelTime[4];       // channel playback time (in seconds)
uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
uniform sampler2D iChannel0;             // input channel. XX = 2D/Cube
uniform sampler2D iChannel1;             // input channel. XX = 2D/Cube
uniform vec4      iDate;                 // (year, month, day, time in secs)
uniform float     iSampleRate;           // sound sample rate (i.e., 44100)

#define INF 1e10
#define EPS 1e-2
#define PI 3.14159265359

struct Camera{
    vec3 pos;
    vec3 dir;
    vec3 up;
    vec3 side;
    float focus;
} camera;

struct Ray {
    vec3 dir;
} ray;

struct Light{
    vec3 pos;
} light;

struct Intersection{
    vec3 pos;
    vec3 diffuseColor;
    vec3 specularColor;
    vec3 ambientColor;
    float specularPower;
} intersection;

void setPhong() {
    intersection.diffuseColor = vec3(0.2, 0.4, 0.7);
    intersection.specularColor = vec3(1.0, 1.0, 1.0) * 0.9;
    intersection.ambientColor = vec3(0.0, 0.02, 0.10);
    intersection.specularPower = 20.0;
}

vec3 convert(float r, float theta, float phi, float a) {
    float x = r*sin(theta)*cos(phi);
    float y = r*sin(theta)*sin(phi);
    float z = r*cos(theta);
    
    float h = -1.0;
    float t = (z-r)/(h-r);
    float _x = x/t;
    float _y = y/t;
    
    vec3 v1 = vec3(x, y, z);
    vec3 v2 = vec3(_x, _y, h);
    
    //return mix(v1, v2, a);
    return clamp(mix(v1, v2, a), -vec3(INF), vec3(INF));
}

void init(vec2 pos) {
    float phi = PI*iTime/6.0;
    float theta = mix(EPS, PI-EPS, sin(PI*iTime/13.0)*0.5+0.5);
    camera.pos = convert(3.0, theta, phi, 0.0);
    //camera.pos = vec3(3.0, 0.0, 2.0);
    camera.dir = normalize(-camera.pos);
    camera.side = normalize(cross(camera.dir, vec3(0.0, 0.0, 1.0)));
    camera.up = normalize(cross(camera.side, camera.dir));
    camera.focus = 1.8;
    light.pos = vec3(15.0, 20.0, 5.0);
    ray.dir = normalize(camera.side*pos.x + camera.up*pos.y + camera.dir*camera.focus);
    setPhong();
}

float capsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p-a;
    vec3 ba = b-a;
    float h = clamp(dot(pa, ba)/dot(ba, ba), 0.0, 1.0);
    return max(0.0, length(pa - ba*h) - r);
}

float torus(vec3 p, float r1, float r2) {
    vec2 q = vec2(length(p.xy)-r1, p.z);
    return abs(length(q)-r2);
}

float getT() {
    return pow(sin(iTime/3.0), 4.0);
}

float dist(vec3 pos) {
    float res = INF;
    
    const float r = 1.0;
    
///*
    const int N = 36;
    const float weight = 0.02;
    
    for(int i=0; i<N; i++) {
        float theta = mix(0.1, PI, float(i)/float(N));
        vec3 v = convert(r, theta, 0.0, getT());
        float d = torus(pos-vec3(0.0, 0.0, v.z), length(v.xy), weight);
        res = min(res, d);
    }
//*/    
/*
    const int num1 = 8;
    const int num2 = 12;
    const float weight = 0.05;
    for (int i=0; i<num1; i++) {
        for (int j=0; j<num2; j++) {
            float phi1 = mix(0.0, 2.0*PI, float(i)/float(num1));
            float phi2 = mix(0.0, 2.0*PI, float(i+1)/float(num1));
            float theta1 = mix(0.1, PI, float(j)/float(num2));
            float theta2 = mix(0.1, PI, float(j+1)/float(num2));
            vec3 v1 = convert(r, theta1, phi1, getT());
            vec3 v2 = convert(r, theta1, phi2, getT());
            vec3 v3 = convert(r, theta2, phi1, getT());
            float d1 = capsule(pos, v1, v2, weight);
            float d2 = capsule(pos, v1, v3, weight);
            res = min(res, min(d1, d2));
        }
    }
*/
    
    return res;
}

vec3 getNormal(vec3 p) {
    return normalize(vec3(
        dist(p+vec3(EPS,0,0)) - dist(p),
        dist(p+vec3(0,EPS,0)) - dist(p),
        dist(p+vec3(0,0,EPS)) - dist(p)
    ));
}

vec3 calc() {
    
    float t = 0.0, d;
    intersection.pos = camera.pos;
    const int N = 24;
    for(int i=0; i<N; i++) {
        d = dist(intersection.pos);
        if (abs(d) < EPS) break;
        t += d*0.9+EPS;
        intersection.pos = camera.pos + t*ray.dir;   
    }
    
    vec3 n = getNormal(intersection.pos);
    vec3 lightDir = - normalize(intersection.pos - light.pos);
    vec3 eyeDir = - normalize(intersection.pos - camera.pos);
    float diffuse = clamp(dot(n, lightDir), 0.0, 1.0);
    float specular = pow(clamp(dot(n, normalize(lightDir+eyeDir)), 0.0, 1.0), intersection.specularPower);
    float ambient = 1.0;

    if (abs(d) < EPS) {
        return vec3(diffuse * intersection.diffuseColor + specular * intersection.specularColor + ambient * intersection.ambientColor);
    } else {
        return vec3(0.1);
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 uv = (2.0*fragCoord.xy - iResolution.xy) / min(iResolution.x, iResolution.y);
    init(uv);
    
    vec3 col = calc();
	fragColor = vec4(col,1.0);
}

void main (void)
{
  vec4 color = vec4 (0.0, 0.0, 0.0, 1.0);
  mainImage (color, gl_FragCoord.xy);
  color.w = 1.0;
  gl_FragColor = color;
}
