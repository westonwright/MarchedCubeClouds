using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Player : MonoBehaviour
{
    public ComputeShader densityShader;

    private float currentDensityValue;

    private DensityGenerator densityGenerator;

    void Start()
    {
        densityGenerator = FindObjectOfType<DensityGenerator>();
    }

    void Update()
    {
        currentDensityValue = densityGenerator.CalculateSinglePoint(transform.position);
        //if currentDensityValue is greater than the surface level, the player is in a cloud
    }
}
