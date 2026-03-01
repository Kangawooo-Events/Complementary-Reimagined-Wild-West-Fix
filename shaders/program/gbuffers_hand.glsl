/////////////////////////////////////
// Complementary Shaders by EminGT //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

in vec2 texCoord;
in vec2 lmCoord;

flat in vec3 upVec, sunVec, northVec, eastVec;
in vec3 normal;

in vec4 glColor;

in vec4 corner0;
in vec4 corner1;
in vec2 texCoord0;
in vec2 texCoord1;

const vec3 HAND_MODEL_SCALE = vec3(0.471, 0.515, 1.515);

const vec3 modelScaleF = 0.5 * HAND_MODEL_SCALE;
const vec3 modelScaleS = modelScaleF + (0.25 / 8.0) * HAND_MODEL_SCALE;
const vec3 hRefF = vec3(length(modelScaleF.xz), length(modelScaleF.yz), length(modelScaleF.xy));
const vec3 hRefS = vec3(length(modelScaleS.xz), length(modelScaleS.yz), length(modelScaleS.xy));

bool testDim(float h, float hRef) {
    return abs(h - hRef) < 0.001;
}
bool testDims(float h, vec3 hRef) {
    return testDim(h, hRef.x) || testDim(h, hRef.y) || testDim(h, hRef.z);
}

#if defined GENERATED_NORMALS || defined COATED_TEXTURES || defined POM || defined IPBR && defined IS_IRIS
    in vec2 signMidCoordPos;
    flat in vec2 absMidCoordPos;
    flat in vec2 midCoord;
#endif

#if defined GENERATED_NORMALS || defined CUSTOM_PBR
    flat in vec3 binormal, tangent;
#endif

#ifdef POM
    in vec3 viewVector;

    in vec4 vTexCoordAM;
#endif

//Pipeline Constants//

//Common Variables//
float NdotU = dot(normal, vec3(0.0, 1.0, 0.0)); // NdotU is different here to improve held map visibility
float NdotUmax0 = max(NdotU, 0.0);
float SdotU = dot(sunVec, upVec);
float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;
float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;
float sunVisibility2 = sunVisibility * sunVisibility;
float shadowTimeVar1 = abs(sunVisibility - 0.5) * 2.0;
float shadowTimeVar2 = shadowTimeVar1 * shadowTimeVar1;
float shadowTime = shadowTimeVar2 * shadowTimeVar2;

#ifdef OVERWORLD
    vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
    vec3 lightVec = sunVec;
#endif

#if defined GENERATED_NORMALS || defined CUSTOM_PBR
    mat3 tbnMatrix = mat3(
        tangent.x, binormal.x, normal.x,
        tangent.y, binormal.y, normal.y,
        tangent.z, binormal.z, normal.z
    );
#endif

//Common Functions//

//Includes//
#include "/lib/util/spaceConversion.glsl"
#include "/lib/lighting/mainLighting.glsl"

#if defined GENERATED_NORMALS || defined COATED_TEXTURES
    #include "/lib/util/miplevel.glsl"
#endif

#ifdef GENERATED_NORMALS
    #include "/lib/materials/materialMethods/generatedNormals.glsl"
#endif

#ifdef COATED_TEXTURES
    #include "/lib/materials/materialMethods/coatedTextures.glsl"
#endif

#if IPBR_EMISSIVE_MODE != 1
    #include "/lib/materials/materialMethods/customEmission.glsl"
#endif

#ifdef CUSTOM_PBR
    #include "/lib/materials/materialHandling/customMaterials.glsl"
#endif

#ifdef COLOR_CODED_PROGRAMS
    #include "/lib/misc/colorCodedPrograms.glsl"
#endif

