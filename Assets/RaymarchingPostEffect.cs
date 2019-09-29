using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RaymarchingPostEffect : MonoBehaviour {
    public Material rayMarchMaterial;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    public void OnRenderImage(RenderTexture source, RenderTexture destination) {
        Graphics.Blit(source, destination, rayMarchMaterial);
    }
}
