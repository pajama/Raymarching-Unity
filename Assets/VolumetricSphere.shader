// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "Unlit/VolumetricSphere"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
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
            #include "Lighting.cginc"

            sampler2D _MainTex;
            float3 _Centre = 0;
            float _Radius = 2;
            int _Steps;
            float _MinDistance;
            float4 _Color;

            fixed4 simpleLambert (fixed3 normal) {
                fixed3 lightDir = _WorldSpaceLightPos0.xyz;	// Light direction
                fixed3 lightCol = _LightColor0.rgb;		// Light color

                fixed NdotL = max(dot(normal, lightDir),0);
                fixed4 c;
                c.rgb = _Color * lightCol * NdotL;
                c.a = 1;
                return c;
            }

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

            float map (float3 p)
            {
                return distance(p,_Centre) - _Radius;
            }

            float3 normal (float3 p)
            {
                const float eps = 0.01;
                return normalize
                (
                    float3( 
                        map(p + float3(eps, 0, 0) ) - map(p - float3(eps, 0, 0)),
                        map(p + float3(0, eps, 0) ) - map(p - float3(0, eps, 0)),
                        map(p + float3(0, 0, eps) ) - map(p - float3(0, 0, eps))
                    )
                );
            }

            fixed4 renderSurface(float3 p)
            {
                float3 n = normal(p);
                return simpleLambert(n);
            }

            fixed4 rayMarch(float3 position, float3 direction)
            {
                for(int i=0; i<_Steps; i++){
                    float distance = map(position);
                    if(distance < _MinDistance){
                        return renderSurface(position);
                    }
                    position += distance * direction;
                }
                return 1;
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
