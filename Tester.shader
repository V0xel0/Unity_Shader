﻿// Normal Mapping for a Triplanar Shader - Ben Golus 2017
// Whiteout Blend example shader

// Uses a straight forward Whiteout style normal map blend. Good balance of performance and appearance.

Shader "Triplanar/Tester"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset] _BumpMap ("Normal Map", 2D) = "bump" {}
    }
    SubShader
    {
        Tags { "LightMode"="ForwardBase" "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // flip UVs horizontally to correct for back side projection
            #define TRIPLANAR_CORRECT_PROJECTED_U

            // offset UVs to prevent obvious mirroring
            // #define TRIPLANAR_UV_OFFSET

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                half3 worldNormal : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _BumpMap;
            
            fixed4 _LightColor0;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                //calculate triplanar blend
                half3 triblend = pow(abs(i.worldNormal), 16);
                triblend /= max(dot(triblend, half3(1,1,1)), 0.0001);

                // // Asymmetric Triplanar Blend
                // float3 triblend = 0;
                // // Blend for sides only
                // float2 xzBlend = abs(normalize(i.worldNormal.xz));
                // triblend.xz = max(0, xzBlend - 0.67);
                // triblend.xz /= dot(triblend.xz, float2(1,1));
                // // Blend for top
                // triblend.y = saturate((abs(i.worldNormal.y) - 0.675) * 80.0);
                // triblend.xz *= (1 - triblend.y);

                // preview blend
                // return fixed4(triblend.xyz, 1);

                // calculate triplanar uvs
                // applying texture scale and offset values ala TRANSFORM_TEX macro
                float2 uvX = i.worldPos.zy * _MainTex_ST.xy + _MainTex_ST.zw;
                float2 uvY = i.worldPos.xz * _MainTex_ST.xy + _MainTex_ST.zw;
                float2 uvZ = i.worldPos.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                // offset UVs to prevent obvious mirroring
            #if defined(TRIPLANAR_UV_OFFSET)
                uvY += 0.33;
                uvZ += 0.67;
            #endif

                // minor optimization of sign(), prevents return value of 0
                half3 axisSign = i.worldNormal < 0 ? -1 : 1;
                
                // flip UVs horizontally to correct for back side projection
            #if defined(TRIPLANAR_CORRECT_PROJECTED_U)
                uvX.x *= axisSign.x;
                uvY.x *= axisSign.y;
                uvZ.x *= -axisSign.z;
            #endif

                // albedo textures
                fixed4 colX = tex2D(_MainTex, uvX);
                fixed4 colY = tex2D(_MainTex, uvY);
                fixed4 colZ = tex2D(_MainTex, uvZ);
                fixed4 col = colX * triblend.x + colY * triblend.y + colZ * triblend.z;

                // tangent space normal maps
                half3 tnormalX = UnpackNormal(tex2D(_BumpMap, uvX));
                half3 tnormalY = UnpackNormal(tex2D(_BumpMap, uvY));
                half3 tnormalZ = UnpackNormal(tex2D(_BumpMap, uvZ));

                // flip normal maps' x axis to account for flipped UVs
            #if defined(TRIPLANAR_CORRECT_PROJECTED_U)
                tnormalX.x *= axisSign.x;
                tnormalY.x *= axisSign.y;
                tnormalZ.x *= -axisSign.z;
            #endif

                // swizzle world normals to match tangent space and apply Whiteout normal blend
                tnormalX = half3(tnormalX.xy + i.worldNormal.zy, tnormalX.z * i.worldNormal.x);
                tnormalY = half3(tnormalY.xy + i.worldNormal.xz, tnormalY.z * i.worldNormal.y);
                tnormalZ = half3(tnormalZ.xy + i.worldNormal.xy, tnormalZ.z * i.worldNormal.z);

                // swizzle tangent normals to match world normal and blend together
                half3 worldNormal = normalize(
                    tnormalX.zyx * triblend.x +
                    tnormalY.xzy * triblend.y +
                    tnormalZ.xyz * triblend.z
                    );

                // preview world normals
                // return fixed4(worldNormal * 0.5 + 0.5, 1);

                // calculate lighting
                half ndotl = saturate(dot(worldNormal, _WorldSpaceLightPos0.xyz));
                half3 ambient = ShadeSH9(half4(worldNormal, 1));
                half3 lighting = _LightColor0.rgb * ndotl + ambient;

                // preview directional lighting
                // return fixed4(ndotl.xxx, 1);

                return fixed4(col.rgb * lighting, 1);
            }
            ENDCG
        }
    }
}