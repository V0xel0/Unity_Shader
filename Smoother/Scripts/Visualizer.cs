using System.Collections;
using System.Collections.Generic;
using UnityEngine;
//Copy pasted from catlikecodng.com
//USE ONLY FOR DEBUGGING -- hide in inspector -> OnDrawGizmos will not be called
public class Visualizer : MonoBehaviour
{
    public float offset = 0.01f;
	public float scale = 0.1f;
    public bool drawNormals = false;
    public bool drawTangent = false;
    public bool drawBiTangent = false;
    void OnDrawGizmos() 
    {
        MeshFilter filter = GetComponent<MeshFilter>();
		if (filter) {
			Mesh mesh = filter.sharedMesh;
			if (mesh) {
				ShowTangentSpace(mesh);
			}
		}
    }

    void ShowTangentSpace (Mesh mesh) {
		Vector3[] vertices = mesh.vertices;
		Vector3[] normals = mesh.normals;
		Vector4[] tangents = mesh.tangents;
		for (int i = 0; i < vertices.Length; i++) {
			ShowTangentSpace(
				transform.TransformPoint(vertices[i]),
				transform.TransformDirection(normals[i]),
				transform.TransformDirection(tangents[i]),
				tangents[i].w
			);
		}
	}

	void ShowTangentSpace (Vector3 vertex, Vector3 normal, Vector3 tangent, float binormalSign) {
		vertex += normal * offset;
        if (drawNormals)
        {
		    Gizmos.color = Color.green;
		    Gizmos.DrawLine(vertex, vertex + normal * scale);
            
        }
        if (drawTangent)
        {
            Gizmos.color = Color.red;
		    Gizmos.DrawLine(vertex, vertex + tangent * scale);
        }
        if (drawBiTangent)
        {
            Vector3 binormal = Vector3.Cross(normal, tangent) * binormalSign;
		    Gizmos.color = Color.blue;
		    Gizmos.DrawLine(vertex, vertex + binormal * scale);
        }
	}
}
