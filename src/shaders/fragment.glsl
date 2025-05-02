precision highp float;              //// set default precision of float variables to high precision

varying vec2 vUv;                   //// screen uv coordinates (varying, from vertex shader)
uniform vec2 iResolution;           //// screen resolution (uniform, from CPU)
uniform float iTime;                //// time elapsed (uniform, from CPU)
uniform sampler2D iAudioTexture;
uniform int iAudioHead;
uniform vec2 iAudioDimensions;

const vec3 CAM_POS = vec3(0.0, 1.3, -2.6);
// const vec3 CAM_POS = vec3(0.0, 3.0, -9.0);


const int LOG_FFT_SIZE = 15;
const int FREQ_BUFFER_FRAMES = 5;
const int BUFFER_SIZE = LOG_FFT_SIZE * FREQ_BUFFER_FRAMES;
float dBs[BUFFER_SIZE];
vec3 box_centers[BUFFER_SIZE];
vec3 box_sizes[BUFFER_SIZE];
vec3 box_colors[BUFFER_SIZE];

const float box_size = 0.1;
const float box_spacing = 0.3;
const float x_offset = (float(LOG_FFT_SIZE) * box_spacing) / 2.0;

const vec3 green = vec3(0.0, 1.0, 0.0);
const vec3 yellow = vec3(1.0, 1.0, 0.0);
const vec3 red = vec3(1.0, 0.0, 0.0);


/////////////////////////////////////////////////////
//// audio fft texture lookup
/////////////////////////////////////////////////////

float getAudioFFT(int row, int freqIdx) { 
    return texture2D(iAudioTexture, vec2(
        (float(freqIdx) + 0.5) / float(LOG_FFT_SIZE),
        (float(row) + 0.5) / float(FREQ_BUFFER_FRAMES)
    )).r;
}

float getCurrentAudioVolumedB() {
    float sum = 0.0;
    for (int i = 0; i < LOG_FFT_SIZE; i++) {
        sum += getAudioFFT(0, i);
    }
    return clamp(log2(sum / float(LOG_FFT_SIZE)) * 10.0, -60.0, 0.0); // Convert to decibels
}

void convertAudioFFTToDB() {
    int row = iAudioHead;
    for (int i = 0; i < BUFFER_SIZE; i+=LOG_FFT_SIZE) {
        for (int j = 0; j < LOG_FFT_SIZE; j++) {
            float dB = getAudioFFT(row, j); // Get the FFT value
            dBs[i + j] = dB; // Convert to 0-255 range
            box_sizes[i + j].y = 0.05 + dB * 1.3; // Box size based on FFT value
        }
        row--;
        if (row < 0) {
            row += FREQ_BUFFER_FRAMES;
        }
    }
}

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
vec4 sdf(vec3 p, int get_color)
{
    vec3 dir = p - CAM_POS;
    int j_start = 0;
    int j_end = LOG_FFT_SIZE;
    if (dir.x < 0.0) {
        j_end = int(ceil((p.x + x_offset + box_size) / box_spacing));
    } else {
        j_start = int(floor((p.x + x_offset - box_size) / box_spacing));
    }
    int i_start = max(int(floor((p.z - box_size) / box_spacing)), 0) * LOG_FFT_SIZE;

    if (i_start >= BUFFER_SIZE || j_start >= LOG_FFT_SIZE || j_end < 0 || abs(p.y) > 3.5) {
        return vec4(0.0, 0.0, 0.0, 100.0); // return background color
    }

    float s = 100.0;
    vec3 color = vec3(0.0, 0.0, 0.0);

    for (int i = i_start; i < BUFFER_SIZE; i+=LOG_FFT_SIZE) {
        for (int j = j_start; j < j_end; j++) {
            float dB = dBs[i + j];
            vec3 box_c = box_centers[i + j]; // Box center
            vec3 box_s = box_sizes[i + j]; // Box size
            float box_sdf = sdfBox(p, box_c, box_s); // SDF for the box
            if (box_sdf < 0.001) {
                s = box_sdf;
                if (get_color == 0) {
                    return vec4(0.0, 0.0, 0.0, s); // return sdf value only
                } else {
                    if (dB < 0.5) {
                        color = mix(green, yellow, dB / 0.5); // interpolate between green and yellow
                    } else {
                        color = mix(yellow, red, (dB - 0.5) * 2.0); // interpolate between yellow and red
                    }
                    return vec4(color, s); // return color and sdf value
                }
            } else {
                s = min(s, box_sdf); // keep the minimum sdf value
            }
        }
    }

    return vec4(0.0, 0.0, 0.0, s); // return color and sdf value
}

