using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class TrackInteraction : MonoBehaviour
{
    public CustomRenderTexture tracksMap;
    public GameObject terrain;
    public Material paintTracks;
    private Material smoother;
    private RaycastHit hitOnGround;
    private int layerMask;
    public Transform pos;
    void Start()
    {
        layerMask = LayerMask.GetMask("Ground");
        smoother = terrain.GetComponent<MeshRenderer>().material; //shared instead material for edit mode
        tracksMap.Initialize();
    }

    void Update()
    {
        if (Physics.Raycast(pos.position, Vector3.down, out hitOnGround, 0.5f, layerMask))
        {
            paintTracks.SetVector("_Coords", new Vector4(hitOnGround.textureCoord.x, hitOnGround.textureCoord.y, 0 , 0));
            //Debug.Log(pos.position.x);
            //Debug.Log("Hit");
            //Debug.Log($" {hitOnGround.textureCoord.x},
            // CustomRenderTexture temp = CustomRenderTexture.GetTemporary(tracksMap.width, tracksMap.height, 0, CustomRenderTextureFormat.ARGB64 );
            // Graphics.Blit(tracksMap, temp);
            // Graphics.Blit(temp, tracksMap, paintTracks);
            // CustomRenderTexture.ReleaseTemporary(temp);
            tracksMap.Update();
        }
    }
}