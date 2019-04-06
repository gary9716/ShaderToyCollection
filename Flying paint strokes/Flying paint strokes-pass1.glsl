// Shader downloaded from https://www.shadertoy.com/view/MstfWf
// written by shadertoy user CoyHot
//
// Name: Flying paint strokes
// Description: My first experiment with Raymarching / Sphere Tracing. Just to learn this new concept to me :
//    
//    Trying to combine distorsions on a simple sphere (i add some comments to explain what I do).
//    Not optimized and maybe dirty, need a few seconds to "stabilize".

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

// -------------------------------------------------------
// ---------------  Flying paint strokes -----------------
// Francois 'CoyHot' Grassard, May 2018
// My first real attempt with Raymarching / Sphere Tracing
// -------------------------------------------------------



float map(vec3 p)
{
  // Define some temporal and/or spatial references 
  float a =sin(iTime);
  float b = p.z/6.0;
  float c = 0.75+(sin((iTime*p.z)*3.)/12.);
  float d = iTime/5.;

  // --> Reminder : The next steps have to be read from bottom to top <--

  // Rotate the whole scene
  p.xy *= mat2(cos(d), sin(d), -sin(d), cos(d));


  // Add turbulences on each axes, based on Z value
  p.x += cos(b)*7.;
  p.y += sin(b)*7.;
  p.z += sin(b)*7.;


  // Twist the whole scene alond Z axis
  p.xy *= mat2(cos(b), sin(b), -sin(b), cos(b));


  // Scatter strokes in space to avoid all strokes to be aligned
  p = vec3(p.x+cos((p.z)),p.y+sin((p.z)),p.z);
  p = vec3(p.x+cos(p.y),p.y+cos(p.x),p.z);


  // Multiply Strokes
  p = mod(p,16.0)-8.0;


  // Rotate strokes globaly, base on global time. On Z AXIS !!!!
  p.xy *= mat2(cos(cos(a)), sin(cos(a)), -sin(cos(a)), cos(cos(a)));


  // Rotate each stroke, based on there own Z Value and global time
  p.xz *= mat2(cos(c*3.), sin(c*3.), -sin(c*3.), cos(c));


  // Add another sin/cos Noise on the surface, also based on Z value, to add some smaller details on the surface (to mimic the tail of the stroke)
  p.z += (sin(p.x*25.+iTime)/40.);
  p.z += (cos(p.y*25.+iTime)/40.);


  // Rotate the whole shape, based on time
  p.xy *= mat2(cos(a), sin(a), -sin(a), cos(a));


  // Add sin/cos Noise on the surface, based on Z value
  p.z += (sin(p.x*15.+iTime)/5.);
  p.z += (cos(p.y*15.+iTime)/5.);


  // Return the distance, including a final turbulence based on sin(time) and Z
  return length(p) - sin((iTime+p.z)*2.0)-.25;
}



float trace (vec3 o, vec3 d)
{
  float t=0.; // Used as a near clipping value (check it with a value of 20.)
  for(int i = 0; i< 128; i++)
  {
    vec3 p = o+d*t;
    float d = map(p);
    t += d*0.075;
  }
  return t;
}




void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    
	uv -= 0.5;
	uv /= vec2(iResolution.y / iResolution.x, 1);
    
    
	// 2D Displacement based on texture (produced Tweaked UV) : First Texture
	vec4 tex1 = texture(iChannel0, vec2(uv.x,uv.y+iTime/15.));
	uv.x += tex1.r/5.5*uv.x;
	uv.y += tex1.r/5.5*uv.y;
    

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));

	// Camera and ray direction
	vec3 pc = vec3(0.+sin(iTime)*1.0,0.+cos(iTime)*1.0,iTime*50.);
	vec3 ray = normalize(vec3(uv*1.5,1.));

	vec3 pixel = vec3(trace(pc,ray));

	// Add some Color, based on Tweaked UV
	pixel.r += uv.x*25.;
	pixel.g += uv.y*25.;
	pixel.b += uv.x*-25.;


	// Multiply the color by the fog
	vec3 fog = 1.0/(1.0+pixel*pixel/10.0)-0.001;    
    
	// Output to screen
	fragColor = vec4(pixel*fog,1.0);
}

void main ()
{
  vec4 color = vec4 (0.0, 0.0, 0.0, 1.0);
  mainImage (color, gl_FragCoord.xy);
  color.w = 1.0;
  fragColor = color;
}
