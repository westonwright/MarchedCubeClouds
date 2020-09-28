/*
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MeshGenerator : MonoBehaviour
{
    const int threadGroupSize = 8;
    public ComputeShader shader;
    // Buffers
    ComputeBuffer triangleBuffer;
    ComputeBuffer pointsBuffer;
    ComputeBuffer triCountBuffer;

    private MeshFilter meshFilter;
    private Mesh mesh;

    private Triangle[] tris;

    private Vector3[] vertices;
    private Vector3[] normals;
    private int[] meshTriangles;

    public float surfaceLevel = .1f;

    private void Start()
    {
    }

    public void DrawChunk(Chunk chunk)
    {
        CreateBuffers(chunk);
        
        UpdateMesh(chunk);
        
        ReleaseBuffers();

        // Release buffers immediately in editor
        if (!Application.isPlaying)
        {
            ReleaseBuffers();
        }

    }
    public void UpdateMesh(Chunk chunk)
    {
        int numVoxelsPerAxis = chunk.pointsPerAxis - 1;
        int numThreadsPerAxis = Mathf.CeilToInt(numVoxelsPerAxis / (float)threadGroupSize);

        triangleBuffer.SetCounterValue(0);
        pointsBuffer.SetData(chunk.points);
        shader.SetBuffer(0, "points", pointsBuffer);
        shader.SetInt("pointsPerAxis", chunk.pointsPerAxis);

        shader.Dispatch(0, numThreadsPerAxis, numThreadsPerAxis, numThreadsPerAxis);

        // Get number of triangles in the triangle buffer
        ComputeBuffer.CopyCount(triangleBuffer, triCountBuffer, 0);
        int[] triCountArray = { 0 };
        triCountBuffer.GetData(triCountArray);
        int numTris = triCountArray[0];

        // Get triangle data from shader
        tris = new Triangle[numTris];
        triangleBuffer.GetData(tris, 0, 0, numTris);

        meshFilter = chunk.chunkObject.GetComponent<MeshFilter>(); ;
        mesh = meshFilter.mesh ?? new Mesh();
        mesh.Clear();

        vertices = new Vector3[numTris * 3];
        normals = new Vector3[numTris * 3];
        meshTriangles = new int[numTris * 3];

        for (int i = 0; i < numTris; i++)
        {
            for (int j = 0; j < 3; j++)
            {
                meshTriangles[i * 3 + j] = i * 3 + j;
                vertices[i * 3 + j] = tris[i][j];
                normals[i * 3 + j] = tris[i][j + 3];
            }
        }
        mesh.vertices = vertices;
        mesh.triangles = meshTriangles;
        mesh.normals = normals;
        meshFilter.mesh = mesh;
    }
    void CreateBuffers(Chunk chunk)
    {
        int numPoints = chunk.pointsPerAxis * chunk.pointsPerAxis * chunk.pointsPerAxis;
        int numVoxelsPerAxis = chunk.pointsPerAxis - 1;
        int numVoxels = numVoxelsPerAxis * numVoxelsPerAxis * numVoxelsPerAxis;
        int maxTriangleCount = numVoxels * 5;

        triangleBuffer = new ComputeBuffer(maxTriangleCount, sizeof(float) * 3 * 3, ComputeBufferType.Append);
        pointsBuffer = new ComputeBuffer(numPoints, sizeof(float) * 4);
        triCountBuffer = new ComputeBuffer(1, sizeof(int), ComputeBufferType.Raw);
    }

    void ReleaseBuffers()
    {
        if (triangleBuffer != null)
        {
            triangleBuffer.Release();
            pointsBuffer.Release();
            triCountBuffer.Release();
        }
    }
    struct Triangle
    {
#pragma warning disable 649 // disable unassigned variable warning
        public Vector3 v0;
        public Vector3 v1;
        public Vector3 v2;
        public Vector3 n0;
        public Vector3 n1;
        public Vector3 n2;

        public Vector3 this[int i]
        {
            get
            {
                switch (i)
                {
                    case 0:
                        return v0;
                    case 1:
                        return v1;
                    case 2:
                        return v2;
                    case 3:
                        return n0;
                    case 4:
                        return n1;
                    default:
                        return n2;
                }
            }
        }
    }
}
*/
