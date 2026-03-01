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
