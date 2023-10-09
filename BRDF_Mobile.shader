Shader "Unlit/BRDF_Mobile"
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
                half3  worldPos   : TEXCOORD2   ;
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
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
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

            inline half Specular(half r, half NoH, half LoH)
            {
                half a = Pow4(r);
                half b = NoH * NoH * (a - 1) + 1;
                half denom = 4 * UNITY_PI * b * b  * max(0.1, (LoH * LoH) )  * (r + 0.5);
                return a / denom;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half3 viewDir =  normalize(_WorldSpaceCameraPos - i.worldPos);
                half3 normal = UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _Bumpiness);
                normal = CalcTanSpaceNormal(normal, i.tangent, i.biTangent, i.normal);
                //Utils vectors
                half NoL = DotClamped(normal, _WorldSpaceLightPos0);
                half NoV = DotClamped(viewDir, i.normal);
                half3 reflectionDir = reflect(-viewDir, normal); //*i.normal for less distoriton
                half3 halfVec = normalize(_WorldSpaceLightPos0.xyz + viewDir);
                half NoH = DotClamped(halfVec, normal);
                half LoH = DotClamped(_WorldSpaceLightPos0.xyz, halfVec);
                
                half oneMinusReflectivity;
                half smoothness = _Smoothness;
                half metallic = GetMetallicAndSmoothness(i.uv.xy, smoothness);

                half3 specColor;
                half3 albedo = GetDiffuseColorAndSmoothness(i.uv.xy, smoothness);
                albedo =  DiffuseAndSpecularFromMetallic(albedo, metallic, specColor, oneMinusReflectivity); //This return Gamma value instead of linear!

                half roughness = clamp(1 - smoothness, 0.033, 1);
                half3 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectionDir, (roughness) * UNITY_SPECCUBE_LOD_STEPS);
                half3 ambient = ShadeSH9(half4(normal, 1));

                half3 specular = specColor * Specular(roughness, NoH,  LoH);
            

                //Final color
                fixed4 col;
                col.rgb = (specular + albedo * UNITY_INV_PI) * NoL * _LightColor0;
                //col.rgb = 1 / (max(0.1, (LoH * LoH) )  * (roughness + 0.5)) * specColor;
                col.a = 1.0;
                return col;
            }
            ENDCG
        }
    }
}