/////////////////////////////////////////////////////
//// ray marching
/////////////////////////////////////////////////////

//// ray marching: origin - ray origin; dir - ray direction 
float rayMarching(vec3 origin, vec3 dir)
{
    float s = 0.0;
    for(int i = 0; i < 15; i++)
    {
        //// your implementation starts

        vec3 p = origin + s * dir;
        float sdf_p = sdf(p, 0).w;

        if(sdf_p < 0.001 || sdf_p > 10.0){
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

//// normal: p - query point
vec3 normal(vec3 p)
{
    float s = sdf(p, 0).w;          //// sdf value in p
    float dx = 0.01;           //// step size for finite difference

    //// your implementation starts

    float sdf_gradient_x = sdf(p + vec3(dx, 0.0, 0.0), 0).w - sdf(p - vec3(dx, 0.0, 0.0), 0).w;
    float sdf_gradient_y = sdf(p + vec3(0.0, dx, 0.0), 0).w - sdf(p - vec3(0.0, dx, 0.0), 0).w;
    float sdf_gradient_z = sdf(p + vec3(0.0, 0.0, dx), 0).w - sdf(p - vec3(0.0, 0.0, dx), 0).w;

    return normalize(vec3(sdf_gradient_x, sdf_gradient_y, sdf_gradient_z));

    //// your implementation ends
}

/////////////////////////////////////////////////////
//// Phong shading
/////////////////////////////////////////////////////

vec3 phong_shading(vec3 p, vec3 n)
{
    //// background
    if(p.z > 10.0){
        return vec3(0.0, 0.0, 0.0);
    }

    return sdf(p, 1).xyz;

    //// phong shading
    // vec3 lightPos = CAM_POS * 2.0;
    // vec3 l = normalize(lightPos - p);
    // float amb = 0.8;
    // float dif = max(dot(n, l), 0.) * 0.3;
    // vec3 eye = CAM_POS;
    // float spec = pow(max(dot(reflect(-l, n), normalize(eye - p)), 0.0), 128.0) * 0.45;

    // vec3 sunDir = vec3(0, 1, -1);
    // float sunDif = max(dot(n, sunDir), 0.) * 0.2;
    

    vec3 color = vec3(0.0, 0.0, 0.0);

    //// your implementation for coloring starts

    color = sdf(p, 1).xyz;

    //// your implementation for coloring ends
    return color;

    // return (amb + dif + spec + sunDif) * color;
}

/////////////////////////////////////////////////////
//// main function
/////////////////////////////////////////////////////

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord.xy - .5 * iResolution.xy) / iResolution.y;         //// screen uv
    vec3 origin = CAM_POS;                                                  //// camera position
    vec3 center = vec3(0.0, 0.0, 0.0);                                      /// scene center

    vec3 f = normalize(center - origin);                                 //// camera forward direction
    vec3 r = normalize(cross(vec3(0.0, 1.0, 0.0), f));                   //// camera right direction
    vec3 u = cross(f, r);                                                //// camera up direction
    vec3 dir = normalize(uv.x * r + uv.y * u + f);                       //// camera direction

    for (int i = 0; i < FREQ_BUFFER_FRAMES; i++) {
        for (int j = 0; j < LOG_FFT_SIZE; j++) {
            box_centers[i * LOG_FFT_SIZE + j] = vec3(float(j) * box_spacing - x_offset, 0.0, float(i) * box_spacing);
            box_sizes[i * LOG_FFT_SIZE + j] = vec3(box_size, 0.05, box_size);
        }
    }

    convertAudioFFTToDB();

    float s = rayMarching(origin, dir);                                     //// ray marching
    if(s > 10.0) {                                                         //// ray marching failed
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);                              //// background color
        return;
    }
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