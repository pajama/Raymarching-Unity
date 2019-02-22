// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "Unlit/VolumetricSphere"
{
    Properties
    {
    _Radius ("Radius", float) = 1
    _Centre ("Centre", vector) = (0,0,0)
    _Steps ("Steps", int) = 64
    _MinDistance ("Min Distance", float) = .01
    }
    SubShader
    {

        Tags {"Queue"="Transparent" "RenderType"="Transparent" }
        LOD 100

        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float3 _Centre = 0;
            float _Radius = 2;
            int _Steps;
            float _MinDistance;



            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION; //clip space
                float3 wPos : TEXCOORD1; //world space
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            float sphereDistance (float3 p)
            {
                return distance(p,_Centre) - _Radius;
            }

            fixed4 rayMarch(float3 position, float3 direction)
            {
                for(int i=0; i<_Steps; i++){
                    float distance = sphereDistance(position);
                    if(distance < _MinDistance){
                        float depth = i /(float)_Steps;
                        return fixed4(depth,depth,depth,1.);
                    }
                    position += distance * direction;
                }
                return 0;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPosition = i.wPos;
                float3 viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);

                fixed4 pixel = rayMarch(worldPosition, viewDirection);
                return pixel;
    
            }
            ENDCG
        }
    }
}
