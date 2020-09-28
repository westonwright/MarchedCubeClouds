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

    private List<Vector3> currentSections = new List<Vector3>();
    private Vector3Int playerChunkPosition;

    public GameObject player;
    private Vector3 playerPosition;

    private void Start()
    {
    }

    private void Update()
    {
        playerPosition = player.transform.position;
        playerChunkPosition = new Vector3Int(Mathf.FloorToInt((playerPosition.x / chunkSize)), Mathf.FloorToInt((playerPosition.y / chunkSize)), Mathf.FloorToInt((int)(playerPosition.z / chunkSize))) * chunkSize;
        for (float z = -renderDistance + playerChunkPosition.z; z < renderDistance; z += chunkSize)
        {
            for (float y = -renderDistance + playerChunkPosition.y; y < renderDistance; y += chunkSize)
            {
                for (float x = -renderDistance + playerChunkPosition.x; x < renderDistance; x += chunkSize)
                {
                    if(y > chunkFloor && y < chunkCeil)
                    {
                        Vector3 sectionPosition = new Vector3(x, y, z);
                        if (Vector3.Distance(sectionPosition, playerPosition) < renderDistance)
                        {
                            if(currentSections.IndexOf(sectionPosition) < 0)
                            {
                                currentSections.Add(sectionPosition);
                                CreateChunk(sectionPosition);
                            }
                        }
                    }
                }
            }
        }
    }

    private void CreateChunk(Vector3 section)
    {
        ChunkData newChunkData = new ChunkData();
        newChunkData.chunkObject = Instantiate(chunkPrefab, transform);
        newChunkData.section = section;
        newChunkData.size = chunkSize;

        Chunk newChunk = newChunkData.chunkObject.GetComponent<Chunk>();
        newChunk.chunkData = newChunkData;
        newChunk.chunkManager = this;
        newChunk.player = player.transform;
        newChunk.renderDistance = renderDistance;
        newChunk.falloffLevels = falloffLevels;
        newChunk.basePointsPerAxis = pointsPerAxis;

    }

    public void DeleteChunk(ChunkData deleteChunk)
    {
        currentSections.Remove(deleteChunk.section);
        Destroy(deleteChunk.chunkObject);
    }
}

public class ChunkData
{
    //render quality counts up as it goes down in quality. Equals 0 if chunk isn't rendering.
    public int pointsPerAxis;
    public int size;
    public GameObject chunkObject;
    public Vector3 section;
}