#ifndef CUSTOM_UTILS
#define CUSTOM_UTILS

    inline half3 CalcTanSpaceNormal(half3 normal, half3 tangent, half3 biNormal, half3 wNormal )
    {
        return  normalize (
                            normal.x * tangent  +
                            normal.y * biNormal +
                            normal.z * wNormal );
    }

    inline half3 CalcBiNormal(half3 normal, half4 tangent)
    {
        return cross(normal, tangent.xyz) * (tangent.w * unity_WorldTransformParams.w);
    }

    //For normals packed as RGRG in RGBA, "Z" is faked
    inline half3 MobileNormalUnpack(float2 normalMap, half fakeZ)
    {
        return half3(normalMap.xy * 2 - 1, fakeZ);
    }

#endif