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