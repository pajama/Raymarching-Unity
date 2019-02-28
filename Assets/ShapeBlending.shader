Shader "Raymarch/ShapeBlending"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Radius ("Radius", float) = 1
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
            #include "Sdfs.cginc"
            #include "RaymarchedLighting.cginc"

            sampler2D _MainTex;
            float3 _Centre = 0;
            float _Radius = 2;
            int _Steps;
            float _MinDistance;
            float4 _Color;
            float3 _ObjectPosition;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION; //clip space
                float3 wPos : TEXCOORD1; //world space
                float3 objectPos : CUSTOM;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.objectPos =  mul ( unity_ObjectToWorld, float4(0,0,0,1) ).xyz;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }
            
            float map (float3 p)
            {
                return sdf_blend(
                    sdf_box(p, 0, _Radius),
                    sdf_sphere(p, 0, _Radius),
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

            fixed4 rayMarch(float3 position, float3 direction, float3 center)
            {
                for(int i=0; i<_Steps; i++){
                    float distance = map(position-center);
                    if(distance < _MinDistance){
                        return renderSurface(position-center);
                    }
                    position += distance * direction;
                }
                return 0;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPosition = i.wPos;
                float3 viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);

                fixed4 pixel = rayMarch(worldPosition, viewDirection, i.objectPos);
                return pixel;
    
            }
            ENDCG
        }
    }
}
