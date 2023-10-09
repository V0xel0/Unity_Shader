using System.Collections;
using System;
using System.Collections.Generic;
using UnityEngine;

public class GroundInteraction : MonoBehaviour
{
    public enum TexSize {_128 = 128, _256 = 256, _512 = 512, _1024 = 1024, _2048 = 2048};
    public Transform[] objectsTransforms = new Transform[2];
    public TexSize textureMapSize = TexSize._512;

    [Range(0.0f, 1.0f)] public float BrushStrength = 0.25f;
    [Range(1.0f, 40.0f)] public float BrushSize = 25.0f;
    [Range(0.9f, 1.15f)] public float DegenRegen = 1.0f;
    [Range(0.0f, 2.0f)] public float RayLength = 0.7f;


    public string GroundLayerName = "Ground";

    private CustomRenderTexture tracksMap;
    private RaycastHit hitOnGround;
    private int layerMask;
    private Vector4[] positions = new Vector4[2];
    private bool anyChange = false;
    private Material mapControlMat;
    private Material groundMaterial;
    private Collider selfCollider;

    void Start()
    {
        CreateMap();
        tracksMap.Initialize();
        groundMaterial = GetComponent<Renderer>().material;
        groundMaterial.SetTexture("_TrackMap", tracksMap);

        layerMask = LayerMask.GetMask(GroundLayerName);
        foreach (var obj in objectsTransforms)
        {
            obj.hasChanged = false;
        }
        selfCollider = GetComponent<Collider>();
    }

    void Update()
    {
        for (int i = 0; i < objectsTransforms.Length; i++)
        {
            if ( objectsTransforms[i].hasChanged && 
                Physics.Raycast(objectsTransforms[i].position, Vector3.down, out hitOnGround, RayLength, layerMask) &&
                selfCollider == hitOnGround.collider )
            {
                anyChange = true;
                positions[i] = new Vector4(hitOnGround.textureCoord.x, hitOnGround.textureCoord.y, 0 , 0); //sendig uv of mesh collider
                objectsTransforms[i].hasChanged = false; //Need to manually update the flag
                //Debug.Log($"x:{positions[i].x}, y:{positions[i].y}");
                //Debug.Log($"x2:{hitOnGround.textureCoord.x}, y2:{hitOnGround.textureCoord.y}");
            }
            else
            {
                positions[i] = new Vector4(-100,-100,0,0);
            }
        }
        if (anyChange)
        {
            mapControlMat.SetVectorArray("_Positions", positions);
            tracksMap.Update();
            anyChange = false;
            //Debug.Log("Call");
        }
        //Debug.Log(positions[0].x);
    }

    private void CreateMap()
    {
        if (!tracksMap)
        {
            tracksMap = new CustomRenderTexture((int)textureMapSize, (int)textureMapSize, RenderTextureFormat.R8);
            tracksMap.name += $"Map {this.name}";
            mapControlMat = new Material(Shader.Find("Unlit/TracksPainter"));
            mapControlMat.name += $"{this.name}";

            tracksMap.initializationSource = CustomRenderTextureInitializationSource.TextureAndColor;
            tracksMap.initializationMode = CustomRenderTextureUpdateMode.OnDemand;
            tracksMap.initializationColor = new Color(0,0,0,1);
            tracksMap.material = mapControlMat;
            tracksMap.updateMode = CustomRenderTextureUpdateMode.OnDemand;
        }
        mapControlMat.SetTexture("_Tex"       , tracksMap);
        mapControlMat.SetColor  ("_Color"     , Color.red);
        mapControlMat.SetFloat  ("_Strength"  , BrushStrength);
        mapControlMat.SetFloat  ("_Size"      , BrushSize);
        mapControlMat.SetFloat  ("_DegenRegen", DegenRegen);
    }
}