using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DensityGenerator : MonoBehaviour
{
    public ComputeShader densityShader;

    public float surfaceLevel = .1f;
    public int octaves = 1;
    public float noiseScale = 1;

    public float cloudsGradFloor = 0f;
    public float cloudsGradCeil = 50f;
    public float cutoffGradFloor = 0f;
    public float cutoffGradCeil = 50f;

    public float ambientOcclusionDistance = 500;

    private float timePassed = 0;
    private ComputeBuffer pointValsBuffer;
    private ComputeBuffer triangleBuffer;
    private ComputeBuffer triCountBuffer;

    private MeshFilter meshFilter;
    private Mesh mesh;

    private Triangle[] tris;

    private Vector3[] vertices;
    private Vector3[] normals;
    private Color[] colors;
    private int[] meshTriangles;

    //PointVisualizer pointVisualizer;

    const int threadGroupSize = 8;
    int numThreadsPerAxis;

    private void Start()
    {
        //pointVisualizer = FindObjectOfType<PointVisualizer>();
    }
    private void Update()
    {
        timePassed += Time.deltaTime;
    }

    public void CalculatePoints(Chunk chunk)
    {
        CreateBuffers(chunk);

        numThreadsPerAxis = Mathf.CeilToInt(chunk.pointsPerAxis / (float)threadGroupSize);

        pointValsBuffer.SetData(chunk.points);
        densityShader.SetBuffer(0, "pointValues", pointValsBuffer);
        densityShader.SetFloat("surfaceLevel", surfaceLevel);
        densityShader.SetFloat("ambientOcclusionDistance", ambientOcclusionDistance);
        densityShader.SetInt("numPointsPerAxis", chunk.pointsPerAxis);
        densityShader.SetFloat("chunkSize", chunk.size);
        densityShader.SetFloats("chunkSection", new float[] { chunk.section.x, chunk.section.y, chunk.section.z });
        densityShader.SetInt("octaves", octaves);
        densityShader.SetFloat("noiseScale", noiseScale);
        densityShader.SetFloat("cloudsGradFloor", cloudsGradFloor);
        densityShader.SetFloat("cloudsGradCeil", cloudsGradCeil);
        densityShader.SetFloat("cutoffGradFloor", cutoffGradFloor);
        densityShader.SetFloat("cutoffGradCeil", cutoffGradCeil);
        densityShader.SetFloat("timePassed", timePassed);

        densityShader.Dispatch(0, numThreadsPerAxis, numThreadsPerAxis, numThreadsPerAxis);
        //pointValsBuffer.GetData(chunk.points, 0, 0, chunk.points.Length);

        int numVoxelsPerAxis = chunk.pointsPerAxis - 1;
        numThreadsPerAxis = Mathf.CeilToInt(numVoxelsPerAxis / (float)threadGroupSize);

        //pointValsBuffer.GetData(chunk.points);
        //pointValsBuffer.SetData(chunk.points);
        triangleBuffer.SetCounterValue(0);
        densityShader.SetBuffer(1, "pointValues", pointValsBuffer);
        densityShader.SetBuffer(1, "triangles", triangleBuffer);

        densityShader.Dispatch(1, numThreadsPerAxis, numThreadsPerAxis, numThreadsPerAxis);

        // Get number of triangles in the triangle buffer
        ComputeBuffer.CopyCount(triangleBuffer, triCountBuffer, 0);
        int[] triCountArray = { 0 };
        triCountBuffer.GetData(triCountArray);
        int numTris = triCountArray[0];
        // Get triangle data from shader
        tris = new Triangle[numTris];
        //tris = new Triangle[5000000];
        triangleBuffer.GetData(tris, 0, 0, numTris);

        meshFilter = chunk.chunkObject.GetComponent<MeshFilter>(); ;
        mesh = meshFilter.mesh ?? new Mesh();
        mesh.Clear();

        vertices = new Vector3[numTris * 3];
        normals = new Vector3[numTris * 3];
        colors = new Color[numTris * 3];
        meshTriangles = new int[numTris * 3];

        for (int i = 0; i < numTris; i++)
        {
            for (int j = 0; j < 3; j++)
            {
                meshTriangles[i * 3 + j] = i * 3 + j;
                vertices[i * 3 + j] = tris[i][j];
                normals[i * 3 + j] = tris[i][j + 3];
                Vector3 colVal = tris[i][j + 6];
                colors[i * 3 + j] = new Color(colVal.x, colVal.y, colVal.z);
            }
        }
        mesh.vertices = vertices;
        mesh.triangles = meshTriangles;
        mesh.normals = normals;
        mesh.colors = colors;
        meshFilter.mesh = mesh;


        ReleaseBuffers();

        if (!Application.isPlaying)
        {
            ReleaseBuffers();
        }
    }

    void CreateBuffers(Chunk chunk)
    {
        int numVoxelsPerAxis = chunk.pointsPerAxis - 1;
        int numVoxels = numVoxelsPerAxis * numVoxelsPerAxis * numVoxelsPerAxis;
        int maxTriangleCount = numVoxels * 5;

        triangleBuffer = new ComputeBuffer(maxTriangleCount, sizeof(float) * 3 * 9, ComputeBufferType.Append);
        pointValsBuffer = new ComputeBuffer(chunk.points.Length, sizeof(float) * 4);
        triCountBuffer = new ComputeBuffer(1, sizeof(int), ComputeBufferType.Raw);
    }

    void ReleaseBuffers()
    {
        if (triangleBuffer != null)
        {
            triangleBuffer.Release();
            pointValsBuffer.Release();
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
        public Vector3 c0;
        public Vector3 c1;
        public Vector3 c2;

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
                    case 5:
                        return n2;
                    case 6:
                        return c0;
                    case 7:
                        return c1;
                    default:
                        return c2;
                }
            }
        }
    }
}
