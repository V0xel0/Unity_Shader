Shader "Unlit/TracksPainter"
{
    Properties
    {
        [NoScaleOffset] _Tex("InputTex", 2D) = "white" {}
        [HideInInspector] _Color("Color", Color) = (1, 0, 0 , 1)
        [HideInInspector]_Strength("Strength", Range(0,1)) = 0.25
        [HideInInspector] _Size("Brush size", Range(1,40)) = 25
        [HideInInspector] _DegenRegen("Brush size", Range(0.9,1.15)) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
           CGPROGRAM
            #include "UnityCustomRenderTexture.cginc"
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag
            #pragma target 2.0

            uniform float4 _Positions[1];

            sampler2D _Tex;
            fixed4 _Color;
            half _Strength;
            half _Size;
            half _DegenRegen;

            fixed4 frag (v2f_customrendertexture IN) : COLOR
            {
                //First, sample itself to do addition
                float4 selfIn = tex2D(_Tex, IN.localTexcoord.xy);
                for (int i = 0; i < 1; i++)
                {
                    half draw = pow(saturate(1 - distance(IN.localTexcoord.xy, _Positions[i].xy)), 1000 / _Size);
                    half4 drawCol = _Color * draw * _Strength;
                    selfIn = saturate(selfIn + drawCol);
                }
                return saturate(selfIn) * _DegenRegen; //multiplier gives nice reg/degen effects while moving
            }
            ENDCG
        }
    }
}