Shader "Unlit/PBS_Test"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SpecColor("Specular color", color) = (0.5, 0.5, 0.5, 1.0)
        _Roughness("Roughness", Range(0, 1)) = 0.5
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

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal :NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal    : TEXCOORD1;
                float3 viewDir   : TEXCOORD2;
            };

            half3 EnvBRDFApprox( half3 SpecularColor, half Roughness, half NoV )
            {
                const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
                const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
                half4 r = Roughness * c0 + c1;
                half a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
                half2 AB = half2( -1.04, 1.04 ) * a004 + r.zw;
                return SpecularColor * AB.x + AB.y;
            }

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _SpecColor;
            half _Roughness;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = normalize(WorldSpaceViewDir(v.vertex));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col;
                half NoV = dot(i.normal, i.viewDir);
                col.rgb = EnvBRDFApprox(_SpecColor.rgb, _Roughness, NoV).rgb;
                col.a = 1;
                return col;
            }
            ENDCG
        }
    }
}
