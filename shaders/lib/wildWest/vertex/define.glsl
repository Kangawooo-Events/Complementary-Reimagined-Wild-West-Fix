out vec4 corner0;
out vec4 corner1;
out vec2 texCoord1;

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