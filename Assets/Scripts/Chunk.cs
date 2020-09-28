using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Chunk : MonoBehaviour
{
    [HideInInspector]
    public ChunkData chunkData;
    [HideInInspector]
    public ChunkManager chunkManager;
    [HideInInspector]
    public Transform player;
    [HideInInspector]
    public float renderDistance;
    [HideInInspector]
    public int falloffLevels;
    [HideInInspector]
    public int basePointsPerAxis;

    [HideInInspector]
    public bool refreshChunk = false;

    private DensityGenerator densityGenerator;

    private int qualityDivider = 0;
    private float chunkDistance;
    private int newQualityDivider;

    void Start()
    {
        densityGenerator = FindObjectOfType<DensityGenerator>();
    }

    void Update()
    {
        if (Vector3.Distance(chunkData.section, player.position) >= renderDistance)
        {
            chunkManager.DeleteChunk(chunkData);
        }

        chunkDistance = Vector3.Distance(chunkData.section, player.position);
        newQualityDivider = Mathf.CeilToInt(chunkDistance / (renderDistance / falloffLevels));
        newQualityDivider = newQualityDivider == 0 ? 1 : newQualityDivider;
        if (qualityDivider != newQualityDivider)
        {
            UpdateChunk();
        }

        if (refreshChunk)
        {
            densityGenerator.CalculatePoints(chunkData);
            refreshChunk = false;
        }
    }
    private void UpdateChunk()
    {
        refreshChunk = true;

        qualityDivider = newQualityDivider;
        chunkData.pointsPerAxis = Mathf.FloorToInt(basePointsPerAxis / qualityDivider) + 2;
    }


    void OnDrawGizmos()
    {
        //Gizmos.color = new Color(1, 1, 1, .25f);
        //Gizmos.DrawWireCube(chunkData.section, Vector3.one * (chunkData.size));
    }
}
