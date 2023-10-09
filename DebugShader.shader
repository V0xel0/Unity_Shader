Shader "Unlit/DebugShader"
{
    Properties
    {
        [Toggle(OBJECT_SPACE)]
        _SwitchSpace ("Switch to Object Space", Float) = 0
        [Toggle(VERTEX_COLOR)]
        _ShowVertColors("Show Vertex Color", Float) = 0
        [Toggle(SCREEN_POS)]
        _ShowScreenPos("Show Screen Pos", Float) = 0
        [Toggle(UVS)]
        _ShowUVs("Show UVs", Float) = 0
        [Toggle(UVS1)]
        _ShowUVS1("Show UVs_1", Float) = 0
        [Toggle(UVS2)]
        _ShowUVS2("Show UVs_2", Float) = 0

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature OBJECT_SPACE
            #pragma shader_feature VERTEX_COLOR
            #pragma shader_feature SCREEN_POS
            #pragma shader_feature UVS
            #pragma shader_feature UVS1
            #pragma shader_feature UVS2
            #pragma target 3.0
            #include "UnityCG.cginc"

            struct appdata
            {
                float2 uv     : TEXCOORD0;
                float2 uv1    : TEXCOORD1;
                float2 uv2    : TEXCOORD2;
                float3 normal : NORMAL   ;
                float4 vertex : POSITION ;
                fixed4 color  : COLOR    ;
            };

            struct v2f
            {
                float2 uv         : TEXCOORD0;
                float3 normal     : TEXCOORD1;
                float4 vertScrPos : TEXCOORD2;
                float2 uv1        : TEXCOORD3;
                float2 uv2        : TEXCOORD4;
                float4 vertex : SV_POSITION;
                fixed4 color  : COLOR      ;
            };

            sampler2D _MainTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                #ifndef OBJECT_SPACE
                    o.normal = UnityObjectToWorldNormal(v.normal);
                #else
                    o.normal = v.normal;
                #endif
                #ifdef SCREEN_POS
                    o.vertScrPos = ComputeScreenPos(o.vertex);
                #endif
                #ifdef VERTEX_COLOR
                    o.color = v.color;
                #endif
                #ifdef UVS
                    o.uv = v.uv;
                #endif
                #ifdef UVS1
                    o.uv1 = v.uv1;
                #endif
                 #ifdef UVS2
                    o.uv2 = v.uv2;
                #endif
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //i.normal = normalize(i.normal); //if we want to be precise, otherwise for performance -> dont normalize
                #ifdef VERTEX_COLOR
                    return i.color;
                #endif
                #ifdef SCREEN_POS
                    float2 fragPos = i.vertScrPos / i.vertScrPos.w;
                    return fixed4(i.vertScrPos.x, i.vertScrPos.y, 0.5, 1.0);
                #endif
                #ifdef UVS
                    return fixed4(i.uv.x, i.uv.y, 0.0, 1.0);
                #endif
                 #ifdef UVS1
                    return fixed4(i.uv1.x, i.uv1.y, 0.0, 1.0);
                #endif
                #ifdef UVS2
                    return fixed4(i.uv2.x, i.uv2.y, 0.0, 1.0);
                #endif
                return fixed4(i.normal * 0.5 + 0.5, 1.0);
            }
            ENDCG
        }
    }
}
