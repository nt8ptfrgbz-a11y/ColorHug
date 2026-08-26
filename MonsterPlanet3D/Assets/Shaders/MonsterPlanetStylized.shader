Shader "MonsterPlanet/Stylized"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _EmissionColor ("Emission", Color) = (0,0,0,0)
        _RimColor ("Rim", Color) = (0.15,0.45,1,1)
        _RimPower ("Rim Power", Range(1,8)) = 3
        _Metallic ("Metallic", Range(0,1)) = 0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Cull ("Cull", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 200
        Cull [_Cull]

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
            fixed4 _EmissionColor;
            fixed4 _RimColor;
            half _RimPower;
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
                SHADOW_COORDS(3)
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                half3 normal = normalize(i.worldNormal);
                half3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                half3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                half ndl = saturate(dot(normal, lightDir));
                half steppedLight = smoothstep(0.05, 0.55, ndl);
                half shadow = SHADOW_ATTENUATION(i);
                fixed4 albedo = tex2D(_MainTex, i.uv) * _Color;
                half3 ambient = ShadeSH9(half4(normal, 1));
                half rim = pow(1.0h - saturate(dot(normal, viewDir)), _RimPower);
                half3 halfDir = normalize(lightDir + viewDir);
                half spec = pow(saturate(dot(normal, halfDir)), lerp(8.0h, 64.0h, _Glossiness));
                half3 lit = ambient + _LightColor0.rgb * steppedLight * lerp(0.55h, 1.0h, shadow);
                half3 color = albedo.rgb * lit;
                color += _RimColor.rgb * rim * (0.12h + _Metallic * 0.22h);
                color += _LightColor0.rgb * spec * (0.08h + _Metallic * 0.38h);
                color += _EmissionColor.rgb;
                return fixed4(color, albedo.a);
            }
            ENDCG
        }

        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
    Fallback "Unlit/Texture"
}
