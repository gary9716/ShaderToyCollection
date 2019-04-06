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

//Velocity handling

#define time iTime

vec3 hash3(vec3 p)
{
    p = fract(p * vec3(443.8975,397.2973, 491.1871));
    p += dot(p.zxy, p.yxz+19.1);
    return fract(vec3(p.x * p.y, p.z*p.x, p.y*p.z))-0.5;
}

vec3 update(in vec3 vel, vec3 pos, in float id)
{
    vec4 sndNFO = texture(iChannel2, vec2(0.75, 0.25));
    float R = 1.5;
    const float r = .5;
    float t= time*2.+id*8.;
    float d= 5.;
    
    float x = ((R-r)*cos(t-time*0.1) + d*cos((R-r)/r*t));
    float y = ((R-r)*sin(t) - d*sin((R-r)/r*t));
    
    vel = mix(vel, vec3(x*1.2,y,sin(time*12.6+id*50. + sndNFO.z*10.)*7.)*5. +hash3(vel*10.+time*0.2)*7., 1.);
    
    //vel.z += sin(time*sndNFO.z)*50.;
    //vel.z += sin(time + sndNFO.z*70.)*10.;
    //vel.z += sin(time)*30.*sndNFO.x;
    
    return vel;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = q-0.5;
    p.x *= iResolution.x/iResolution.y;
    
    vec2 mo = iMouse.xy/iResolution.xy-0.5;
    
    float dt = iTimeDelta;
    
    vec4 col= vec4(0);
    
    vec2 w = 1./iResolution.xy;
    
    vec3 pos = texture(iChannel0, vec2(q.x,100.*w)).xyz;
    vec3 velo = texture(iChannel0, vec2(q.x,0.0)).xyz;
    velo = update(velo, pos, q.x);
    
    if (fragCoord.y < 30.)
    {
    	col.rgb = velo;
    }
    else
    {
        pos += velo*0.002;
        col.rgb = pos;
    }
	
    if (iFrame < 5) 
    {
        if (fragCoord.y < 30.)
        	col = ((texture(iChannel1, q*1.9))-.5)*vec4(0.,0.,0.,0.);
        else
        {
            col = vec4(.0,-.7,0,0);
        }
    }
    
    
    if (mod(float(iFrame), 300.) == 0. && fragCoord.y > 30.)
    {
        col = vec4(.0,-.2, -0.,0);
    }
    
    col.a = q.x;
    
	fragColor = col;
}

void main (void)
{
  vec4 color = vec4 (0.0, 0.0, 0.0, 1.0);
  mainImage (color, gl_FragCoord.xy);
  color.w = 1.0;
  gl_FragColor = color;
}
