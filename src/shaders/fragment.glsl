/////////////////////////////////////////////////////
//// CS 8803/4803 CGAI: Computer Graphics in AI Era
//// Assignment 1A: SDF and Ray Marching
/////////////////////////////////////////////////////

precision highp float;              //// set default precision of float variables to high precision

varying vec2 vUv;                   //// screen uv coordinates (varying, from vertex shader)
uniform vec2 iResolution;           //// screen resolution (uniform, from CPU)
uniform float iTime;                //// time elapsed (uniform, from CPU)

const vec3 CAM_POS = vec3(-0.35, 1.0, -3.0);

/////////////////////////////////////////////////////
//// sdf functions
/////////////////////////////////////////////////////

//// sphere: p - query point; c - sphere center; r - sphere radius
float sdfSphere(vec3 p, vec3 c, float r)
{
    return length(p - c) - r;
}

//// plane: p - query point; h - height
float sdfPlane(vec3 p, float h)
{
    vec3 n = vec3(0.0, 1.0, 0.0);
    return dot(p, n) + h;
}

//// box: p - query point; c - box center; b - box half size (i.e., the box size is (2*b.x, 2*b.y, 2*b.z))
float sdfBox(vec3 p, vec3 c, vec3 b)
{
    vec3 q = abs(p - c) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float simplex_noise(vec2 p) {
    // Simplex noise implementation or use an existing noise function
    return sin(p.x + p.y); // Placeholder for demonstration purposes
}



/////////////////////////////////////////////////////
//// boolean operations
/////////////////////////////////////////////////////

float sdfIntersection(float s1, float s2)
{
    return max(s1, s2);
}

float sdfUnion(float s1, float s2)
{
    return min(s1, s2);
}

float sdfSubtraction(float s1, float s2)
{
    return max(s1, -s2);
}

/////////////////////////////////////////////////////
//// sdf calculation
/////////////////////////////////////////////////////

//// sdf: p - query point
//// returns vec4: sdf value (float) and color (vec3)
vec4 sdf(vec3 p)
{
    float s = 0.;

    //// 1st object: plane
    float plane1_h = 0.0;
    
    //// 2nd object: sphere
    vec3 sphere1_c = vec3(-2.0, 1.0, 0.0);
    float sphere1_r = 0.25;

    //// 3rd object: box
    vec3 box1_c = vec3(-1.0, 1.0, 0.0);
    vec3 box1_b = vec3(0.2, 0.2, 0.2);

    //// 4th object: box-sphere subtraction
    vec3 box2_c = vec3(0.0, 1.0, 0.0);
    vec3 box2_b = vec3(0.3, 0.3, 0.3);

    vec3 sphere2_c = vec3(0.0, 1.0, 0.0);
    float sphere2_r = 0.4;

    //// 5th object: sphere-sphere intersection
    vec3 sphere3_c = vec3(1.0, 1.0, 0.0);
    float sphere3_r = 0.4;

    vec3 sphere4_c = vec3(1.3, 1.0, 0.0);
    float sphere4_r = 0.3;

    //// calculate the sdf based on all objects in the scene
    
    float plane1_sdf = sdfPlane(p, plane1_h);
    float sphere1_sdf = sdfSphere(p, sphere1_c, sphere1_r);
    float box1_sdf = sdfBox(p, box1_c, box1_b);
    float box2_sdf = sdfBox(p, box2_c, box2_b);
    float sphere2_sdf = sdfSphere(p, sphere2_c, sphere2_r);
    float sphere3_sdf = sdfSphere(p, sphere3_c, sphere3_r);
    float sphere4_sdf = sdfSphere(p, sphere4_c, sphere4_r);

    // plane and sphere
    s = sdfUnion(plane1_sdf, sphere1_sdf);

    // box
    s = sdfUnion(s, box1_sdf);

    // box-sphere subtraction
    float box_sphere_subtraction = sdfSubtraction(box2_sdf, sphere2_sdf);
    s = sdfUnion(s, box_sphere_subtraction);

    // sphere-sphere intersection
    float sphere_sphere_intersection = sdfIntersection(sphere3_sdf, sphere4_sdf);
    s = sdfUnion(s, sphere_sphere_intersection);

    vec3 color = vec3(0.7, 0.7, 0.0); // default color
    if(sphere1_sdf == s){
        color =  vec3(1.0, 0.0, 0.0);
    }
    else if(box1_sdf == s){
        color =  vec3(0.0, 1.0, 0.0);
    }
    else if(box_sphere_subtraction == s){
        color =  vec3(0.0, 0.0, 1.0);
    }
    else if(sphere_sphere_intersection == s){
        color =  vec3(1.0, 1.0, 0.2);
    }
    return vec4(color, s); // return color and sdf value
}

/////////////////////////////////////////////////////
//// ray marching
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 4: ray marching
//// You are asked to implement the ray marching algorithm within the following for-loop.
/////////////////////////////////////////////////////

//// ray marching: origin - ray origin; dir - ray direction 
float rayMarching(vec3 origin, vec3 dir)
{
    float s = 0.0;
    for(int i = 0; i < 100; i++)
    {
        //// your implementation starts

        vec3 p = origin + s * dir;
        float sdf_p = sdf(p).w;

        if(sdf_p < 0.001){
            break;
        }

        s += sdf_p;

        //// your implementation ends
    }
    
    return s;
}

/////////////////////////////////////////////////////
//// normal calculation
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 5: normal calculation
//// You are asked to calculate the sdf normal based on finite difference.
/////////////////////////////////////////////////////

//// normal: p - query point
vec3 normal(vec3 p)
{
    float s = sdf(p).w;          //// sdf value in p
    float dx = 0.01;           //// step size for finite difference

    //// your implementation starts

    float sdf_gradient_x = sdf(p + vec3(dx, 0.0, 0.0)).w - sdf(p - vec3(dx, 0.0, 0.0)).w;
    float sdf_gradient_y = sdf(p + vec3(0.0, dx, 0.0)).w - sdf(p - vec3(0.0, dx, 0.0)).w;
    float sdf_gradient_z = sdf(p + vec3(0.0, 0.0, dx)).w - sdf(p - vec3(0.0, 0.0, dx)).w;

    return normalize(vec3(sdf_gradient_x, sdf_gradient_y, sdf_gradient_z));

    //// your implementation ends
}

/////////////////////////////////////////////////////
//// Phong shading
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 6: lighting and coloring
//// You are asked to specify the color for each object in the scene.
//// Each object must have a separate color without mixing.
//// Notice that we have implemented the default Phong shading model for you.
/////////////////////////////////////////////////////

vec3 phong_shading(vec3 p, vec3 n)
{
    //// background
    if(p.z > 10.0){
        return vec3(0.9, 0.6, 0.2);
    }

    //// phong shading
    vec3 lightPos = vec3(4.*sin(iTime), 4., 4.*cos(iTime));  
    vec3 l = normalize(lightPos - p);               
    float amb = 0.1;
    float dif = max(dot(n, l), 0.) * 0.7;
    vec3 eye = CAM_POS;
    float spec = pow(max(dot(reflect(-l, n), normalize(eye - p)), 0.0), 128.0) * 0.9;

    vec3 sunDir = vec3(0, 1, -1);
    float sunDif = max(dot(n, sunDir), 0.) * 0.2;

    //// shadow
    float s = rayMarching(p + n * 0.02, l);
    if(s < length(lightPos - p)) dif *= .2;

    vec3 color = vec3(1.0, 1.0, 1.0);

    //// your implementation for coloring starts

    color = sdf(p).xyz;

    //// your implementation for coloring ends

    return (amb + dif + spec + sunDif) * color;
}

/////////////////////////////////////////////////////
//// Step 7: creative expression
//// You will create your customized sdf scene with new primitives and CSG operations in the sdf2 function.
//// Call sdf2 in your ray marching function to render your customized scene.
/////////////////////////////////////////////////////

float sdCone( vec3 p, vec2 c, float h, vec3 center)
{
  p -= center;

  // c is the sin/cos of the angle, h is height
  // Alternatively pass q instead of (c,h),
  // which is the point at the base in 2D
  vec2 q = h*vec2(c.x/c.y,-1.0);
    
  vec2 w = vec2( length(p.xz), p.y );
  vec2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
  vec2 b = w - q*vec2( clamp( w.x/q.x, 0.0, 1.0 ), 1.0 );
  float k = sign( q.y );
  float d = min(dot( a, a ),dot(b, b));
  float s = max( k*(w.x*q.y-w.y*q.x),k*(w.y-q.y)  );
  return sqrt(d)*sign(s);
}

/////////////////////////////////////////////////////
//// main function
/////////////////////////////////////////////////////

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord.xy - .5 * iResolution.xy) / iResolution.y;         //// screen uv
    vec3 origin = CAM_POS;                                                  //// camera position 
    vec3 dir = normalize(vec3(uv.x, uv.y, 1));                              //// camera direction
    float s = rayMarching(origin, dir);                                     //// ray marching
    vec3 p = origin + dir * s;                                              //// ray-sdf intersection
    vec3 n = normal(p);                                                     //// sdf normal
    vec3 color = phong_shading(p, n);                                       //// phong shading
    fragColor = vec4(color, 1.);                                            //// fragment color
}

void main() 
{
    mainImage(gl_FragColor, gl_FragCoord.xy);
    //mainImage2(gl_FragColor, gl_FragCoord.xy);  // CREATIVE EXPRESSION PIECE
}