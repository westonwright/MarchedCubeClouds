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

    public Vector3 noiseTimeOffsets;
    private float timePassed = 0;
    private ComputeBuffer pointValsBuffer;
    private ComputeBuffer pointNormsBuffer;
    private ComputeBuffer triangleBuffer;
    private ComputeBuffer triCountBuffer;
    private ComputeBuffer singleValueBuffer;

    private MeshFilter meshFilter;
    private Mesh mesh;

    private Vector4[] emptyPointValLengthArray;
    private Vector3[] emptyPointNormLengthArray;

    private Triangle[] tris;

    private Vector3[] vertices;
    private Vector3[] normals;
    private Color[] colors;
    private int[] meshTriangles;

    //PointVisualizer pointVisualizer;

    const int threadGroupSize = 8;
    int numThreadsPerAxis;
    int numPoints;
    int numVoxelsPerAxis;
    int numVoxels;
    int maxTriangleCount;

    private void Start()
    {
        //pointVisualizer = FindObjectOfType<PointVisualizer>();
    }
    private void Update()
    {
        //timePassed += Time.deltaTime;
        timePassed = 0;
    }

    public void CalculatePoints(ChunkData chunk)
    {
        CreateBuffers(chunk);

        numThreadsPerAxis = Mathf.CeilToInt(chunk.pointsPerAxis / (float)threadGroupSize);

        densityShader.SetInt("octaves", octaves);
        densityShader.SetFloat("noiseScale", noiseScale);
        densityShader.SetFloats("noiseTimeOffsets", new float[] { noiseTimeOffsets.x, noiseTimeOffsets.y, noiseTimeOffsets.z });
        densityShader.SetFloat("cloudsGradFloor", cloudsGradFloor);
        densityShader.SetFloat("cloudsGradCeil", cloudsGradCeil);
        densityShader.SetFloat("cutoffGradFloor", cutoffGradFloor);
        densityShader.SetFloat("cutoffGradCeil", cutoffGradCeil);
        densityShader.SetFloat("surfaceLevel", surfaceLevel);
        densityShader.SetFloat("ambientOcclusionDistance", ambientOcclusionDistance);

        emptyPointValLengthArray = new Vector4[numPoints];
        pointValsBuffer.SetData(emptyPointValLengthArray);

        densityShader.SetBuffer(0, "pointValues", pointValsBuffer);
        densityShader.SetInt("pointsPerAxis", chunk.pointsPerAxis);
        densityShader.SetFloat("chunkSize", chunk.size);
        densityShader.SetFloats("chunkSection", new float[] { chunk.section.x, chunk.section.y, chunk.section.z });

        densityShader.SetFloat("timePassed", timePassed);

        densityShader.Dispatch(0, numThreadsPerAxis, numThreadsPerAxis, numThreadsPerAxis);

        emptyPointNormLengthArray = new Vector3[numPoints];
        pointNormsBuffer.SetData(emptyPointNormLengthArray);

        densityShader.SetBuffer(1, "pointValues", pointValsBuffer);
        densityShader.SetBuffer(1, "pointNormals", pointNormsBuffer);

        densityShader.Dispatch(1, numThreadsPerAxis, numThreadsPerAxis, numThreadsPerAxis);

        numThreadsPerAxis = Mathf.CeilToInt(numVoxelsPerAxis / (float)threadGroupSize);

        triangleBuffer.SetCounterValue(0);
        densityShader.SetBuffer(2, "pointValues", pointValsBuffer);
        densityShader.SetBuffer(2, "pointNormals", pointNormsBuffer);
        densityShader.SetBuffer(2, "triangles", triangleBuffer);

        densityShader.Dispatch(2, numThreadsPerAxis, numThreadsPerAxis, numThreadsPerAxis);

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

    void CreateBuffers(ChunkData chunk)
    {
        numPoints = chunk.pointsPerAxis * chunk.pointsPerAxis * chunk.pointsPerAxis;
        numVoxelsPerAxis = chunk.pointsPerAxis - 1;
        numVoxels = numVoxelsPerAxis * numVoxelsPerAxis * numVoxelsPerAxis;
        maxTriangleCount = numVoxels * 5;

        triangleBuffer = new ComputeBuffer(maxTriangleCount, sizeof(float) * 3 * 9, ComputeBufferType.Append);
        pointValsBuffer = new ComputeBuffer(numPoints, sizeof(float) * 4);
        pointNormsBuffer = new ComputeBuffer(numPoints, sizeof(float) * 3);
        triCountBuffer = new ComputeBuffer(1, sizeof(int), ComputeBufferType.Raw);
    }

    void ReleaseBuffers()
    {
        if (triangleBuffer != null)
        {
            triangleBuffer.Release();
            pointValsBuffer.Release();
            pointNormsBuffer.Release();
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

    public float CalculateSinglePoint(Vector3 pointPosition)
    {
        singleValueBuffer = new ComputeBuffer(1, sizeof(float), ComputeBufferType.Append);
        singleValueBuffer.SetCounterValue(0);

        densityShader.SetFloats("singleValuePosition", new float[] { pointPosition.x, pointPosition.y, pointPosition.z });
        densityShader.SetBuffer(3, "singleValue", singleValueBuffer);

        densityShader.Dispatch(3, 1, 1, 1);

        float[] singleValueArray = new float[1];
        singleValueBuffer.GetData(singleValueArray, 0, 0, 1);

        singleValueBuffer.Release();

        return singleValueArray[0];
    }
}
