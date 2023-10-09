Shader "Unlit/GrassShader"
{
    Properties
    {
        [Toggle(WITH_TEX)]
        _WithTex ("Switch to simulate with texture", Float) = 0

        _WindTex ("Texture", 2D) = "white" {}
        _WindParameters("Wind params (xy is xz)", vector) = (1,1,1,1)

        _WavingSpeed("Waving Speed", float) = 1.0
        _WavingAmplitude("Waving Amplitude", float) = 1.0

        _Color("Color", Color) = (1, 1, 1, 1)
        _Radius("Object radius", Range(0,10)) = 1
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque" 
            "DisableBatching" = "True"
        }
        Cull Off
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma shader_feature WITH_TEX

            #include "UnityCG.cginc"

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
                float2 samplePos : TEXCOORD1;
            };

            sampler2D _WindTex;
            float4 _WindTex_ST;
            float4 _Color;
            half4 _WindParameters;

            half _WavingSpeed;
            half _WavingAmplitude;

            uniform float3 _Positions[100];
            uniform float _NumOfObjects;

            float _Radius;

            v2f vert (appdata v)
            {
                float4 rawVert = v.vertex;
                v2f o;
                //o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal); // world space normal
                //get world position
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                //Normalize world pos -- set wind wave interval
                o.samplePos = worldPos.xz / _WindParameters.zw;
                o.samplePos += _Time.x * _WindParameters.xy;
                //sample windPos from tex
                float windSample = tex2Dlod(_WindTex, float4(o.samplePos, 0, 0));
                //speed also dependent on vertex height
                float heightFactor = v.vertex.y > 0.3;
                heightFactor =  heightFactor * pow(v.vertex.y, heightFactor);

                //Waving speed is just a tex sampling multiplier
                #ifdef WITH_TEX
                    rawVert.z += sin(_WavingSpeed*windSample)*_WavingAmplitude * heightFactor;
                    rawVert.x += cos(_WavingSpeed*windSample)*_WavingAmplitude * heightFactor;
                #else
                    rawVert.z += sin(o.samplePos.y)*_WavingAmplitude * heightFactor;
                    rawVert.x += cos(o.samplePos.x)*_WavingAmplitude * heightFactor;
                #endif

                for (int i = 0; i < _NumOfObjects; i++)
                {
                    //distance between objects pos and world position of vertex
                    float3 dist = distance(_Positions[i], worldPos);
                    float3 radius = 1 - saturate(dist/_Radius);
                    float3 displSphere = worldPos - _Positions[i];
                    displSphere *= radius;
                    rawVert.xz += 5;
                    //rawVert.xz += clamp(displSphere.xz * step(0.3, rawVert.y), -_WavingAmplitude*100,_WavingAmplitude*100);
                }
                o.vertex = UnityObjectToClipPos(rawVert);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return float4(_Color.rgb, 1.0);
               // return float4(_Positions[0].x, 0, 0, 1.0);
               //return float4(_NumOfObjects, 0, 0, 1.0);
            }
            ENDCG
        }
    }
}
