//IN ORDER FOR THE SHADER TO WORK MESH UVS HAVE TO BE IN 0-1 SPACE AS MESH UV IS
//MAPPING 0-1 UV SPACE OF THE CUSTOMRENDERTEXTURE 1:1
//IF WANT SEPARATE UVS FOR MAPPING THEY HAVE TO BE IN UV2 AND FOR NOW, ONLY
//SMOOTHING BY NORMAL WILL WORK FOR UV2 (IF WANT BOTH SMOOTHING EFFECTS THEN uv2 HAS TO BE 0-1
//CORRECTLY MAPPED)
Shader "Unlit/Smoother"
{
    Properties
    {
        _MainTex ("Albedo", 2D) = "grey" {}
        [NoScaleOffset] _NormalMap ("Normal map", 2D) = "bump" {}
        [NoScaleOffset] [HideInInspector] _TrackMap ("Track map", 2D) = "black" {}
        _TrackTex ("Track texture", 2D) = "grey" {}
        _FakeZMulti("Fake normal Z", Range(0.0, 4.0)) = 1.0
        [Toggle(MOVE_VERT)] 
         _MoveVerts ("Move verts", Float) = 0
    }
    SubShader
    {
        Tags { 
        "RenderType"="Opaque" 
        }
        LOD 200
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #pragma shader_feature MOVE_VERT
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex  : POSITION  ;
                float2 uv      : TEXCOORD0 ;
                float2 uv1     : TEXCOORD1;
                float2 uv2     : TEXCOORD2 ;
                float3 normal  : NORMAL    ;
                float4 tangent : TANGENT   ;
            };

            struct v2f
            {
                float4 pos      : SV_POSITION ;
                float4 uv       : TEXCOORD0   ;
                half3  normal   : TEXCOORD1   ;
                half4  tangent  : TEXCOORD2   ;
                half3  biNormal : TEXCOORD3   ;
                #if defined( MOVE_VERT )
                    half smooth : TEXCOORD4;
                #else
                    float2 uv2 : TEXCOORD4;
                #endif
                float2 uv1 : TEXCOORD5;
                SHADOW_COORDS(6)
            };

            sampler2D _MainTex     ;
            float4    _MainTex_ST  ;
            sampler2D _NormalMap   ;
            sampler2D _TrackMap    ;
            sampler2D _TrackTex    ;
            float4    _TrackTex_ST ;

            fixed _FakeZMulti    ;

            inline half3 CalcTanSpaceNorm(half3 normal, half3 tangent, half3 biNormal, half3 wNormal )
            {
                return  normalize (
                                    normal.x * tangent  +
                                    normal.y * biNormal +
                                    normal.z * wNormal );
            }

            inline half3 CalcBiNormal(float3 normal, float4 tangent)
            {
                return cross(normal, tangent.xyz) * (tangent.w * unity_WorldTransformParams.w);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.uv.xy = TRANSFORM_TEX(v.uv.xy, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv.xy, _TrackTex);

                //!! WILL ONLY WORK FOR PROPER first UV - to support uv2 more
                //!! inerpolators is needed or double sampling (in vert and then
                //!  in frag)
                #if defined( MOVE_VERT )
                    o.smooth = tex2Dlod(_TrackMap, float4(v.uv.xy, 0, 0)).r;
                    v.vertex.y -= v.normal.y * o.smooth  * 0.02;
                #else
                    o.uv2 = v.uv2;
                #endif

                o.pos = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
                o.biNormal = CalcBiNormal(o.normal, o.tangent);
                o.uv1 = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
                TRANSFER_SHADOW(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half smooth;

                #if defined( MOVE_VERT )
                    smooth = i.smooth;
                #else
                    smooth = tex2D(_TrackMap, i.uv2.xy);
                #endif

                half3 normal = half3((tex2D(_NormalMap, i.uv.xy).xy * 2 - 1), _FakeZMulti);
                normal.x += (1 - smooth) * smooth * 1.0; //Magic is "fallof (greyish thing) in final effect"
                normal.y += (1 - smooth) * smooth * 1.0; //1.0 for lower res
                //normal.z += smooth * 0.05;
                normal.z -=  (1 - smooth) * smooth * 1.0; //for z: "+" gives more natural effectc, "-" is more aggresive
                normal =  CalcTanSpaceNorm(normal, i.tangent, i.biNormal, i.normal);
                
                half shadow = SHADOW_ATTENUATION(i);
                //REALTIME LIGHTING
                // half NdotL = DotClamped(normal, _WorldSpaceLightPos0);
                //half3 ambient = ShadeSH9(half4(normal, 1));
                //half3 baseLight = (NdotL *  _LightColor0 * shadow + ambient);

                //LIGHTMAP LIGHTNING
                half3 baseLight =  DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv1)) ;
                half4 lightmapDirection = UNITY_SAMPLE_TEX2D_SAMPLER(unity_LightmapInd, unity_Lightmap, i.uv1) ;
                baseLight = DecodeDirectionalLightmap(baseLight, lightmapDirection, normal) ;
                //baseLight = SubtractMainLightWithRealtimeAttenuationFromLightmap(baseLight,
                //shadow, UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv1.xy ),
                //normal);
                
                half3 albedo = tex2D(_MainTex, i.uv.xy).rgb;
                half3 trackCol = tex2D(_TrackTex, i.uv.zw).rgb * 0.55;
                half3 baseCol = lerp(albedo, trackCol, smooth);

                fixed4 col;
                col.rgb = (baseLight * baseCol * shadow + baseLight * 0.1);
                //col.rgb = fixed3(smooth, smooth , smooth); 
                col.a = 1.0;
                return col;
            }
            ENDCG
        }
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}