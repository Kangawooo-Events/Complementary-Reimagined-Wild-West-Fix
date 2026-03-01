int part = gl_VertexID / 48 % 2;
int face = (gl_VertexID % 48) / 4;
int vertex = gl_VertexID % 4;
bool slim = isSlim();

ivec4 uvData = slim ? slimArmUV[face % 6] : armUV[face % 6];
bool rotate = armRotateUV[face % 6];
bool flip = armFlipUV[face % 6];
bool mirror = armMirrorUV[face % 6];

if (part == 0) {
    if (face >= 6) uvData.xz += 16;
} else {
    uvData += ivec4(8, -32, 8, -32);
    if (face >= 6) uvData.yw += 16;
}

ivec2 uv;
switch (vertex) {
    case 0: uv = uvData.xy; break;
    case 1: uv = rotate ? uvData.xw : uvData.zy; break;
    case 2: uv = uvData.zw; break;
    case 3: uv = rotate ? uvData.zy : uvData.xw; break;
}
if (flip) {
    uv = uvData.xy + uvData.zw - uv;
}
if (mirror) {
    uv.x = uvData.x + uvData.z - uv.x;
}

texCoord1 = vec2(uv) / 64.0;

vec4 pos = gl_ModelViewMatrix * gl_Vertex;
corner0 = corner1 = vec4(0.0);
if (gl_VertexID % 4 == 0) corner0 = pos;
if (gl_VertexID % 4 == 2) corner1 = pos;