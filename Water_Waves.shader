Shader "Unlit/Water_Waves"
{
    Properties
    {
        [NoScaleOffset] _LightGradient ("Gradient", 2D) = "grey" {}
        [NoScaleOffset] _NormalMap ("Normal map", 2D) = "bump" {}
        [NoScaleOffset] _SecNormalMap ("Second normal map", 2D) = "bump" {}
        _Specular ("Specular", Range(0.0, 1.0)) = 0.01
        _HighColor ("HighColor", color) = (0.5, 0.5, 0.5, 1.0)
        _DeepColor ("DeepColor", color) = (0.5, 0.5, 0.5, 1.0)
        _Bumpiness("Bumpiness", Range(0.0, 1.0)) = 1.0
        _RimAmount("Fresnel", Range(0.0, 4.0)) = 1.0
        _RefrAngle("Refraction angle", Range(0.0, 1.0)) = 0.5
        _RefrPower("Refraction distortion", Range(0.0, 1.0)) = 0.5
        _Wave0("Wave0 parameters dir, step, wavelengt", Vector) = (1,0,0.5,10)
        _Wave1("Wave1 parameters", Vector) = (0,1,0.25,20)
        _Wave2("Wave2 parameters", Vector) = (1,1,0.15,10)
    }
    SubShader
    {
        Tags { 
        "RenderType"="Transparent" 
        "LightMode"="ForwardBase"
        "Queue"="Transparent"}
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha

        GrabPass { "_WaterRefraction" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityStandardBRDF.cginc"

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
            sampler2D _SecNormalMap                 ;
            sampler2D _LightGradient                ;
            sampler2D _CameraDepthTexture           ;
            sampler2D _WaterRefraction              ;
            float4    _CameraDepthTexture_TexelSize ;

            float  _Specular  ;
            float  _Bumpiness ;
            float  _RimAmount ;
            half   _RefrPower ;
            half   _RefrAngle ;
            fixed4 _HighColor ;
            fixed4 _DeepColor ;
            float4 _Wave0     ;
            float4 _Wave1     ;
            float4 _Wave2     ;

            //Own unpack funciton cause unity does not support scaling of bumpinees for mobiles
            inline float3 CalcFragNormal(float4 lookup, float scale,  float4 tangent, float3 wNormal, float3 biNormal)
            {
                float3 normal;
                normal.xy = lookup.wy * 2 - 1;
                normal.xy *= scale;
                normal.z = sqrt(1 - saturate(dot(normal.xy, normal.xy)));
                return normalize(
                                    normal.x * tangent  +
                                    normal.y * biNormal +
                                    normal.z * wNormal );
            }

            inline float3 CalcBiNormal(float3 normal, float4 tangent)
            {
                return cross(normal, tangent.xyz) * (tangent.w * unity_WorldTransformParams.w);
            }

            inline float3  CalcRefraction(float3 tanNormal, float4 scrPos)
            {
                float2 uvOffset = _RefrAngle * 0.1 * tanNormal.xy;
                uvOffset.x *= _RefrPower * 50 ;
	            uvOffset.y *= _CameraDepthTexture_TexelSize.z * abs(_CameraDepthTexture_TexelSize.y);
	            float2 uv = (scrPos.xy + uvOffset) / scrPos.w;
                return tex2D(_WaterRefraction, uv).rgb;
            }

            inline float3 CalcWave(float4 wave, float3 locPos, inout float3 biNormal, inout float3 tangent)
            {
                float steep = wave.z;
                float wavelength = wave.w;
                float k = 2 * UNITY_PI / wavelength;
                float c = sqrt(9.8 / k) * 0.2;
                float2 d = normalize(wave.xy);
                float f = k * (dot(d, locPos.xz) - c * _Time.y);
                float a = steep / k;

                tangent += float3(
                    -d.x * d.x * (steep * sin(f)),
                    d.x * (steep * cos(f)),
                    -d.x * d.y * (steep * sin(f))
                );
                biNormal += float3(
                    -d.x * d.y * (steep * sin(f)),
                    d.y * (steep * cos(f)),
                    -d.y * d.y * (steep * sin(f))
                );
                return float3(
                    d.x * (a * cos(f)),
                    a * sin(f),
                    d.y * (a * cos(f))
                );
		    }

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _NormalMap).xyxy;

                o.uv.xy += _Time.x;
                o.uv.zw += 1.5 * _Time.x;
                
                float3 tangent = float3(1, 0, 0);
			    float3 biNormal = float3(0, 0, 1);
                float3 wavePos = v.vertex.xyz;
                
                wavePos += CalcWave(_Wave0, v.vertex.xyz, biNormal, tangent);
                wavePos += CalcWave(_Wave1, v.vertex.xyz, biNormal, tangent);
                wavePos += CalcWave(_Wave2, v.vertex.xyz, biNormal, tangent);

                o.normal = normalize(cross(biNormal, tangent));
                o.biNormal = biNormal;
                o.tangent.xyz = tangent;
                o.tangent.w = v.tangent.w;

                float4 newPos;
                newPos.xyz = wavePos;
                newPos.w = v.vertex.w;

                o.vertex = UnityObjectToClipPos(newPos);
        
                o.viewDir = normalize(WorldSpaceViewDir(newPos));
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }
            

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal    = CalcFragNormal(tex2D(_NormalMap   , i.uv.xy), _Bumpiness, i.tangent, i.normal, i.biNormal);
                float3 secNormal = CalcFragNormal(tex2D(_SecNormalMap, i.uv.zw), _Bumpiness, i.tangent, i.normal, i.biNormal);
                normal = normalize(float3(normal + secNormal) );

                //half NdotL = DotClamped(normal, _WorldSpaceLightPos0);
                float rim =  (DotClamped(i.viewDir, normal)) * _RimAmount; //smooth one (brightener)
                //float rimH = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, (1 - DotClamped(i.viewDir, normal))); //highlighter

                half4 baseLight = tex2D(_LightGradient, float2(rim, rim));
                
                //Lightning calc
                float3 halfVec = normalize(_WorldSpaceLightPos0.xyz + i.viewDir);
                float3 blinPhong = pow(DotClamped(halfVec, normal), _Specular * 400);
                float3 halfVec2 = normalize(_WorldSpaceLightPos0.xyz + i.viewDir.yzx);
                float3 blinPh2 = pow(DotClamped(halfVec2, normal), _Specular * 400);
                
                //Ambient reflection light
                float3 reflectionDir = reflect(-i.viewDir, i.normal * normal);
                float roughness = 1 - smoothstep(0, 300, _Specular * 400); //magic is just a lesser from Specular
                float3 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectionDir , (roughness ) * UNITY_SPECCUBE_LOD_STEPS);
                
                //Final color
                fixed4 col;
                col.a = 1;
                //TODO:Check different mixing possibilities as for mix is by frensel
                fixed4 waterColor = lerp( _DeepColor.rgba, _HighColor.rgba, baseLight.a );
                fixed3 refColor = CalcRefraction(normal, i.screenPos);
                fixed3 baseColor = lerp(refColor.rgb, waterColor.rgb, 1 - baseLight.a);
                fixed3 finalMix = lerp(baseColor, envSample, baseLight.a);
                
                col.rgb =  finalMix + (blinPh2 + blinPhong);
                col.a = waterColor.a;
                return col;
            }
            ENDCG
        }
    }
}