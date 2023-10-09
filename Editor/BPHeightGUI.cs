using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class BPHeightGUI : ShaderGUI
{
    enum SourceForSmoothness
    {
        MetallicAlpha, AlbedoAlpha
    }
    private Material material;
    private MaterialEditor editor;
	private MaterialProperty[] properties;
    public override void OnGUI ( MaterialEditor editor, MaterialProperty[] properties) 
    {
        this.material = editor.target as Material;
        this.editor = editor;
		this.properties = properties;
        DrawMainMaps();
        EditorGUI.indentLevel += 2; 
        DrawSmoothnes();
        EditorGUI.indentLevel -= 2;
        DrawNormalMap();
        DrawAdditionalOptions(); 
    }

    void DrawMainMaps()
    {
        GUILayout.Label("Main Maps", EditorStyles.boldLabel);
        DrawAlbedo();
        DrawMetallicMap();
    }

    void DrawAlbedo()
    {
        MaterialProperty albedoTex = FindProperty("_MainTex", properties);
        MaterialProperty tintColor = FindProperty("_Tint", properties);
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(new GUIContent(albedoTex.displayName), albedoTex, tintColor);
        if (EditorGUI.EndChangeCheck())
        {
            SetKeyword("_ALBEDO_MAP", albedoTex.textureValue);
        }
    }

    void DrawMetallicMap()
    {
        MaterialProperty metallicMap = FindProperty("_MetallicMap", properties);
        MaterialProperty metallicVal = FindProperty("_Metallic", properties);
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(new GUIContent("Metallic"), metallicMap, metallicMap.textureValue ? null : metallicVal);
        if (EditorGUI.EndChangeCheck())
        {
            SetKeyword("_METALLIC_MAP", metallicMap.textureValue);
        }
    }

    void DrawSmoothnes()
    {
        MaterialProperty smoothVal = FindProperty("_Smoothness", properties);
        editor.ShaderProperty(smoothVal, smoothVal.displayName);
        EditorGUI.indentLevel += 1;
        SourceForSmoothness src = SourceForSmoothness.MetallicAlpha;
        if (material.IsKeywordEnabled("_SMOOTHNESS_ALBEDO"))
        {
            src = SourceForSmoothness.AlbedoAlpha;
        }
        EditorGUI.BeginChangeCheck();
        src = (SourceForSmoothness)EditorGUILayout.EnumPopup("Source", src);
        if (EditorGUI.EndChangeCheck()) 
        {
            SetKeyword("_SMOOTHNESS_ALBEDO", src == SourceForSmoothness.AlbedoAlpha);
        }
        EditorGUI.indentLevel -= 1;
    }

    void DrawNormalMap()
    {
        MaterialProperty normalTex = FindProperty("_NormalMap" , properties);
        MaterialProperty extraBump = FindProperty("_Bumpiness" , properties);
        GUIContent normalLabel = new GUIContent(normalTex.displayName, normalTex.displayName);
        editor.TexturePropertySingleLine(normalLabel, normalTex, normalTex.textureValue ? extraBump : null );
    }

    void DrawAdditionalOptions()
    {
        GUILayout.Label("Additional Options", EditorStyles.boldLabel);
        MaterialProperty baseRefl = FindProperty("_BaseRef", properties);
        editor.ShaderProperty(baseRefl, baseRefl.displayName);
    }

    void SetKeyword (string keyword, bool state) 
    {
        if (state) 
        {
            material.EnableKeyword(keyword);
        }
        else 
        {
            material.DisableKeyword(keyword);
        }
    }
}
