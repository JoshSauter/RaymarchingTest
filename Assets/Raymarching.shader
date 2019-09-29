// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/Raymarching"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f
            {
                float4 clipPos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            v2f vert (appdata_full v) {
                v2f o;
                o.clipPos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            #define MAX_STEPS 50
            
            fixed hash( fixed n ) { return frac(sin(n)*753.5453123); }
            fixed4 noised( in fixed3 x )
            {
                fixed3 p = floor(x);
                fixed3 w = frac(x);
                fixed3 u = w*w*(3.0-2.0*w);
                fixed3 du = 6.0*w*(1.0-w);
                
                fixed n = p.x + p.y*157.0 + 113.0*p.z;
                
                fixed a = hash(n+  0.0);
                fixed b = hash(n+  1.0);
                fixed c = hash(n+157.0);
                fixed d = hash(n+158.0);
                fixed e = hash(n+113.0);
                fixed f = hash(n+114.0);
                fixed g = hash(n+270.0);
                fixed h = hash(n+271.0);
                
                fixed k0 =   a;
                fixed k1 =   b - a;
                fixed k2 =   c - a;
                fixed k3 =   e - a;
                fixed k4 =   a - b - c + d;
                fixed k5 =   a - c - e + g;
                fixed k6 =   a - b - e + f;
                fixed k7 = - a + b + c - d + e - f - g + h;

                return fixed4( k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z, 
                             du * (fixed3(k1,k2,k3) + u.yzx*fixed3(k4,k5,k6) + u.zxy*fixed3(k6,k4,k5) + k7*u.yzx*u.zxy ));
            }
            
            float3 repeat(float3 pos, float3 repetition) {
                return fmod(abs(pos), repetition) - 0.5*repetition;
            }
            
            float3 repeatRegular(float3 pos, float regularRepetition) {
                return repeat(pos, float3(regularRepetition, regularRepetition, regularRepetition));
            }
            
            float boxSDF(float3 pos, float3 bounds) {
                float3 diff = abs(pos) - bounds;
                return length(max(diff, 0.0)) + min(max(diff.x, max(diff.y, diff.z)), 0.0);
            }
            
            float sphereSDF(float3 pos, float radius) {
                return length(pos) - radius;
            }
            
            float unionSDF(float p1, float p2) {
                return min(p1, p2);
            }
            
            float intersectionSDF(float p1, float p2) {
                return max(p1, p2);
            }
            
            float diffSDF(float p1, float p2) {
                return max(-p2, p1);
            }
            
            float smoothIntersectionSDF( float d1, float d2, float k ) {
                float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
                return lerp( d2, d1, h ) + k*h*(1.0-h);
            }
            
            float worldSDF(in float3 pos) {
                //float sphere = sphereSDF(repeatRegular(pos, 96), (1 + 0.5 * _SinTime.z) * 56);
                //float outerSphere = sphereSDF(repeatRegular(pos * hash(pos.x + pos.y + pos.z), 96), (1 + 0.5 * _SinTime.z) * 56);
                float outerSphere = sphereSDF(repeatRegular(pos, 96), (1 + 0.5 * _SinTime.y) * 56);
                float innerSphere = sphereSDF(repeatRegular(pos, 96), (1 + 0.5 * _SinTime.y) * 40);
                float pathwayArea = boxSDF(pos + float3(0,6,0), float3(14,8,1000));
                float pathwayBlocks = boxSDF(repeat(pos - float3(0,7.5,0), float3(12,16,12)), float3(4,.5,4));
                float pathwayBlocksCutout = boxSDF(repeat(pos - float3(0,7.5,0), float3(12,16,12)), float3(3,1,3));
                float pathway = intersectionSDF(pathwayArea, diffSDF(pathwayBlocks, pathwayBlocksCutout));
                float sphere = unionSDF(pathwayArea, diffSDF(outerSphere, innerSphere));
                
                float size = 6;
                float3 repeatPos = repeatRegular(pos, size*2);
                float3 baseSize = float3(size,size,size);
                float width = 0.5;
                float bigBoxSDF = boxSDF(repeatPos, baseSize);
                float xBoxSDF = boxSDF(repeatPos, baseSize + width * float3(1,-1,-1));
                float yBoxSDF = boxSDF(repeatPos, baseSize + width * float3(-1,1,-1));
                float zBoxSDF = boxSDF(repeatPos, baseSize + width * float3(-1,-1,1));
                
                float3 repeatOffsetPos = repeatRegular(pos - size * float3(1,1,1), size*2);
                size = 1.5;
                baseSize = float3(size,size,size);
                width = .5;
                float cornerBoxSDF = boxSDF(repeatOffsetPos, baseSize);
                float xCornerBoxSDF = boxSDF(repeatOffsetPos, baseSize + width * float3(1,-1,-1));
                float yCornerBoxSDF = boxSDF(repeatOffsetPos, baseSize + width * float3(-1,1,-1));
                float zCornerBoxSDF = boxSDF(repeatOffsetPos, baseSize + width * float3(-1,-1,1));
                
                float repeatedCube = diffSDF(diffSDF(diffSDF(bigBoxSDF, xBoxSDF), yBoxSDF), zBoxSDF);
                float offsetRepeatedCube = diffSDF(diffSDF(diffSDF(cornerBoxSDF, xCornerBoxSDF), yCornerBoxSDF), zCornerBoxSDF);
                float cubes = unionSDF(repeatedCube, cornerBoxSDF);
                
                return unionSDF(smoothIntersectionSDF(cubes, sphere, .5), pathway);
            }

            fixed4 frag (v2f i) : SV_Target {
                float3 viewDirection = normalize(i.worldPos - _WorldSpaceCameraPos);
                float depth = 0;
                float end = 400 + depth;
                for (int x = 0; x < MAX_STEPS && depth < end; x++) {
                    float3 position = i.worldPos + depth * viewDirection;
                    float sdfValue = worldSDF(position);
                    if (sdfValue < .001) {
                        float col = 1.0 - (x / (float)MAX_STEPS);
                        //return col * normalize(noised(position/256));
                        //return col * fixed4(position.x,position.y,(-position.x - position.y) / 2.0,1);
                        return fixed4(col, col, col, 1);
                    }
                    
                    depth += sdfValue + .001;
                }
                
                return fixed4(0,0,0,0);
            }
            ENDCG
        }
    }
}
