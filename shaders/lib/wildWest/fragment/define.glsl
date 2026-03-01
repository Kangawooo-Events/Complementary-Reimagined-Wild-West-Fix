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
