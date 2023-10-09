Shader "Unlit/MultipleLights"
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
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags {
				"LightMode" = "ForwardBase"
			}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature CONSERVATION
            #pragma shader_feature REFLECTION
            #include "Assets/Includes/CGINCS/GouraudLightning.cginc"
            ENDCG
        }
        Pass
        {
            Tags {
				"LightMode" = "ForwardAdd"
			}
            Blend One One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature CONSERVATION
            #pragma shader_feature REFLECTION
            #include "Assets/Includes/CGINCS/GouraudLightning.cginc"
            ENDCG
        }
        // Pass
        // {
        //     CGPROGRAM
        //     #pragma vertex vert
        //     #pragma fragment frag
        //     #pragma shader_feature CONSERVATION
        //     #pragma shader_feature REFLECTION
        //     #include "GouraudLightning.cginc"
        //     ENDCG
        // }
       
    }
}
