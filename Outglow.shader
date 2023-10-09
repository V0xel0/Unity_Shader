Shader "Outglow"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _BumpMap ("Bumpmap", 2D) = "bump" {}
        _Color ("Albedo TintColor", Color) = (1,1,1,1)
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _RimVec("Fresnel vector (xyz)", vector) = (1,0,0,0)
        _FresnelMul("Fresnel multiplier", Range(0.0, 5.0)) = 0.71
        _FresnelCol ("Fresnel color", color) = (0.019, 0.63, 0.23, 1.0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows 
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _BumpMap;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_BumpMap;
            float3 viewDir;
        };

        half   _Glossiness;
        half   _Metallic  ;
        fixed4 _Color     ;

        fixed4 _FresnelCol;
        half4 _RimVec;
        half _FresnelMul;

        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Normal = UnpackNormal (tex2D (_BumpMap, IN.uv_BumpMap));
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;

            half NoV = 1 - DotClamped(o.Normal, IN.viewDir);
            half viewBias = saturate(DotClamped(IN.viewDir, _RimVec)); //cutting _RimVec is a fresnel cutout
            o.Emission =  NoV * _FresnelCol * _FresnelMul * viewBias;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
