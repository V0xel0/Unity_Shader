Shader "Unlit/CartoonB"
{
    Properties
    {
        _MainTex ("Albedo", 2D) = "black" {}
        _Color ("Color", color) = (1,1,1,1)
        _Specular("Specular", Range(0.0, 300.0)) = 0.1
        _Gloss("Glossines", Range(0, 0.7)) = 0.01
        _RimColor("Rim Color", color) = (0,0,0,1)
        _RimAmount("Rim Amount", Range(0, 1)) = 0.5
        _RimLength("Rim Length", Range(0, 5)) = 0.5
        _OverlayColor("Overlay color", color) = (0,0,0,1)
        _OverlayWidth("Overlay width", Range(0, 1)) = 0.02
        _SpecularColor("Specular color", color) = (1,1,1,1)
    }

    SubShader
    {
         Tags { 
            "RenderType"="Opaque" }
        
        Pass
        {
            LOD 100
            Cull Front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature DRAW_OVERLAY

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
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
            };

            fixed4 _OverlayColor;
            float _OverlayWidth;

            v2f vert (appdata v)
            {
                v2f o;
                o.normal = v.normal;
                o.vertex = UnityObjectToClipPos(v.vertex + o.normal * _OverlayWidth);

                return o;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col;
                col = _OverlayColor;
                return col;
            }
            ENDCG
        }
        Pass
        {
             Tags { 
            "LightMode" = "ForwardBase"}
            LOD 100
            Cull Back
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature CONSERVATION

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
                float4 viewDir : TEXCOORD1;
                
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Specular;
            float _Gloss;
            float _RimAmount;
            float _RimLength;
            fixed4 _Color;
            fixed4 _RimColor;
            fixed4 _SpecularColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.viewDir = v.vertex;
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal = normalize(i.normal);
                float lightIntensity = smoothstep(0, 0.09, DotClamped(normal, _WorldSpaceLightPos0));
                float lambert = smoothstep(0, 0.05, lightIntensity);
                float3 viewDir = normalize (WorldSpaceViewDir(i.viewDir));
                float3 halfVec = normalize(_WorldSpaceLightPos0.xyz + viewDir); //L+V / |L+V|
                float3 rim = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, (1 - DotClamped(viewDir, normal)) * DotClamped(dot(normal, _WorldSpaceLightPos0), _RimLength));
                //float3 rim2 = (1- dot(viewDir, normal)) * pow(dot(normal, _WorldSpaceLightPos0), _RimLength);

                float blinPhong =  smoothstep(0.005, 0.01, pow(DotClamped(halfVec, normal), _Specular) * _Gloss );
                fixed4 col;
                col.rgb = _LightColor0 * _Color.rgb * lambert + _Color.rgb * 0.45 + blinPhong * _SpecularColor + rim * _RimColor; // albedo * magic is just a simple ambient lighting -- albedo could be any color wanted
                col.a = 1.0;
                return col;
            }
            ENDCG
        }
    }
}