//Program//
void main() {
    vec4 color = texture2D(tex, texCoord);

    vec2 finalTexCoord = texCoord;
    vec4 texColor = texture2D(tex, texCoord);
    ivec2 size = textureSize(tex, 0);
    vec3 diff = corner1.xyz / corner1.w - corner0.xyz / corner0.w;
    float h = length(diff);

    
    if (size.x == 64 && size.y == 64) 
    {
        if (abs(h - hRefF.x) < 0.0001 || abs(h - hRefF.y) < 0.0001 || abs(h - hRefF.z) < 0.0001 || abs(h - hRefS.x) < 0.0001 || abs(h - hRefS.y) < 0.0001 || abs(h - hRefS.z) < 0.0001) 
        {
            finalTexCoord = texCoord1;
        }
    }
    
    color = texture2D(tex, finalTexCoord);

    float smoothnessD = 0.0, materialMask = OSIEBCA * 254.0; // No SSAO, No TAA, Reduce Reflection
    vec2 lmCoordM = lmCoord;
    vec3 normalM = normal, shadowMult = vec3(0.5); // Reduced shadowMult for held items to not get too bright

    float alphaCheck = color.a;
    #ifdef DO_PIXELATION_EFFECTS
        // Fixes artifacts on fragment edges with non-nvidia gpus
        alphaCheck = max(fwidth(color.a), alphaCheck);
    #endif

    if (alphaCheck > 0.001) {
        #ifdef GENERATED_NORMALS
            vec3 colorP = color.rgb;
        #endif
        color *= glColor;

        vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z + 0.38);
        vec3 viewPos = ScreenToView(screenPos);
        vec3 playerPos = ViewToPlayer(viewPos);

        if (color.a < 0.75) materialMask = 0.0;

        bool noSmoothLighting = true, noGeneratedNormals = false, noDirectionalShading = false, noVanillaAO = false;
        float smoothnessG = 0.0, highlightMult = 1.0, emission = 0.0, noiseFactor = 0.6;
        vec3 geoNormal = normalM;
        vec3 worldGeoNormal = normalize(ViewToPlayer(geoNormal * 10000.0));
        vec3 maRecolor = vec3(0.0);
        #ifdef IPBR
            #if defined IS_IRIS || defined IS_ANGELICA && ANGELICA_VERSION >= 20000008
                #include "/lib/materials/materialHandling/irisIPBR.glsl"

                if (materialMask != OSIEBCA * 254.0) materialMask += OSIEBCA * 100.0; // Entity Reflection Handling
            #endif

            #ifdef GENERATED_NORMALS
                if (!noGeneratedNormals) GenerateNormals(normalM, colorP);
            #endif

            #ifdef COATED_TEXTURES
                CoatTextures(color.rgb, noiseFactor, playerPos, false);
            #endif

            #if IPBR_EMISSIVE_MODE != 1
                emission = GetCustomEmissionForIPBR(color, emission);
            #endif
        #else
            #ifdef CUSTOM_PBR
                GetCustomMaterials(color, normalM, lmCoordM, NdotU, shadowMult, smoothnessG, smoothnessD, highlightMult, emission, materialMask, viewPos, 0.0);
            #endif
        #endif

        DoLighting(color, shadowMult, playerPos, viewPos, 0.0, geoNormal, normalM, 0.5,
                   worldGeoNormal, lmCoordM, noSmoothLighting, noDirectionalShading, noVanillaAO,
                   false, 0, smoothnessG, highlightMult, emission);

        #ifdef IPBR
            color.rgb += maRecolor;
        #endif
    }

    float skyLightFactor = GetSkyLightFactor(lmCoordM, shadowMult);

    #ifdef COLOR_CODED_PROGRAMS
        ColorCodeProgram(color, -1);
    #endif

    #ifdef IRIS_FEATURE_FADE_VARIABLE
        skyLightFactor *= 0.5;
    #endif

    /* DRAWBUFFERS:06 */
    gl_FragData[0] = color;
    gl_FragData[1] = vec4(smoothnessD, materialMask, skyLightFactor, 1.0);

    #if BLOCK_REFLECT_QUALITY >= 2 && (RP_MODE >= 2 || defined IS_IRIS)
        /* DRAWBUFFERS:064 */
        gl_FragData[2] = vec4(mat3(gbufferModelViewInverse) * normalM, 1.0);
    #endif
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

