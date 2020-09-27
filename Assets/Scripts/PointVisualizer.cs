using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PointVisualizer : MonoBehaviour
{
    public GameObject pointObject;
    private GameObject[] pointObjects;

    public void CreatePoints(int length)
    {
        pointObjects = new GameObject[length];
        for (int i = 0; i < length; i++)
        {
            pointObjects[i] = Instantiate(pointObject, transform);
        }
    }

    public void SetPointObject(int index, Vector3 position, float noiseValue, float surfaceLevel)
    {
        if(noiseValue > surfaceLevel)
        {
            pointObjects[index].SetActive(true);
            pointObjects[index].transform.position = position;
            pointObjects[index].GetComponent<Renderer>().material.color = Color.Lerp(Color.black, Color.white, noiseValue / 1.4f + .5f);
            pointObjects[index].name = index.ToString();
        }
        else
        {
            pointObjects[index].SetActive(false);
        }
    }
}
