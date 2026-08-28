Shader "MonsterPlanet/GuardianSuit"
{
    Properties
    {
        _Color ("Silver Fabric", Color) = (0.48,0.54,0.64,1)
        _PrimaryColor ("Hero Color", Color) = (0.02,0.36,0.95,1)
        _SecondaryColor ("Accent Color", Color) = (0.68,0.88,1,1)
        _MainTex ("Technical Weave", 2D) = "gray" {}
        _EmissionColor ("Energy", Color) = (0.02,0.4,1,1)
        _RimColor ("Rim", Color) = (0.2,0.72,1,1)
        _RimPower ("Rim Power", Range(1,8)) = 3.2
        _PatternVariant ("Pattern Variant", Range(0,2)) = 0
        _DetailStrength ("Fabric Detail", Range(0,1)) = 0.82
        _EnergyStrength ("Energy Strength", Range(0,2)) = 1
        _Metallic ("Metallic", Range(0,1)) = 0.68
        _Glossiness ("Smoothness", Range(0,1)) = 0.72
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 220
        Cull Back

        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed4 _PrimaryColor;
            fixed4 _SecondaryColor;
            fixed4 _EmissionColor;
            fixed4 _RimColor;
            half _RimPower;
            half _PatternVariant;
            half _DetailStrength;
            half _EnergyStrength;
            half _Metallic;
            half _Glossiness;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                half3 worldNormal : TEXCOORD2;
                float3 modelPos : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.modelPos = v.vertex.xyz;
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                half3 normal = normalize(i.worldNormal);
                half3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                half3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                half ndl = saturate(dot(normal, lightDir));
                half steppedLight = smoothstep(0.02h, 0.62h, ndl);
                half shadow = SHADOW_ATTENUATION(i);

                // Costume panels are generated in model space. They stay crisp
                // while the bitmap provides only fine cloth/hex detail.
                float3 p = i.modelPos;
                half front = smoothstep(-0.18h, 0.12h, p.z);
                half torso = smoothstep(0.83h, 1.05h, p.y) * (1.0h - smoothstep(1.5h, 1.68h, p.y));
                half limbs = smoothstep(0.17h, 0.34h, abs(p.x));
                half boots = 1.0h - smoothstep(0.28h, 0.58h, p.y);
                half gloves = limbs * smoothstep(0.83h, 1.02h, p.y);
                half sideSuit = limbs * (0.46h + 0.54h * front);
                half commonMask = max(boots, gloves * 0.7h);

                // Each selectable guardian has its own readable silhouette pattern,
                // rather than being a simple palette swap of the same costume.
                half auroraWeight = 1.0h - step(0.5h, _PatternVariant);
                half novaWeight = step(0.5h, _PatternVariant) * (1.0h - step(1.5h, _PatternVariant));
                half solarWeight = step(1.5h, _PatternVariant);

                half vDistance = abs(abs(p.x) - saturate(1.58h - p.y) * 0.46h);
                half auroraV = (1.0h - smoothstep(0.025h, 0.085h, vDistance)) * torso * front;
                half auroraPattern = max(auroraV, sideSuit);

                half novaDiagonal = p.x + (p.y - 1.22h) * 0.36h;
                half novaBands = (1.0h - smoothstep(0.045h, 0.105h, abs(abs(novaDiagonal) - 0.22h))) * torso * front;
                half novaPattern = max(novaBands, sideSuit * (0.72h + 0.28h * step(0.0h, p.x)));

                half solarHeight = saturate((p.y - 0.86h) / 0.7h);
                half solarWidth = 0.075h + solarHeight * 0.22h;
                half solarRay = (1.0h - smoothstep(solarWidth, solarWidth + 0.065h, abs(p.x))) * torso * front;
                half solarShoulders = smoothstep(1.34h, 1.54h, p.y) * torso * front;
                half solarPattern = max(solarRay, max(solarShoulders, sideSuit * 0.58h));

                half heroPattern = auroraPattern * auroraWeight
                    + novaPattern * novaWeight
                    + solarPattern * solarWeight;
                half primaryMask = saturate(max(heroPattern, commonMask));

                half centerDistance = abs(p.x) + abs(p.y - 1.18h) * 0.28h;
                half centerPlate = (1.0h - smoothstep(0.12h, 0.25h, centerDistance)) * torso * front;
                half waist = (1.0h - smoothstep(0.025h, 0.065h, abs(p.y - 0.83h))) * front;
                half auroraAccent = max(centerPlate, waist);
                half novaCore = (1.0h - smoothstep(0.035h, 0.09h, abs(novaDiagonal))) * torso * front;
                half novaAccent = max(novaCore, waist * 0.78h);
                half solarCore = (1.0h - smoothstep(0.035h, 0.095h, abs(p.x))) * torso * front;
                half solarChevronDistance = abs(abs(p.x) - saturate(p.y - 0.91h) * 0.32h);
                half solarChevron = (1.0h - smoothstep(0.018h, 0.06h, solarChevronDistance)) * torso * front;
                half solarAccent = max(solarCore, max(solarChevron, waist));
                half accentMask = saturate(
                    auroraAccent * auroraWeight
                    + novaAccent * novaWeight
                    + solarAccent * solarWeight);

                fixed3 cloth = tex2D(_MainTex, i.uv).rgb;
                half weave = dot(cloth, half3(0.28h, 0.56h, 0.16h));
                half blueThread = saturate((cloth.b - cloth.r) * 3.0h);
                fixed3 albedo = lerp(_Color.rgb, _PrimaryColor.rgb, primaryMask);
                albedo = lerp(albedo, _SecondaryColor.rgb, accentMask * 0.72h);
                half fabricLighting = lerp(0.76h, 1.18h, saturate(weave * 2.8h));
                albedo *= lerp(1.0h, fabricLighting, _DetailStrength);

                half3 ambient = ShadeSH9(half4(normal, 1));
                half rim = pow(1.0h - saturate(dot(normal, viewDir)), _RimPower);
                half3 halfDir = normalize(lightDir + viewDir);
                half spec = pow(saturate(dot(normal, halfDir)), lerp(12.0h, 84.0h, _Glossiness));
                half3 lit = ambient + _LightColor0.rgb * steppedLight * lerp(0.5h, 1.0h, shadow);
                half3 color = albedo * lit;
                color += _RimColor.rgb * rim * (0.12h + _Metallic * 0.28h);
                color += _LightColor0.rgb * spec * (0.1h + _Metallic * 0.46h);
                color += _EmissionColor.rgb * (blueThread * 0.18h + accentMask * 0.035h) * _EnergyStrength;
                return fixed4(color, 1);
            }
            ENDCG
        }

        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
    Fallback "MonsterPlanet/Stylized"
}