out vec2 texCoord;
out vec2 lmCoord;

flat out vec3 upVec, sunVec, northVec, eastVec;
out vec3 normal;

out vec4 glColor;

out vec4 corner0;
out vec4 corner1;
out vec2 texCoord1;

#if defined GENERATED_NORMALS || defined COATED_TEXTURES || defined POM || defined IPBR && defined IS_IRIS
    out vec2 signMidCoordPos;
    flat out vec2 absMidCoordPos;
    flat out vec2 midCoord;
#endif

#if defined GENERATED_NORMALS || defined CUSTOM_PBR
    flat out vec3 binormal, tangent;
#endif

#ifdef POM
    out vec3 viewVector;

    out vec4 vTexCoordAM;
#endif

//Attributes//
#if defined GENERATED_NORMALS || defined COATED_TEXTURES || defined POM || defined IPBR && defined IS_IRIS
    attribute vec4 mc_midTexCoord;
#endif

#if defined GENERATED_NORMALS || defined CUSTOM_PBR
    attribute vec4 at_tangent;
#endif

const ivec4 armUV[] = ivec4[](
    ivec4(40, 52, 36, 64), // left 
    ivec4(36, 64, 32, 52), // bottom 
    ivec4(44, 64, 48, 52), // right
    ivec4(44, 52, 40, 48), // top
    ivec4(40, 52, 44, 64), // east
    ivec4(36, 52, 40, 48)  // top
);

const ivec4 slimArmUV[] = ivec4[](
    ivec4(39, 52, 36, 64),
    ivec4(43, 64, 46, 52),
    ivec4(36, 64, 32, 52),
    ivec4(42, 52, 39, 48),
    ivec4(39, 52, 43, 64),
    ivec4(36, 52, 39, 48)
);

const bool armRotateUV[] = bool[](
    false, false, true, true, true, true
);

const bool armFlipUV[] = bool[](
    false, false, true, false, true, false
);

const bool armMirrorUV[] = bool[](
    true, false, false, false, false, false
);

bool isSlim() {
    vec4 samp1 = texture2D(tex, vec2(54.0 / 64.0, 20.0 / 64.0));
    vec4 samp2 = texture2D(tex, vec2(55.0 / 64.0, 20.0 / 64.0));
    return samp1.a == 0.0 ||
        (((samp1.r + samp1.g + samp1.b) == 0.0) &&
         ((samp2.r + samp2.g + samp2.b) == 0.0) &&
         samp1.a == 1.0 && samp2.a == 1.0);
}

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
    gl_Position = ftransform();

    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    lmCoord  = GetLightMapCoordinates();

    glColor = gl_Color;

    normal = normalize(gl_NormalMatrix * gl_Normal);

    upVec = normalize(gbufferModelView[1].xyz);
    eastVec = normalize(gbufferModelView[0].xyz);
    northVec = normalize(gbufferModelView[2].xyz);
    sunVec = GetSunVector();

    #if defined GENERATED_NORMALS || defined COATED_TEXTURES || defined POM || defined IPBR && defined IS_IRIS
        midCoord = (gl_TextureMatrix[0] * mc_midTexCoord).st;
        vec2 texMinMidCoord = texCoord - midCoord;
        signMidCoordPos = sign(texMinMidCoord);
        absMidCoordPos  = abs(texMinMidCoord);
    #endif

    #if defined GENERATED_NORMALS || defined CUSTOM_PBR
        binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
        tangent  = normalize(gl_NormalMatrix * at_tangent.xyz);
    #endif

    #ifdef POM
        mat3 tbnMatrix = mat3(
            tangent.x, binormal.x, normal.x,
            tangent.y, binormal.y, normal.y,
            tangent.z, binormal.z, normal.z
        );

        viewVector = tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;

        vTexCoordAM.zw  = abs(texMinMidCoord) * 2;
        vTexCoordAM.xy  = min(texCoord, midCoord - texMinMidCoord);
    #endif

    #if HAND_SWAYING > 0
        #include "/lib/misc/handSway.glsl"
    #endif

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
}

#endif
