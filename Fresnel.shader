Shader "Unlit/Fresnel"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "grey" {}
        _Fresnel("Fresnel", Range(0.0, 1.0)) = 1.0
        _NdotLMul("Base light multiplier",  Range(0.0, 4.0)) = 1.0
        _RimAmount("Rim adder", Range(-1.0, 1.0)) = 0.0

        _FakeBlinCol ("FakeBlinCol", color) = (0.5, 0.5, 0.5, 1.0)
        _FakeBlinLow("Fake blinn lower offset", Range(0.0, 1)) = 0.431
        _FakeBlinUp("Fake blinn  upper offset", Range(0.0, 0.99)) = 0.273

        [Toggle(EXTRA_RIM)] _ExtraRim ("Extra Rim", Float) = 0
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

            #pragma shader_feature EXTRA_RIM

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityStandardBRDF.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal  : NORMAL   ;
                float4 tangent : TANGENT  ;


            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                half3 normal    : TEXCOORD1   ;
                half4 tangent   : TEXCOORD2   ;
                half3 viewDir   : TEXCOORD4   ;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            half _Fresnel;
            half _NdotLMul;

            fixed _RimAmount;

            fixed4 _FakeBlinCol;
            half  _FakeBlinLow;
            half  _FakeBlinUp;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
                o.viewDir = normalize(WorldSpaceViewDir(v.vertex));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half NoV = DotClamped(i.viewDir, i.normal);
                half NdotL = DotClamped(_WorldSpaceLightPos0, i.normal);
                half3 ambient = ShadeSH9(half4(i.normal, 1));
                half3 rimH = 0;
                #if defined (EXTRA_RIM)
                    rimH = smoothstep( _FakeBlinLow - 0.01, _FakeBlinUp + 0.01, (NoV) + _RimAmount ) * _FakeBlinCol.rgb;
                #endif

                half3 baseLight = NdotL * _LightColor0 * _NdotLMul + ambient + (1 - NoV) * _Fresnel + rimH;

                fixed3 baseCol = tex2D(_MainTex, i.uv.xy);
                fixed4 col;

                col.rgb = baseCol * baseLight;
                col.a = 1;
                return col;
            }
            ENDCG
        }
    }
}
