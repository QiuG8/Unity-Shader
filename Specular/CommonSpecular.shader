// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "MyShader/Specular"
{
	Properties
	{
		_Color("Color",Color) = (1,1,1,1)
		_MainMap("Main Map",2D) = "white"{}
		_NormalMap("Normap Map",2D) = "bump"{}
		_Specular("Specular Color",Color) = (1,1,1,1)
		_Gloss("Gloss",Range(8,256)) = 20
	}
		SubShader
		{
			Tags{"RenderType"="Opaque" "Queue"="Geometry"}
			Pass
			{
				Tags{ "LightMode" = "ForwardBase" }
				CGPROGRAM
				#pragma multi_compile_fwdbase
				#pragma vertex vert
				#pragma fragment frag

				#include "Lighting.cginc"
				#include "UnityCG.cginc"
				#include "AutoLight.cginc"

				fixed4 _Color;
				sampler2D _MainMap;
				sampler2D _NormalMap;
				sampler2D _RampMap;
				float4 _MainMap_ST;
				float4 _NormalMap_ST;
				fixed4 _Specular;
				float _Gloss;

				struct a2v
				{
					float4 vertex:POSITION;
					float3 normal : NORMAL;
					float4 tangent:TANGENT;
					float4 texcoord:TEXCOORD0;
				};
				struct v2f
				{
					float4 pos:SV_POSITION;
					float2 uv:TEXCOORD0;
					float3 TangentLightDir:TEXCOORD1;
					float3 TangentViewDir:TEXCOORD2;
					float3 WorldPos:TEXCOORD3;
					SHADOW_COORDS(4)
				};
				
				v2f vert(a2v v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.texcoord, _MainMap);

					o.WorldPos = mul(unity_ObjectToWorld, v.vertex).xyz;	
					TANGENT_SPACE_ROTATION;
					o.TangentLightDir = mul(rotation,ObjSpaceLightDir(v.vertex));
					o.TangentViewDir = mul(rotation,ObjSpaceViewDir(v.vertex));
					TRANSFER_SHADOW(o);
					return o;
				}

				fixed4 frag(v2f i) :SV_Target
				{
					i.TangentLightDir = normalize(i.TangentLightDir);
					i.TangentViewDir = normalize(i.TangentViewDir);
					i.WorldPos = normalize(i.WorldPos);

					fixed3 TangentNormal = UnpackNormal(tex2D(_NormalMap, i.uv));

					fixed3 albedo = tex2D(_MainMap, i.uv).rgb*_Color.rgb;
					fixed3 ambient = albedo.rgb*UNITY_LIGHTMODEL_AMBIENT.xyz;
					fixed halfLambert = (0.5*dot(TangentNormal, i.TangentLightDir) + 0.5);
					fixed3 diffuse = tex2D(_RampMap, fixed2(halfLambert, halfLambert))*_LightColor0*albedo;
					fixed3 TangentHalfDir = normalize(i.TangentViewDir + i.TangentLightDir);
					fixed3 specular = _LightColor0.rgb*_Specular.rgb
						*pow(max(0, dot(TangentNormal,TangentHalfDir)),_Gloss);

					UNITY_LIGHT_ATTENUATION(atten, i, i.WorldPos);

					return fixed4(ambient+(diffuse+specular)*atten,1.0);
				}



				ENDCG
			}
			Pass
				{
					
					Tags{ "LightMode" = "ForwardAdd" }
					Blend One One
					CGPROGRAM
					
					#pragma multi_compile_fwdadd
					#pragma vertex vert
					#pragma fragment frag

					#include "Lighting.cginc"
					#include "UnityCG.cginc"
					#include "AutoLight.cginc"

					fixed4 _Color;
					sampler2D _MainMap;
					sampler2D _NormalMap;
					float4 _MainMap_ST;
					float4 _NormalMap_ST;
					fixed4 _Specular;
					float _Gloss;

				struct a2v
				{
					float4 vertex:POSITION;
					fixed3 normal : NORMAL;
					float4 tangent:TANGENT;
					float4 texcoord:TEXCOORD0;
				};
				struct v2f
				{
					float4 pos:SV_POSITION;
					float2 uv:TEXCOORD0;
					float3 TangentLightDir:TEXCOORD1;
					float3 TangentViewDir:TEXCOORD2;
					float3 WorldPos:TEXCOORD3;
					SHADOW_COORDS(4)
				};

				v2f vert(a2v v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.texcoord, _MainMap);

					o.WorldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					TANGENT_SPACE_ROTATION;
					o.TangentLightDir = mul(rotation,ObjSpaceLightDir(v.vertex));
					o.TangentViewDir = mul(rotation,ObjSpaceViewDir(v.vertex));
					TRANSFER_SHADOW(o);
					return o;
				}

				fixed4 frag(v2f i) :SV_Target
				{
					i.TangentLightDir = normalize(i.TangentLightDir);
					i.TangentViewDir = normalize(i.TangentViewDir);

					fixed3 TangentNormal = UnpackNormal(tex2D(_NormalMap, i.uv));

					fixed3 albedo = tex2D(_MainMap, i.uv).rgb*_Color.rgb;
					fixed3 diffuse = _LightColor0.rgb*(0.5*dot(TangentNormal, i.TangentLightDir) + 0.5);
					fixed3 TangentHalfDir = normalize(i.TangentViewDir + i.TangentLightDir);
					fixed3 specular = _LightColor0.rgb*_Specular.rgb
					*pow(max(0, dot(TangentNormal,TangentHalfDir)),_Gloss);

					UNITY_LIGHT_ATTENUATION(atten, i, i.WorldPos);

					return fixed4((diffuse + specular)*atten,1.0);
				}



					ENDCG
				}

		}
		FallBack"Specular"
}
