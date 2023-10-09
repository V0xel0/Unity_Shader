Shader "Unlit/BPHeight"
{
    Properties
    {
        _MainTex ("Albedo", 2D) = "black" {}
        [NoScaleOffset] _MetallicMap("Metallic map", 2D) = "white" {}
        [NoScaleOffset] _NormalMap ("Normal map", 2D) = "bump" {}
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 1.0
        _Tint("Tint", color) = (1.0, 1.0, 1.0, 1.0)
        _Bumpiness("Bumpiness", Range(0.0, 1.0)) = 1.0
        _BaseRef("Material base reflectivity", Range(0.0, 1)) = 0.5
        [Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 1.0
    }

    CustomEditor "BPHeightGUI"

    SubShader
    {
        Tags { 
        "RenderType"="Opaque" 
        "LightMode" = "ForwardBase"}
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #pragma shader_feature _ALBEDO_MAP
            #pragma shader_feature _METALLIC_MAP
            #pragma shader_feature _SMOOTHNESS_ALBEDO

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #include "Assets/Includes/CGINCS/CustomUtils.cginc"

            struct appdata
            {
                float4 vertex  : POSITION  ;
                float2 uv      : TEXCOORD0 ;
                float3 normal  : NORMAL    ;
                float4 tangent : TANGENT   ;
            };

            struct v2f
            {
                half4  vertex    : SV_POSITION ;
                float2 uv        : TEXCOORD0   ;
                half3  normal    : TEXCOORD1   ;
                half3  viewDir   : TEXCOORD2   ;
                half4  tangent   : TEXCOORD3   ;
                half3  biTangent : TEXCOORD4   ;
            };

            sampler2D _MainTex     ;
            float4    _MainTex_ST  ;
            sampler2D _MetallicMap ;
            sampler2D _NormalMap   ;

            half  _Smoothness ;
            half4 _Tint       ;
            half  _Bumpiness  ;
            half  _Metallic   ;
            half  _BaseRef    ;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
                o.biTangent = CalcBiNormal(o.normal, o.tangent);
                o.viewDir = normalize (WorldSpaceViewDir(v.vertex));
                return o;
            }

            //TODO: Move to include file
            inline half GetMetallicAndSmoothness(float2 uv, inout half sm)
            {
                #if defined( _METALLIC_MAP )
                    half4 vals =  tex2D(_MetallicMap, uv.xy);
                    #ifndef _SMOOTHNESS_ALBEDO
                        sm = vals.a * _Smoothness;
                    #endif
                    return vals.r;
                #else
                    return _Metallic;
                #endif
            }

            inline half3 GetDiffuseColorAndSmoothness(float2 uv, inout half sm)
            {
                #if defined (_ALBEDO_MAP)
                    half4 vals = tex2D(_MainTex, uv.xy);
                    #if defined (_SMOOTHNESS_ALBEDO)
                        sm = vals.a * _Smoothness;
                    #endif
                    return  vals.rgb * _Tint;
                #else
                    return _Tint;
                #endif
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half3 normal = UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _Bumpiness);
                normal = CalcTanSpaceNormal(normal, i.tangent, i.biTangent, i.normal);
                //Utils vectors
                half NoL = DotClamped(normal, _WorldSpaceLightPos0);
                half NoV = DotClamped(i.viewDir, i.normal);
                half3 reflectionDir = reflect(-i.viewDir, normal); //*i.normal for less distoriton
                half3 halfVec = normalize(_WorldSpaceLightPos0.xyz + i.viewDir);
                half NoH = DotClamped(halfVec, normal);
                
                half oneMinusReflectivity;
                half smoothness = _Smoothness;
                half metallic = GetMetallicAndSmoothness(i.uv.xy, smoothness);

                half3 specColor;
                half3 albedo = GetDiffuseColorAndSmoothness(i.uv.xy, smoothness);
                albedo =  DiffuseAndSpecularFromMetallic(albedo, metallic, specColor, oneMinusReflectivity);

                half roughness = 1 - smoothness;
                half3 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectionDir, (roughness) * UNITY_SPECCUBE_LOD_STEPS);
                half3 ambient = ShadeSH9(half4(normal, 1));

                float blinPhong = saturate(pow(NoH, Pow5(clamp(smoothness * smoothness, 0.38, 1)) * 3200));
                blinPhong *= lerp(0, 9, smoothness ) * smoothness;
                
                half3 specMix = blinPhong * specColor;
                half3 baseLightning = NoL * _LightColor0 + ambient;

                // 0.17 Diamond (linear) is 0.45 in SRGB, for performance reason Gamma workflow is assumed
                //But PBR requires all inputs to be linear xDDD
                half normBase = lerp(0, 0.45, _BaseRef); 
                half fresnelPow = Pow4(1 - NoV);
                half3 r0 = lerp(normBase, specColor, metallic); //spec Color is in srgb TODO:: Replace Unity macro to own if want linear
                r0 = clamp(r0, 0.01, 0.95);
                half3 f0 = (r0 + (1 - r0) * fresnelPow);

                // albedo = GetDiffuseColorAndSmoothness(i.uv.xy, smoothness);
                // half3 kD = 1 - f0;
                // kD *= oneMinusReflectivity;

                //Final color
                fixed4 col;
                col.rgb =  (albedo * baseLightning + 
                          f0 * envSample  * clamp(smoothness, 0.84, 1) + //hack
                          + specMix ) + 
                          NoL * specColor * (1 - smoothness) * clamp(metallic, 0, 0.75); //hack for metallic witl low smooth
                // col.rgb = col.rgb / (col.rgb + 1);
                // col.rgb = pow(col.rgb, half3(1/2.2, 1/2.2, 1/2.2));
                col.a = 1.0;
                return col;
            }
            ENDCG
        }
    }
}