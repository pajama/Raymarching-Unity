Shader "Raymarch/VolumetricSphereLambert"
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
            
            float sdf_sphere (float3 p, float3 c, float r)
            {
                return distance(p,c) - r;
            }
            
            float sdf_box (float3 p, float3 c, float3 s)
            {
                float x = max
                (   p.x - c.x - float3(s.x / 2., 0, 0),
                    c.x - p.x - float3(s.x / 2., 0, 0)
                );
            
                float y = max
                (   p.y - c.y - float3(s.y / 2., 0, 0),
                    c.y - p.y - float3(s.y / 2., 0, 0)
                );
                
                float z = max
                (   p.z - c.z - float3(s.z / 2., 0, 0),
                    c.z - p.z - float3(s.z / 2., 0, 0)
                );
            
                float d = x;
                d = max(d,y);
                d = max(d,z);
                return d;
            }
            
            float sdf_blend(float d1, float d2, float a)
            {
                return a * d1 + (1 - a) * d2;
            }

            float map (float3 p)
            {
                return sdf_blend(
                    sdf_box(p, _Centre, _Radius),
                    sdf_sphere(p, _Centre, _Radius),
                    (_SinTime[3] + 1) / 2
                );              
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
