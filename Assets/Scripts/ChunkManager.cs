using System.Collections;
using System.Collections.Generic;
using System.Security.Cryptography;
using UnityEngine;

public class ChunkManager : MonoBehaviour
{
    public int pointsPerAxis = 10;
    public int renderDistance = 100;
    public int falloffLevels = 4;
    public int chunkSize = 25;
    public int chunkFloor = 0;
    public int chunkCeil = 100;

    public GameObject chunkPrefab;

    private List<Chunk> chunks = new List<Chunk>();
    public GameObject player;
    private Vector3 playerPosition;

    private MeshGenerator meshGenerator;
    private DensityGenerator densityGenerator;

    private void Start()
    {
        densityGenerator = FindObjectOfType<DensityGenerator>();
        meshGenerator = FindObjectOfType<MeshGenerator>();
    }

    private void Update()
    {
        playerPosition = player.transform.position;
        Vector3Int playerChunkPosition = new Vector3Int(Mathf.FloorToInt((playerPosition.x / chunkSize)), Mathf.FloorToInt((playerPosition.y / chunkSize)), Mathf.FloorToInt((int)(playerPosition.z / chunkSize))) * chunkSize;
        List<Vector3> newSections = new List<Vector3>();
        for (float z = -renderDistance + playerChunkPosition.z; z < renderDistance; z += (float)chunkSize)
        {
            for (float y = -renderDistance + playerChunkPosition.y; y < renderDistance; y += (float)chunkSize)
            {
                for (float x = -renderDistance + playerChunkPosition.x; x < renderDistance; x += (float)chunkSize)
                {
                    if(y > chunkFloor && y < chunkCeil)
                    {
                        Vector3 sectionPosition = new Vector3(x, y, z);
                        if (Vector3.Distance(sectionPosition, playerPosition) < renderDistance)
                        {
                            newSections.Add(sectionPosition);
                        }
                    }
                }
            }
        }

        List<Chunk> chunksToDelete = new List<Chunk>();
        foreach(Chunk chunk in chunks)
        {
            if(newSections.IndexOf(chunk.section) < 0)
            {
                chunksToDelete.Add(chunk);
                continue;
            }
        }
        DeleteChunks(chunksToDelete.ToArray());

        List<Vector3> sectionsToAdd = new List<Vector3>();
        foreach(Vector3 section in newSections)
        {
            if(!chunks.Exists(x => x.section == section))
            {
                sectionsToAdd.Add(section);
            }
        }
        CreateChunks(sectionsToAdd.ToArray());

        CheckChunks();

        RefreshChunks();
    }

    private void DeleteChunks(Chunk[] deleteChunks)
    {
        foreach(Chunk chunk in deleteChunks)
        {
            Destroy(chunk.chunkObject);
            chunks.Remove(chunk);
        }
    }

    private void CreateChunks(Vector3[] addSections)
    {
        foreach(Vector3 section in addSections)
        {
            Chunk newChunk = new Chunk();
            newChunk.chunkObject = Instantiate(chunkPrefab, transform);
            //newChunk.chunkObject.transform.position = section;
            newChunk.section = section;
            //newChunk.size = chunkSize;
            chunks.Add(newChunk);
        }
    }

    private void CheckChunks()
    {
        foreach(Chunk chunk in chunks)
        {
            float chunkDistance = Vector3.Distance(chunk.section, playerPosition);
            int currentQualityDivider = Mathf.CeilToInt(chunkDistance / (renderDistance / falloffLevels));
            currentQualityDivider = currentQualityDivider == 0 ? 1 : currentQualityDivider;
            if (chunk.qualityDivider != currentQualityDivider)
            {
                UpdateChunk(chunk, currentQualityDivider);
            }
        }
    }

    private void UpdateChunk(Chunk chunk, int qualityDivider)
    {
        chunk.qualityDivider = qualityDivider;
        int basePoints = Mathf.FloorToInt(pointsPerAxis / qualityDivider);
        chunk.pointsPerAxis = basePoints + 2;
        chunk.baseSize = chunkSize;
        //chunk.size = chunkSize * ((.5f + (1f / basePoints)) / .5f);
        chunk.size = chunkSize;
        chunk.points = new Vector4[chunk.pointsPerAxis * chunk.pointsPerAxis * chunk.pointsPerAxis];
    }

    private void RefreshChunks()
    {
        foreach(Chunk chunk in chunks)
        {
            densityGenerator.CalculatePoints(chunk);
            //meshGenerator.DrawChunk(chunk);
        }
    }

    void OnDrawGizmos()
    {
        Gizmos.color = Color.white;
        foreach (var chunk in chunks)
        {
            //Gizmos.color = new Color(1, 1, 1, .5f);
            //Gizmos.DrawWireCube(chunk.section, Vector3.one * (chunk.size / 2));
            //Gizmos.DrawWireCube(chunk.section, Vector3.one * (chunk.size));
        }
    }
}

public class Chunk
{
    //render quality counts up as it goes down in quality. Equals 0 if chunk isn't rendering.
    public int qualityDivider = 0;
    public int pointsPerAxis;
    public float size;
    public float baseSize;
    public Vector4[] points;
    public GameObject chunkObject;
    public Vector3 section;
}