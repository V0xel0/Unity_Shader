Shader "Unlit/Gouraud"
{
    Properties
    {
        _MainTex ("Albedo", 2D) = "black" {}
        _Specular("Specular", Range(0.0, 200.0)) = 0.1
        _Gloss("Glossines", color) = (0.5, 0.5, 0.5, 1.0)
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
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float3 diffuse : TEXCOORD1;
                float3 specular : TEXCOORD2;
                float4 locPos : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Specular;
            float4 _Gloss;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                float3 wpos = mul(unity_ObjectToWorld, v.vertex).xyz;
                float3 viewDir = normalize(_WorldSpaceCameraPos - wpos);
                float3 halfVec = normalize(_WorldSpaceLightPos0.xyz + viewDir); //L+V / |L+V|

                float3 blinPhong = pow(DotClamped(halfVec, o.normal), _Specular) * _Gloss.rgb; //+ fixed3(1,0,1) * _Gloss.rgb;
                float lambert = DotClamped(o.normal, _WorldSpaceLightPos0); //multiplication with albedo in fragment

                o.diffuse = lambert *  _LightColor0;
                o.specular = blinPhong; 
                o.locPos = v.vertex;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 albedo = tex2D(_MainTex, i.uv).rgb * 1; //magic is a multiplier for light
                #ifdef CONSERVATION
                    albedo *= 1 - max(_Gloss.r, max(_Gloss.g, _Gloss.b)); //monchrome energy conservation - use the strongest component
                #endif

                i.diffuse *= albedo;

                #ifdef REFLECTION
                    float3 viewDir = normalize (WorldSpaceViewDir(i.locPos));
                    float3 reflectionDir = reflect(-viewDir, i.normal);
                    float roughness = 1 - smoothstep(0, 150, _Specular); //magic is just from 180 (max editor range of _Specular)
                    float3 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectionDir, (roughness ) * UNITY_SPECCUBE_LOD_STEPS);
                    i.specular = (i.specular + envSample * _Gloss.rgb) * _LightColor0;
                #endif

                fixed4 col;
                col.rgb = (i.diffuse + i.specular + albedo * 0.15); // albedo * magic is just a simple ambient lighting -- albedo could be any color wanted
                col.a = 1.0;
                return col;
            }
            ENDCG
        }
    }
}