Shader "WaterRefractive"
{
    Properties
    {
        [NoScaleOffset] _LightGradient ("Light Gradient", 2D) = "grey" {}
        [NoScaleOffset] _NormalMap ("Normal map", 2D) = "bump" {}

        _Specular ("Specular", Range(0.0, 1.0)) = 0.646
        _HighColor ("HighColor", color) = (1.0, 1.0, 1.0, 1.0)
        _DeepColor ("DeepColor", color) = (0.023, 0.4, 0.46, 1.0)
        _FakeBlinCol ("FakeBlinCol", color) = (0.5, 0.5, 0.5, 1.0)
        _FakeZMulti("Fake normal Z", Range(0.0, 4.0)) = 1.0
        _RimAmount("Muddiness", Range(-1.0, 1.0)) = 0.0
        _EdgeCrispness ("Crispness", Range(0,4)) = 1.65

        _RefrAngle("Refraction angle", Range(0.0, 1.0)) = 0.4
        _RefrPower("Refraction distortion", Range(0.0, 1.0)) = 0.5
        _RefrTransp("Water alpha amount", Range(0.0, 1.0)) = 0.88

        _FakeBlinLow("Fake blinn lower offset", Range(0.0, 1)) = 0.431
        _FakeBlinUp("Fake blinn  upper offset", Range(0.0, 0.99)) = 0.273

        [Toggle(REFLECTION)] _Reflection ("Turn on reflection", Float) = 0
        [Toggle(FANCY_LIGHTS)] _Fancy ("Turn on blinn lights", Float) = 0
        [Toggle(BLEND_EDGE)] _BlendEdge ("Turn on edge blending", Float) = 0
        [Toggle(FAKE_BLINN)] _FakeBlinn ("Cheap blinn", Float) = 0
    }

    CustomEditor "BOOMBIT_WaterRefractiveGUI"

    SubShader
    {
        Tags { 
        "RenderType"="Transparent" 
        "LightMode"="ForwardBase"
        "Queue"="Transparent"}
        LOD 200
        Blend SrcAlpha OneMinusSrcAlpha

        GrabPass { "_WaterRefraction" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #pragma shader_feature REFLECTION
            #pragma shader_feature FANCY_LIGHTS
            #pragma shader_feature BLEND_EDGE
            #pragma shader_feature FAKE_BLINN

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #include "Assets/Includes/CGINCS/CustomUtils.cginc"

            struct appdata
            {
                float4 vertex  : POSITION ;
                float4 uv      : TEXCOORD0;
                float3 normal  : NORMAL   ;
                float4 tangent : TANGENT  ;
            };

            struct v2f
            {
                float4 vertex    : SV_POSITION ;
                float4 uv        : TEXCOORD0   ;
                float3 normal    : TEXCOORD1   ;
                float4 tangent   : TEXCOORD2   ;
                float3 biNormal  : TEXCOORD3   ;
                float3 viewDir   : TEXCOORD4   ;
                float4 screenPos : TEXCOORD5   ;
            };

            float4    _NormalMap_ST                 ;
            sampler2D _NormalMap                    ;
            sampler2D _LightGradient                ;
            sampler2D _CameraDepthTexture           ;
            sampler2D _WaterRefraction              ;
            float4    _CameraDepthTexture_TexelSize ;

            half  _Specular      ;
            half  _RefrPower     ;
            half  _RefrAngle     ;
            half  _FakeBlinLow   ;
            half  _FakeBlinUp    ;
            fixed _RimAmount     ;
            fixed _FakeZMulti    ;
            fixed _RefrTransp    ;
            fixed _EdgeCrispness ;

            fixed4 _HighColor   ;
            fixed4 _DeepColor   ;
            fixed4 _FakeBlinCol ;

            inline float3  CalcRefraction(float3 tanNormal, float4 scrPos)
            {
                float2 uvOffset = _RefrAngle * 0.1 * tanNormal.xy;
                uvOffset.x *= _RefrPower * 50 ;
	            uvOffset.y *= _CameraDepthTexture_TexelSize.z * abs(_CameraDepthTexture_TexelSize.y);
	            float2 uv = (scrPos.xy + uvOffset) / scrPos.w;
                return tex2D(_WaterRefraction, uv).rgb;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.uv, _NormalMap).xyxy;
                o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
                o.biNormal = CalcBiNormal(o.normal, o.tangent);
                o.uv.xy += _Time.x;
                o.uv.zw += 1.5 * _Time.x;
                o.viewDir = normalize(WorldSpaceViewDir(v.vertex));
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half3 normal    = MobileNormalUnpack(tex2D(_NormalMap, i.uv.xy).xy, _FakeZMulti);
                half3 secNormal = MobileNormalUnpack(tex2D(_NormalMap, i.uv.zw).zw, _FakeZMulti);
                //better result than proper mix, might consider *3 ... +1
                normal = (float3(normal.xyz + secNormal.xyz)); //Normalization can be skipped
                normal =  CalcTanSpaceNormal(normal, i.tangent, i.biNormal, i.normal);

                //Base lighting, viewBias to not be flat from top view
                half NoV = DotClamped(i.viewDir, normal);
                half viewBias = lerp(2.5, 0.9, DotClamped(i.viewDir, half3(0,1,0)));
                half rim = (NoV * viewBias  ) + _RimAmount;
                half4 baseLight = tex2D(_LightGradient, float2(rim, rim));

                #ifdef FAKE_BLINN
                    half4 rimH = smoothstep( _FakeBlinLow - 0.01, _FakeBlinUp + 0.01, (NoV) * viewBias + _RimAmount ) * _FakeBlinCol.rgba ; //highlighter
                #endif

                #ifdef FANCY_LIGHTS
                    half3 halfVec = normalize(_WorldSpaceLightPos0.xyz + i.viewDir);
                    half3 blinPhong = pow(DotClamped(halfVec, normal), _Specular * 400);
                    half3 halfVec2 = normalize(_WorldSpaceLightPos0.xyz + i.viewDir.yzx);
                    half3 blinPh2 = pow(DotClamped(halfVec2, normal), _Specular * 400);
                    half3 blins = blinPh2 + blinPhong;
                #endif

                #ifdef REFLECTION
                    half3 reflectionDir = reflect(-i.viewDir, normal * i.normal); //*i.normal for lesser distortion
                    half roughness = 1 - smoothstep(0, 180, _Specular * 400); //magic is just a lesser from Specular
                    half3 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectionDir , (roughness ) * UNITY_SPECCUBE_LOD_STEPS);
                #endif

                #ifdef BLEND_EDGE
                    half edgeBlend = 1.0;
                    half depth = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos));
                    depth = LinearEyeDepth(depth);
                    edgeBlend = saturate(_EdgeCrispness * (depth-i.screenPos.w));
		        #endif
                
                //Base color
                fixed4 col;
                fixed4 waterColor = lerp( _DeepColor.rgba, _HighColor.rgba, baseLight.a );
                col.a = waterColor.a;

                #ifdef BLEND_EDGE
                    col.a *= edgeBlend;
                #endif

                #ifdef FAKE_BLINN
                    //left if want toilet
                    //col.a =  clamp(0, 1, rimH.a + ((1 - _DeepColor.a * rimH.a)
                    //*_DeepColor.a ));
                    waterColor = waterColor + rimH;
                #endif

                fixed3 refrColor = CalcRefraction(normal, i.screenPos);
                fixed3 refrBase = lerp(refrColor.rgb, waterColor.rgb, _RefrTransp); //prev 1 - baseLight.a
               
                #if defined (REFLECTION)
                    fixed3 finalMix = lerp(refrBase, envSample, 0.2);
                #endif

                #if defined (FANCY_LIGHTS) && defined (REFLECTION)
                    col.rgb =  finalMix + blins;
                    return col;
                #endif

                #if defined (REFLECTION)
                     col.rgb =  finalMix;
                     return col;
                #endif

                #if defined (FANCY_LIGHTS)
                    waterColor.rgb = refrBase.rgb;
                    col.rgb = waterColor + blins;
                    return col;
                #endif

                //left if we want toilet like transparent cheap light water
                //col.rgb = _DeepColor + rimH;
                col.rgb = refrBase;
                return col;
            }
            ENDCG
        }
    }
}