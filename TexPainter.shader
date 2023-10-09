Shader "Unlit/TexPainter"
{
    Properties
    {
        _MainTex ("Albedo", 2D) = "grey" {}
        _PaintTex ("Texture to paint", 2D) = "grey" {}
        [NoScaleOffset] _NormalMap ("Normal map", 2D) = "bump" {}
        _Specular("Specular", Range(0.0, 200.0)) = 0.1
        _Gloss("Glossines", color) = (0.5, 0.5, 0.5, 1.0)
        _Bumpiness("Bumpiness", Range(0.0, 1.0)) = 1.0
        _PainterA("PainterA", Range(0, 1.0)) = 0.7
        _PainterB("PainterB", Range(0, 1.0)) = 0.5
        _PaintVec("Painting Vec(xyz) & bump(w)", vector) = (0, 1, 0, 0)
        [Toggle(CONSERVATION)] _Conservation ("Energy Conservation", Float) = 0
        [Toggle(REFLECTION)] _Reflection ("Reflective", Float) = 0
    }
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
            #pragma shader_feature CONSERVATION
            #pragma shader_feature REFLECTION

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityStandardBRDF.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent: TANGENT;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float4 locPos : TEXCOORD2;
                float4 tangent : TEXCOORD3;
                float paint : TEXCOORD04;
            };

            sampler2D _MainTex;
            sampler2D _PaintTex;
            float4 _PaintTex_ST;
            float4 _MainTex_ST;
            sampler2D _NormalMap;

            float4 _Gloss;
            float _Specular;
            float _Bumpiness;

            float _PainterA;
            float _PainterB;
            float4 _PaintVec;

            //If look>perf then move to frag
            float calcPaint(float3 norm)
            {
                float3 pVec = normalize(_PaintVec).xyz;
                float painterIntensity = smoothstep(_PainterA, 1.0, DotClamped(norm, pVec));
                float paint = smoothstep(_PainterB, 1.0, painterIntensity);
                return paint;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.paint = calcPaint(o.normal);
                o.vertex = UnityObjectToClipPos(v.vertex + v.normal * o.paint * _PaintVec.w);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _PaintTex);
                o.locPos = v.vertex;
                o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal;
                //Normal calculation (taking normal map into account)
                normal.xy = tex2D(_NormalMap, i.uv.xy).wy * 2 - 1;
                normal.xy *= _Bumpiness;
                normal.z = sqrt(1 - saturate(dot(normal.xy, normal.xy)));
    
                float3 binormal = cross(i.normal, i.tangent.xyz) * (i.tangent.w * unity_WorldTransformParams.w);
                normal = normalize(
                                    normal.x * i.tangent + 
                                    normal.y * binormal + 
                                    normal.z * i.normal);
                //Utils vector
                float3 viewDir = normalize (WorldSpaceViewDir(i.locPos));
                float3 halfVec = normalize(_WorldSpaceLightPos0.xyz + viewDir); //L+V / |L+V|
                //Lightning calc
                float3 blinPhong = pow(DotClamped(halfVec, normal), _Specular) * _Gloss.rgb;
                float lambert = DotClamped(normal, _WorldSpaceLightPos0);
                //Albedo calc
                float3 albedo = lerp(tex2D(_MainTex, i.uv.xy).rgb, tex2D(_PaintTex, i.uv.zw).rgb, i.paint);
                #ifdef CONSERVATION
                    albedo *= 1 - max(_Gloss.r, max(_Gloss.g, _Gloss.b)); //monchrome energy conservation - use the strongest component
                #endif
                //Lightning colors
                float3 diffCol = lambert *  _LightColor0 * albedo;
                float3 specCol = blinPhong;
               
                #ifdef REFLECTION
                    float3 reflectionDir = reflect(-viewDir, normal); //i.normal if want global effect
                    float roughness = 1 - smoothstep(0, 150, _Specular); //magic is just from 180 (max editor range of _Specular)
                    float3 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectionDir, (roughness ) * UNITY_SPECCUBE_LOD_STEPS);
                    specCol = (specCol + envSample * _Gloss.rgb);
                #endif

                //Final color
                fixed4 col;
                col.rgb = (diffCol + specCol + albedo * 0.15); // albedo * magic is just a simple ambient lighting -- albedo could be any color wanted
                col.a = 1.0;
                return col;
            }
            ENDCG
        }
    }
}