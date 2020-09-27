Shader "PBR Master"
{
    Properties
    {
        Color_B178CEE1("Color", Color) = (1, 1, 1, 0)
        Color_8E13568A("Specular", Color) = (1, 1, 1, 0)
        Vector1_8F542D29("Smoothness", Float) = 0
        Color_1A413B9C("Environment Light Color", Color) = (0, 0, 0, 0)
        Vector1_D7E2ED5C("Noise Scale", Float) = 10
        Vector1_D4B45908("Noise Speed", Float) = 0.01
        Vector1_48E1DFAE("Noise Light Strength", Float) = 0.5
        Vector1_8C0B9D56("Displacement Strength", Float) = 0.5
        Vector1_CF216209("SSS Distortion", Float) = 0.7
        Vector1_B33D0616("SSS Power", Float) = 2.5
        Vector1_68A1BB04("SSS Scale", Float) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "Queue"="Transparent+0"
        }
        
        Pass
        {
            Name "Universal Forward"
            Tags 
            { 
                "LightMode" = "UniversalForward"
            }
           
            // Render State
            Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
            Cull Off
            ZTest LEqual
            ZWrite On
            // ColorMask: <None>
            
        
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
        
            // Debug
            // <None>
        
            // --------------------------------------------------
            // Pass
        
            // Pragmas
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
        
            // Keywords
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            // GraphKeywords: <None>
            
            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS 
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define FEATURES_GRAPH_VERTEX
            #pragma multi_compile_instancing
            #define SHADERPASS_FORWARD
            #define REQUIRE_DEPTH_TEXTURE
            
        
            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"
        
            // --------------------------------------------------
            // Graph
        
            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
            float4 Color_B178CEE1;
            float4 Color_8E13568A;
            float Vector1_8F542D29;
            float4 Color_1A413B9C;
            float Vector1_D7E2ED5C;
            float Vector1_D4B45908;
            float Vector1_48E1DFAE;
            float Vector1_8C0B9D56;
            float Vector1_CF216209;
            float Vector1_B33D0616;
            float Vector1_68A1BB04;
            CBUFFER_END
        
            // Graph Functions
            
            void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
            {
                Rotation = radians(Rotation);
            
                float s = sin(Rotation);
                float c = cos(Rotation);
                float one_minus_c = 1.0 - c;
                
                Axis = normalize(Axis);
            
                float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                          one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                          one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                        };
            
                Out = mul(rot_mat,  In);
            }
            
            void Unity_Multiply_float(float A, float B, out float Out)
            {
                Out = A * B;
            }
            
            void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
            {
                Out = UV * Tiling + Offset;
            }
            
            
            float2 Unity_GradientNoise_Dir_float(float2 p)
            {
                // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
                p = p % 289;
                float x = (34 * p.x + 1) * p.x % 289 + p.y;
                x = (34 * x + 1) * x % 289;
                x = frac(x / 41) * 2 - 1;
                return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
            }
            
            void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
            { 
                float2 p = UV * Scale;
                float2 ip = floor(p);
                float2 fp = frac(p);
                float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
                float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
                float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
                float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
                fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
                Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
            }
            
            void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
            {
                Out = A / B;
            }
            
            void Unity_Absolute_float3(float3 In, out float3 Out)
            {
                Out = abs(In);
            }
            
            void Unity_Add_float(float A, float B, out float Out)
            {
                Out = A + B;
            }
            
            void Unity_Saturate_float(float In, out float Out)
            {
                Out = saturate(In);
            }
            
            void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
            {
                Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
            }
            
            void Unity_Absolute_float(float In, out float Out)
            {
                Out = abs(In);
            }
            
            void Unity_Preview_float(float In, out float Out)
            {
                Out = In;
            }
            
            void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
            {
                Out = A * B;
            }
            
            void Unity_Add_float3(float3 A, float3 B, out float3 Out)
            {
                Out = A + B;
            }
            
            // 00222216c70f3619080ea66073823d54
            #include "Assets/Shaders/Includes/CustomLighting.hlsl"
            
            struct Bindings_GetMainLight_fc884d5c668d29144bb1456de0af6c36
            {
                float3 WorldSpacePosition;
            };
            
            void SG_GetMainLight_fc884d5c668d29144bb1456de0af6c36(Bindings_GetMainLight_fc884d5c668d29144bb1456de0af6c36 IN, out half3 Direction_0, out half3 Color_1, out half DistanceAtten_2, out half ShadowAtten_3)
            {
                half3 _CustomFunction_4BD45C5E_Direction_0;
                half3 _CustomFunction_4BD45C5E_Color_1;
                half _CustomFunction_4BD45C5E_DistanceAtten_2;
                half _CustomFunction_4BD45C5E_ShadowAtten_3;
                MainLight_half(IN.WorldSpacePosition, _CustomFunction_4BD45C5E_Direction_0, _CustomFunction_4BD45C5E_Color_1, _CustomFunction_4BD45C5E_DistanceAtten_2, _CustomFunction_4BD45C5E_ShadowAtten_3);
                Direction_0 = _CustomFunction_4BD45C5E_Direction_0;
                Color_1 = _CustomFunction_4BD45C5E_Color_1;
                DistanceAtten_2 = _CustomFunction_4BD45C5E_DistanceAtten_2;
                ShadowAtten_3 = _CustomFunction_4BD45C5E_ShadowAtten_3;
            }
            
            void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
            {
                Out = dot(A, B);
            }
            
            void Unity_Preview_float3(float3 In, out float3 Out)
            {
                Out = In;
            }
            
            struct Bindings_DirectSpecular_24c933b5392073e41adadf0d05cf8566
            {
                float3 WorldSpaceNormal;
                float3 WorldSpaceViewDirection;
            };
            
            void SG_DirectSpecular_24c933b5392073e41adadf0d05cf8566(float4 Color_F53B5328, float Vector1_74C1FACA, float3 Vector3_640FEED, float4 Color_C7E12EF8, Bindings_DirectSpecular_24c933b5392073e41adadf0d05cf8566 IN, out half3 Out_0)
            {
                float4 _Property_A34525CE_Out_0 = Color_F53B5328;
                float _Property_AF244E1C_Out_0 = Vector1_74C1FACA;
                float3 _Property_DF569F59_Out_0 = Vector3_640FEED;
                float4 _Property_B4E24E06_Out_0 = Color_C7E12EF8;
                half3 _CustomFunction_202FE61C_Out_6;
                DirectSpecular_half((_Property_A34525CE_Out_0.xyz), _Property_AF244E1C_Out_0, _Property_DF569F59_Out_0, (_Property_B4E24E06_Out_0.xyz), IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _CustomFunction_202FE61C_Out_6);
                Out_0 = _CustomFunction_202FE61C_Out_6;
            }
            
            struct Bindings_CalculateMainLight_92e70ea51fac8a443b9f65ee2812eea0
            {
                float3 WorldSpaceNormal;
                float3 WorldSpaceViewDirection;
                float3 WorldSpacePosition;
            };
            
            void SG_CalculateMainLight_92e70ea51fac8a443b9f65ee2812eea0(float4 Color_822DDD52, float Vector1_38A6B18D, Bindings_CalculateMainLight_92e70ea51fac8a443b9f65ee2812eea0 IN, out float3 Diffuse_0, out float3 Specular_1)
            {
                Bindings_GetMainLight_fc884d5c668d29144bb1456de0af6c36 _GetMainLight_2D1CB1B7;
                _GetMainLight_2D1CB1B7.WorldSpacePosition = IN.WorldSpacePosition;
                half3 _GetMainLight_2D1CB1B7_Direction_0;
                half3 _GetMainLight_2D1CB1B7_Color_1;
                half _GetMainLight_2D1CB1B7_DistanceAtten_2;
                half _GetMainLight_2D1CB1B7_ShadowAtten_3;
                SG_GetMainLight_fc884d5c668d29144bb1456de0af6c36(_GetMainLight_2D1CB1B7, _GetMainLight_2D1CB1B7_Direction_0, _GetMainLight_2D1CB1B7_Color_1, _GetMainLight_2D1CB1B7_DistanceAtten_2, _GetMainLight_2D1CB1B7_ShadowAtten_3);
                float _DotProduct_E144B168_Out_2;
                Unity_DotProduct_float3(IN.WorldSpaceNormal, _GetMainLight_2D1CB1B7_Direction_0, _DotProduct_E144B168_Out_2);
                float _Saturate_F1939154_Out_1;
                Unity_Saturate_float(_DotProduct_E144B168_Out_2, _Saturate_F1939154_Out_1);
                float _Multiply_BAF06DE_Out_2;
                Unity_Multiply_float(_GetMainLight_2D1CB1B7_DistanceAtten_2, _GetMainLight_2D1CB1B7_ShadowAtten_3, _Multiply_BAF06DE_Out_2);
                float3 _Multiply_C480EEAE_Out_2;
                Unity_Multiply_float(_GetMainLight_2D1CB1B7_Color_1, (_Multiply_BAF06DE_Out_2.xxx), _Multiply_C480EEAE_Out_2);
                float3 _Multiply_98E31ED4_Out_2;
                Unity_Multiply_float((_Saturate_F1939154_Out_1.xxx), _Multiply_C480EEAE_Out_2, _Multiply_98E31ED4_Out_2);
                float4 _Property_B38B1CFA_Out_0 = Color_822DDD52;
                float _Property_C1B6C566_Out_0 = Vector1_38A6B18D;
                float3 _Preview_634436FD_Out_1;
                Unity_Preview_float3(_GetMainLight_2D1CB1B7_Direction_0, _Preview_634436FD_Out_1);
                Bindings_DirectSpecular_24c933b5392073e41adadf0d05cf8566 _DirectSpecular_44AFF988;
                _DirectSpecular_44AFF988.WorldSpaceNormal = IN.WorldSpaceNormal;
                _DirectSpecular_44AFF988.WorldSpaceViewDirection = IN.WorldSpaceViewDirection;
                half3 _DirectSpecular_44AFF988_Out_0;
                SG_DirectSpecular_24c933b5392073e41adadf0d05cf8566(_Property_B38B1CFA_Out_0, _Property_C1B6C566_Out_0, _Preview_634436FD_Out_1, (float4(_Multiply_C480EEAE_Out_2, 1.0)), _DirectSpecular_44AFF988, _DirectSpecular_44AFF988_Out_0);
                Diffuse_0 = _Multiply_98E31ED4_Out_2;
                Specular_1 = _DirectSpecular_44AFF988_Out_0;
            }
            
            struct Bindings_CalculateAdditionalLights_fa66af11a916f9f42a5c85287ac3bd4b
            {
                float3 WorldSpaceNormal;
                float3 WorldSpaceViewDirection;
                float3 WorldSpacePosition;
            };
            
            void SG_CalculateAdditionalLights_fa66af11a916f9f42a5c85287ac3bd4b(float4 Color_E64814B9, float Vector1_CFCF55A, Bindings_CalculateAdditionalLights_fa66af11a916f9f42a5c85287ac3bd4b IN, out half3 Diffuse_0, out half3 Specular_1)
            {
                float4 _Property_9F8E76EC_Out_0 = Color_E64814B9;
                float _Property_EB4B8C51_Out_0 = Vector1_CFCF55A;
                half3 _CustomFunction_F94AA2B1_Diffuse_5;
                half3 _CustomFunction_F94AA2B1_Specular_6;
                AdditionalLights_half((_Property_9F8E76EC_Out_0.xyz), _Property_EB4B8C51_Out_0, IN.WorldSpacePosition, IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _CustomFunction_F94AA2B1_Diffuse_5, _CustomFunction_F94AA2B1_Specular_6);
                Diffuse_0 = _CustomFunction_F94AA2B1_Diffuse_5;
                Specular_1 = _CustomFunction_F94AA2B1_Specular_6;
            }
            
            void Unity_Normalize_float3(float3 In, out float3 Out)
            {
                Out = normalize(In);
            }
            
            void Unity_Multiply_float(float2 A, float2 B, out float2 Out)
            {
                Out = A * B;
            }
            
            void Unity_Add_float2(float2 A, float2 B, out float2 Out)
            {
                Out = A + B;
            }
            
            void Unity_Negate_float2(float2 In, out float2 Out)
            {
                Out = -1 * In;
            }
            
            void Unity_DotProduct_float2(float2 A, float2 B, out float Out)
            {
                Out = dot(A, B);
            }
            
            void Unity_Power_float(float A, float B, out float Out)
            {
                Out = pow(A, B);
            }
            
            void Unity_DotProduct_float(float A, float B, out float Out)
            {
                Out = dot(A, B);
            }
            
            void Unity_Multiply_float(float4 A, float4 B, out float4 Out)
            {
                Out = A * B;
            }
            
            void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
            {
                Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
            }
            
            void Unity_Subtract_float(float A, float B, out float Out)
            {
                Out = A - B;
            }
            
            void Unity_Divide_float(float A, float B, out float Out)
            {
                Out = A / B;
            }
        
            // Graph Vertex
            struct VertexDescriptionInputs
            {
                float3 ObjectSpaceNormal;
                float3 WorldSpaceNormal;
                float3 ObjectSpaceTangent;
                float3 WorldSpacePosition;
                float3 TimeParameters;
            };
            
            struct VertexDescription
            {
                float3 VertexPosition;
                float3 VertexNormal;
                float3 VertexTangent;
            };
            
            VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
            {
                VertexDescription description = (VertexDescription)0;
                float3 _RotateAboutAxis_91AD6AAA_Out_3;
                Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, float3 (0, 1, 0), 90, _RotateAboutAxis_91AD6AAA_Out_3);
                float _Property_440EEBE_Out_0 = Vector1_D4B45908;
                float _Multiply_914B86AC_Out_2;
                Unity_Multiply_float(IN.TimeParameters.x, _Property_440EEBE_Out_0, _Multiply_914B86AC_Out_2);
                float2 _TilingAndOffset_6D6DAF34_Out_3;
                Unity_TilingAndOffset_float((_RotateAboutAxis_91AD6AAA_Out_3.xy), float2 (1, 1), (_Multiply_914B86AC_Out_2.xx), _TilingAndOffset_6D6DAF34_Out_3);
                float _Property_BB4F9425_Out_0 = Vector1_D7E2ED5C;
                float _GradientNoise_18198810_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_6D6DAF34_Out_3, _Property_BB4F9425_Out_0, _GradientNoise_18198810_Out_2);
                float3 _Divide_7C88F776_Out_2;
                Unity_Divide_float3(IN.WorldSpaceNormal, float3(1.5, 1.5, 1.5), _Divide_7C88F776_Out_2);
                float3 _Absolute_ECFC2C75_Out_1;
                Unity_Absolute_float3(_Divide_7C88F776_Out_2, _Absolute_ECFC2C75_Out_1);
                float _Split_21AEC44A_R_1 = _Absolute_ECFC2C75_Out_1[0];
                float _Split_21AEC44A_G_2 = _Absolute_ECFC2C75_Out_1[1];
                float _Split_21AEC44A_B_3 = _Absolute_ECFC2C75_Out_1[2];
                float _Split_21AEC44A_A_4 = 0;
                float _Multiply_8B950EF7_Out_2;
                Unity_Multiply_float(_GradientNoise_18198810_Out_2, _Split_21AEC44A_R_1, _Multiply_8B950EF7_Out_2);
                float3 _RotateAboutAxis_AFC207A1_Out_3;
                Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, float3 (1, 0, 0), 90, _RotateAboutAxis_AFC207A1_Out_3);
                float _Add_E7BCDB67_Out_2;
                Unity_Add_float(_Multiply_914B86AC_Out_2, 10, _Add_E7BCDB67_Out_2);
                float2 _TilingAndOffset_FEAB0DCE_Out_3;
                Unity_TilingAndOffset_float((_RotateAboutAxis_AFC207A1_Out_3.xy), float2 (1, 1), (_Add_E7BCDB67_Out_2.xx), _TilingAndOffset_FEAB0DCE_Out_3);
                float _GradientNoise_6537B291_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_FEAB0DCE_Out_3, _Property_BB4F9425_Out_0, _GradientNoise_6537B291_Out_2);
                float _Multiply_F8FE6501_Out_2;
                Unity_Multiply_float(_GradientNoise_6537B291_Out_2, _Split_21AEC44A_G_2, _Multiply_F8FE6501_Out_2);
                float _Add_9F8877A3_Out_2;
                Unity_Add_float(_Multiply_8B950EF7_Out_2, _Multiply_F8FE6501_Out_2, _Add_9F8877A3_Out_2);
                float _Add_6C11A02A_Out_2;
                Unity_Add_float(_Multiply_914B86AC_Out_2, 20, _Add_6C11A02A_Out_2);
                float2 _TilingAndOffset_CEF11ADD_Out_3;
                Unity_TilingAndOffset_float((IN.WorldSpacePosition.xy), float2 (1, 1), (_Add_6C11A02A_Out_2.xx), _TilingAndOffset_CEF11ADD_Out_3);
                float _GradientNoise_1C72BDE1_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_CEF11ADD_Out_3, _Property_BB4F9425_Out_0, _GradientNoise_1C72BDE1_Out_2);
                float _Multiply_21A8A37D_Out_2;
                Unity_Multiply_float(_GradientNoise_1C72BDE1_Out_2, _Split_21AEC44A_B_3, _Multiply_21A8A37D_Out_2);
                float _Add_88EE8F5F_Out_2;
                Unity_Add_float(_Add_9F8877A3_Out_2, _Multiply_21A8A37D_Out_2, _Add_88EE8F5F_Out_2);
                float _Saturate_2CDD9D86_Out_1;
                Unity_Saturate_float(_Add_88EE8F5F_Out_2, _Saturate_2CDD9D86_Out_1);
                float _Remap_B00EE626_Out_3;
                Unity_Remap_float(_Saturate_2CDD9D86_Out_1, float2 (0, 1), float2 (-1, 1), _Remap_B00EE626_Out_3);
                float _Absolute_CB429FCB_Out_1;
                Unity_Absolute_float(_Remap_B00EE626_Out_3, _Absolute_CB429FCB_Out_1);
                float _Preview_64FE413E_Out_1;
                Unity_Preview_float(_Absolute_CB429FCB_Out_1, _Preview_64FE413E_Out_1);
                float3 _Multiply_24E87ABD_Out_2;
                Unity_Multiply_float(IN.WorldSpaceNormal, (_Preview_64FE413E_Out_1.xxx), _Multiply_24E87ABD_Out_2);
                float _Property_824F2B83_Out_0 = Vector1_8C0B9D56;
                float3 _Multiply_D7E6F3AD_Out_2;
                Unity_Multiply_float(_Multiply_24E87ABD_Out_2, (_Property_824F2B83_Out_0.xxx), _Multiply_D7E6F3AD_Out_2);
                float3 _Add_48B19B00_Out_2;
                Unity_Add_float3(IN.WorldSpacePosition, _Multiply_D7E6F3AD_Out_2, _Add_48B19B00_Out_2);
                description.VertexPosition = _Add_48B19B00_Out_2;
                description.VertexNormal = IN.ObjectSpaceNormal;
                description.VertexTangent = IN.ObjectSpaceTangent;
                return description;
            }
            
            // Graph Pixel
            struct SurfaceDescriptionInputs
            {
                float3 WorldSpaceNormal;
                float3 TangentSpaceNormal;
                float3 WorldSpaceViewDirection;
                float3 WorldSpacePosition;
                float4 ScreenPosition;
                float3 TimeParameters;
            };
            
            struct SurfaceDescription
            {
                float3 Albedo;
                float3 Normal;
                float3 Emission;
                float Metallic;
                float Smoothness;
                float Occlusion;
                float Alpha;
                float AlphaClipThreshold;
            };
            
            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
            {
                SurfaceDescription surface = (SurfaceDescription)0;
                float4 _Property_B4F6F86A_Out_0 = Color_B178CEE1;
                float4 _Property_3A4FEE1_Out_0 = Color_8E13568A;
                float _Property_43B46B5B_Out_0 = Vector1_8F542D29;
                Bindings_CalculateMainLight_92e70ea51fac8a443b9f65ee2812eea0 _CalculateMainLight_B6933DFF;
                _CalculateMainLight_B6933DFF.WorldSpaceNormal = IN.WorldSpaceNormal;
                _CalculateMainLight_B6933DFF.WorldSpaceViewDirection = IN.WorldSpaceViewDirection;
                _CalculateMainLight_B6933DFF.WorldSpacePosition = IN.WorldSpacePosition;
                float3 _CalculateMainLight_B6933DFF_Diffuse_0;
                float3 _CalculateMainLight_B6933DFF_Specular_1;
                SG_CalculateMainLight_92e70ea51fac8a443b9f65ee2812eea0(_Property_3A4FEE1_Out_0, _Property_43B46B5B_Out_0, _CalculateMainLight_B6933DFF, _CalculateMainLight_B6933DFF_Diffuse_0, _CalculateMainLight_B6933DFF_Specular_1);
                Bindings_CalculateAdditionalLights_fa66af11a916f9f42a5c85287ac3bd4b _CalculateAdditionalLights_9BC46348;
                _CalculateAdditionalLights_9BC46348.WorldSpaceNormal = IN.WorldSpaceNormal;
                _CalculateAdditionalLights_9BC46348.WorldSpaceViewDirection = IN.WorldSpaceViewDirection;
                _CalculateAdditionalLights_9BC46348.WorldSpacePosition = IN.WorldSpacePosition;
                half3 _CalculateAdditionalLights_9BC46348_Diffuse_0;
                half3 _CalculateAdditionalLights_9BC46348_Specular_1;
                SG_CalculateAdditionalLights_fa66af11a916f9f42a5c85287ac3bd4b(_Property_3A4FEE1_Out_0, _Property_43B46B5B_Out_0, _CalculateAdditionalLights_9BC46348, _CalculateAdditionalLights_9BC46348_Diffuse_0, _CalculateAdditionalLights_9BC46348_Specular_1);
                float3 _Add_1CD24747_Out_2;
                Unity_Add_float3(_CalculateMainLight_B6933DFF_Diffuse_0, _CalculateAdditionalLights_9BC46348_Diffuse_0, _Add_1CD24747_Out_2);
                float3 _Add_F5A8978D_Out_2;
                Unity_Add_float3(_CalculateMainLight_B6933DFF_Specular_1, _CalculateAdditionalLights_9BC46348_Specular_1, _Add_F5A8978D_Out_2);
                float3 _Add_811BA667_Out_2;
                Unity_Add_float3(_Add_1CD24747_Out_2, _Add_F5A8978D_Out_2, _Add_811BA667_Out_2);
                float3 _Multiply_DEE8590F_Out_2;
                Unity_Multiply_float((_Property_B4F6F86A_Out_0.xyz), _Add_811BA667_Out_2, _Multiply_DEE8590F_Out_2);
                float3 _Normalize_ADBDED10_Out_1;
                Unity_Normalize_float3(IN.WorldSpaceViewDirection, _Normalize_ADBDED10_Out_1);
                Bindings_GetMainLight_fc884d5c668d29144bb1456de0af6c36 _GetMainLight_F1F4647E;
                _GetMainLight_F1F4647E.WorldSpacePosition = IN.WorldSpacePosition;
                half3 _GetMainLight_F1F4647E_Direction_0;
                half3 _GetMainLight_F1F4647E_Color_1;
                half _GetMainLight_F1F4647E_DistanceAtten_2;
                half _GetMainLight_F1F4647E_ShadowAtten_3;
                SG_GetMainLight_fc884d5c668d29144bb1456de0af6c36(_GetMainLight_F1F4647E, _GetMainLight_F1F4647E_Direction_0, _GetMainLight_F1F4647E_Color_1, _GetMainLight_F1F4647E_DistanceAtten_2, _GetMainLight_F1F4647E_ShadowAtten_3);
                float3 _RotateAboutAxis_91AD6AAA_Out_3;
                Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, float3 (0, 1, 0), 90, _RotateAboutAxis_91AD6AAA_Out_3);
                float _Property_440EEBE_Out_0 = Vector1_D4B45908;
                float _Multiply_914B86AC_Out_2;
                Unity_Multiply_float(IN.TimeParameters.x, _Property_440EEBE_Out_0, _Multiply_914B86AC_Out_2);
                float2 _TilingAndOffset_6D6DAF34_Out_3;
                Unity_TilingAndOffset_float((_RotateAboutAxis_91AD6AAA_Out_3.xy), float2 (1, 1), (_Multiply_914B86AC_Out_2.xx), _TilingAndOffset_6D6DAF34_Out_3);
                float _Property_BB4F9425_Out_0 = Vector1_D7E2ED5C;
                float _GradientNoise_18198810_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_6D6DAF34_Out_3, _Property_BB4F9425_Out_0, _GradientNoise_18198810_Out_2);
                float3 _Divide_7C88F776_Out_2;
                Unity_Divide_float3(IN.WorldSpaceNormal, float3(1.5, 1.5, 1.5), _Divide_7C88F776_Out_2);
                float3 _Absolute_ECFC2C75_Out_1;
                Unity_Absolute_float3(_Divide_7C88F776_Out_2, _Absolute_ECFC2C75_Out_1);
                float _Split_21AEC44A_R_1 = _Absolute_ECFC2C75_Out_1[0];
                float _Split_21AEC44A_G_2 = _Absolute_ECFC2C75_Out_1[1];
                float _Split_21AEC44A_B_3 = _Absolute_ECFC2C75_Out_1[2];
                float _Split_21AEC44A_A_4 = 0;
                float _Multiply_8B950EF7_Out_2;
                Unity_Multiply_float(_GradientNoise_18198810_Out_2, _Split_21AEC44A_R_1, _Multiply_8B950EF7_Out_2);
                float3 _RotateAboutAxis_AFC207A1_Out_3;
                Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, float3 (1, 0, 0), 90, _RotateAboutAxis_AFC207A1_Out_3);
                float _Add_E7BCDB67_Out_2;
                Unity_Add_float(_Multiply_914B86AC_Out_2, 10, _Add_E7BCDB67_Out_2);
                float2 _TilingAndOffset_FEAB0DCE_Out_3;
                Unity_TilingAndOffset_float((_RotateAboutAxis_AFC207A1_Out_3.xy), float2 (1, 1), (_Add_E7BCDB67_Out_2.xx), _TilingAndOffset_FEAB0DCE_Out_3);
                float _GradientNoise_6537B291_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_FEAB0DCE_Out_3, _Property_BB4F9425_Out_0, _GradientNoise_6537B291_Out_2);
                float _Multiply_F8FE6501_Out_2;
                Unity_Multiply_float(_GradientNoise_6537B291_Out_2, _Split_21AEC44A_G_2, _Multiply_F8FE6501_Out_2);
                float _Add_9F8877A3_Out_2;
                Unity_Add_float(_Multiply_8B950EF7_Out_2, _Multiply_F8FE6501_Out_2, _Add_9F8877A3_Out_2);
                float _Add_6C11A02A_Out_2;
                Unity_Add_float(_Multiply_914B86AC_Out_2, 20, _Add_6C11A02A_Out_2);
                float2 _TilingAndOffset_CEF11ADD_Out_3;
                Unity_TilingAndOffset_float((IN.WorldSpacePosition.xy), float2 (1, 1), (_Add_6C11A02A_Out_2.xx), _TilingAndOffset_CEF11ADD_Out_3);
                float _GradientNoise_1C72BDE1_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_CEF11ADD_Out_3, _Property_BB4F9425_Out_0, _GradientNoise_1C72BDE1_Out_2);
                float _Multiply_21A8A37D_Out_2;
                Unity_Multiply_float(_GradientNoise_1C72BDE1_Out_2, _Split_21AEC44A_B_3, _Multiply_21A8A37D_Out_2);
                float _Add_88EE8F5F_Out_2;
                Unity_Add_float(_Add_9F8877A3_Out_2, _Multiply_21A8A37D_Out_2, _Add_88EE8F5F_Out_2);
                float _Saturate_2CDD9D86_Out_1;
                Unity_Saturate_float(_Add_88EE8F5F_Out_2, _Saturate_2CDD9D86_Out_1);
                float _Remap_B00EE626_Out_3;
                Unity_Remap_float(_Saturate_2CDD9D86_Out_1, float2 (0, 1), float2 (-1, 1), _Remap_B00EE626_Out_3);
                float _Absolute_CB429FCB_Out_1;
                Unity_Absolute_float(_Remap_B00EE626_Out_3, _Absolute_CB429FCB_Out_1);
                float _Preview_C22952E7_Out_1;
                Unity_Preview_float(_Absolute_CB429FCB_Out_1, _Preview_C22952E7_Out_1);
                float _Property_BB76C5B6_Out_0 = Vector1_48E1DFAE;
                float _Multiply_81A6A00C_Out_2;
                Unity_Multiply_float(_Preview_C22952E7_Out_1, _Property_BB76C5B6_Out_0, _Multiply_81A6A00C_Out_2);
                float2 _TilingAndOffset_312095F8_Out_3;
                Unity_TilingAndOffset_float((IN.WorldSpaceNormal.xy), float2 (1, 1), (_Multiply_81A6A00C_Out_2.xx), _TilingAndOffset_312095F8_Out_3);
                float _Property_EEE36D56_Out_0 = Vector1_CF216209;
                float2 _Multiply_D39564EF_Out_2;
                Unity_Multiply_float(_TilingAndOffset_312095F8_Out_3, (_Property_EEE36D56_Out_0.xx), _Multiply_D39564EF_Out_2);
                float2 _Add_48906C90_Out_2;
                Unity_Add_float2((_GetMainLight_F1F4647E_Direction_0.xy), _Multiply_D39564EF_Out_2, _Add_48906C90_Out_2);
                float2 _Negate_738EA4EA_Out_1;
                Unity_Negate_float2(_Add_48906C90_Out_2, _Negate_738EA4EA_Out_1);
                float _DotProduct_38B3399_Out_2;
                Unity_DotProduct_float2((_Normalize_ADBDED10_Out_1.xy), _Negate_738EA4EA_Out_1, _DotProduct_38B3399_Out_2);
                float _Property_49C48C1_Out_0 = Vector1_B33D0616;
                float _Power_36F9A28C_Out_2;
                Unity_Power_float(_DotProduct_38B3399_Out_2, _Property_49C48C1_Out_0, _Power_36F9A28C_Out_2);
                float _Property_EE224157_Out_0 = Vector1_68A1BB04;
                float _DotProduct_3F168FC8_Out_2;
                Unity_DotProduct_float(_Power_36F9A28C_Out_2, _Property_EE224157_Out_0, _DotProduct_3F168FC8_Out_2);
                float _Saturate_FFB08A4E_Out_1;
                Unity_Saturate_float(_DotProduct_3F168FC8_Out_2, _Saturate_FFB08A4E_Out_1);
                Bindings_GetMainLight_fc884d5c668d29144bb1456de0af6c36 _GetMainLight_9F13029;
                _GetMainLight_9F13029.WorldSpacePosition = IN.WorldSpacePosition;
                half3 _GetMainLight_9F13029_Direction_0;
                half3 _GetMainLight_9F13029_Color_1;
                half _GetMainLight_9F13029_DistanceAtten_2;
                half _GetMainLight_9F13029_ShadowAtten_3;
                SG_GetMainLight_fc884d5c668d29144bb1456de0af6c36(_GetMainLight_9F13029, _GetMainLight_9F13029_Direction_0, _GetMainLight_9F13029_Color_1, _GetMainLight_9F13029_DistanceAtten_2, _GetMainLight_9F13029_ShadowAtten_3);
                float3 _Multiply_4ADD9031_Out_2;
                Unity_Multiply_float((_Saturate_FFB08A4E_Out_1.xxx), _GetMainLight_9F13029_Color_1, _Multiply_4ADD9031_Out_2);
                float3 _Multiply_59470CF4_Out_2;
                Unity_Multiply_float((_Property_B4F6F86A_Out_0.xyz), _Multiply_4ADD9031_Out_2, _Multiply_59470CF4_Out_2);
                float3 _Add_4F9D38F7_Out_2;
                Unity_Add_float3(_Multiply_DEE8590F_Out_2, _Multiply_59470CF4_Out_2, _Add_4F9D38F7_Out_2);
                float4 _Property_3351416A_Out_0 = Color_1A413B9C;
                float4 _Multiply_42A7AC12_Out_2;
                Unity_Multiply_float(_Property_3351416A_Out_0, _Property_B4F6F86A_Out_0, _Multiply_42A7AC12_Out_2);
                float3 _Add_B33784D3_Out_2;
                Unity_Add_float3(_Add_4F9D38F7_Out_2, (_Multiply_42A7AC12_Out_2.xyz), _Add_B33784D3_Out_2);
                float _SceneDepth_4FAE51A0_Out_1;
                Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_4FAE51A0_Out_1);
                float4 _ScreenPosition_8E746D1E_Out_0 = IN.ScreenPosition;
                float _Split_94038860_R_1 = _ScreenPosition_8E746D1E_Out_0[0];
                float _Split_94038860_G_2 = _ScreenPosition_8E746D1E_Out_0[1];
                float _Split_94038860_B_3 = _ScreenPosition_8E746D1E_Out_0[2];
                float _Split_94038860_A_4 = _ScreenPosition_8E746D1E_Out_0[3];
                float _Subtract_42FE7ACD_Out_2;
                Unity_Subtract_float(_Split_94038860_A_4, 1, _Subtract_42FE7ACD_Out_2);
                float _Subtract_68104637_Out_2;
                Unity_Subtract_float(_SceneDepth_4FAE51A0_Out_1, _Subtract_42FE7ACD_Out_2, _Subtract_68104637_Out_2);
                float _Divide_564AD5D6_Out_2;
                Unity_Divide_float(_Subtract_68104637_Out_2, 100, _Divide_564AD5D6_Out_2);
                float _Saturate_2F42B045_Out_1;
                Unity_Saturate_float(_Divide_564AD5D6_Out_2, _Saturate_2F42B045_Out_1);
                surface.Albedo = IsGammaSpace() ? float3(0, 0, 0) : SRGBToLinear(float3(0, 0, 0));
                surface.Normal = IN.TangentSpaceNormal;
                surface.Emission = _Add_B33784D3_Out_2;
                surface.Metallic = 0;
                surface.Smoothness = 0;
                surface.Occlusion = 0;
                surface.Alpha = _Saturate_2F42B045_Out_1;
                surface.AlphaClipThreshold = 0;
                return surface;
            }
        
            // --------------------------------------------------
            // Structs and Packing
        
            // Generated Type: Attributes
            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float4 uv1 : TEXCOORD1;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : INSTANCEID_SEMANTIC;
                #endif
            };
        
            // Generated Type: Varyings
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS;
                float3 normalWS;
                float4 tangentWS;
                float3 viewDirectionWS;
                #if defined(LIGHTMAP_ON)
                float2 lightmapUV;
                #endif
                #if !defined(LIGHTMAP_ON)
                float3 sh;
                #endif
                float4 fogFactorAndVertexLight;
                float4 shadowCoord;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif
            };
            
            // Generated Type: PackedVaryings
            struct PackedVaryings
            {
                float4 positionCS : SV_POSITION;
                #if defined(LIGHTMAP_ON)
                #endif
                #if !defined(LIGHTMAP_ON)
                #endif
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif
                float3 interp00 : TEXCOORD0;
                float3 interp01 : TEXCOORD1;
                float4 interp02 : TEXCOORD2;
                float3 interp03 : TEXCOORD3;
                float2 interp04 : TEXCOORD4;
                float3 interp05 : TEXCOORD5;
                float4 interp06 : TEXCOORD6;
                float4 interp07 : TEXCOORD7;
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif
            };
            
            // Packed Type: Varyings
            PackedVaryings PackVaryings(Varyings input)
            {
                PackedVaryings output = (PackedVaryings)0;
                output.positionCS = input.positionCS;
                output.interp00.xyz = input.positionWS;
                output.interp01.xyz = input.normalWS;
                output.interp02.xyzw = input.tangentWS;
                output.interp03.xyz = input.viewDirectionWS;
                #if defined(LIGHTMAP_ON)
                output.interp04.xy = input.lightmapUV;
                #endif
                #if !defined(LIGHTMAP_ON)
                output.interp05.xyz = input.sh;
                #endif
                output.interp06.xyzw = input.fogFactorAndVertexLight;
                output.interp07.xyzw = input.shadowCoord;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif
                return output;
            }
            
            // Unpacked Type: Varyings
            Varyings UnpackVaryings(PackedVaryings input)
            {
                Varyings output = (Varyings)0;
                output.positionCS = input.positionCS;
                output.positionWS = input.interp00.xyz;
                output.normalWS = input.interp01.xyz;
                output.tangentWS = input.interp02.xyzw;
                output.viewDirectionWS = input.interp03.xyz;
                #if defined(LIGHTMAP_ON)
                output.lightmapUV = input.interp04.xy;
                #endif
                #if !defined(LIGHTMAP_ON)
                output.sh = input.interp05.xyz;
                #endif
                output.fogFactorAndVertexLight = input.interp06.xyzw;
                output.shadowCoord = input.interp07.xyzw;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif
                return output;
            }
        
            // --------------------------------------------------
            // Build Graph Inputs
        
            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
            {
                VertexDescriptionInputs output;
                ZERO_INITIALIZE(VertexDescriptionInputs, output);
            
                output.ObjectSpaceNormal =           input.normalOS;
                output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
                output.ObjectSpaceTangent =          input.tangentOS;
                output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
                output.TimeParameters =              _TimeParameters.xyz;
            
                return output;
            }
            
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
            {
                SurfaceDescriptionInputs output;
                ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
            
            	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            	float3 unnormalizedNormalWS = input.normalWS;
                const float renormFactor = 1.0 / length(unnormalizedNormalWS);
            
            
                output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
                output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
            
            
                output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
                output.WorldSpacePosition =          input.positionWS;
                output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
                output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
            #else
            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
            #endif
            #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
            
                return output;
            }
            
        
            // --------------------------------------------------
            // Main
        
            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"
        
            ENDHLSL
        }
        
        Pass
        {
            Name "ShadowCaster"
            Tags 
            { 
                "LightMode" = "ShadowCaster"
            }
           
            // Render State
            Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
            Cull Off
            ZTest LEqual
            ZWrite On
            // ColorMask: <None>
            
        
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
        
            // Debug
            // <None>
        
            // --------------------------------------------------
            // Pass
        
            // Pragmas
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            #pragma multi_compile_instancing
        
            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>
            
            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS 
            #define FEATURES_GRAPH_VERTEX
            #pragma multi_compile_instancing
            #define SHADERPASS_SHADOWCASTER
            #define REQUIRE_DEPTH_TEXTURE
            
        
            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"
        
            // --------------------------------------------------
            // Graph
        
            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
            float4 Color_B178CEE1;
            float4 Color_8E13568A;
            float Vector1_8F542D29;
            float4 Color_1A413B9C;
            float Vector1_D7E2ED5C;
            float Vector1_D4B45908;
            float Vector1_48E1DFAE;
            float Vector1_8C0B9D56;
            float Vector1_CF216209;
            float Vector1_B33D0616;
            float Vector1_68A1BB04;
            CBUFFER_END
        
            // Graph Functions
            
            void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
            {
                Rotation = radians(Rotation);
            
                float s = sin(Rotation);
                float c = cos(Rotation);
                float one_minus_c = 1.0 - c;
                
                Axis = normalize(Axis);
            
                float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                          one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                          one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                        };
            
                Out = mul(rot_mat,  In);
            }
            
            void Unity_Multiply_float(float A, float B, out float Out)
            {
                Out = A * B;
            }
            
            void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
            {
                Out = UV * Tiling + Offset;
            }
            
            
            float2 Unity_GradientNoise_Dir_float(float2 p)
            {
                // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
                p = p % 289;
                float x = (34 * p.x + 1) * p.x % 289 + p.y;
                x = (34 * x + 1) * x % 289;
                x = frac(x / 41) * 2 - 1;
                return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
            }
            
            void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
            { 
                float2 p = UV * Scale;
                float2 ip = floor(p);
                float2 fp = frac(p);
                float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
                float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
                float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
                float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
                fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
                Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
            }
            
            void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
            {
                Out = A / B;
            }
            
            void Unity_Absolute_float3(float3 In, out float3 Out)
            {
                Out = abs(In);
            }
            
            void Unity_Add_float(float A, float B, out float Out)
            {
                Out = A + B;
            }
            
            void Unity_Saturate_float(float In, out float Out)
            {
                Out = saturate(In);
            }
            
            void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
            {
                Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
            }
            
            void Unity_Absolute_float(float In, out float Out)
            {
                Out = abs(In);
            }
            
            void Unity_Preview_float(float In, out float Out)
            {
                Out = In;
            }
            
            void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
            {
                Out = A * B;
            }
            
            void Unity_Add_float3(float3 A, float3 B, out float3 Out)
            {
                Out = A + B;
            }
            
            void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
            {
                Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
            }
            
            void Unity_Subtract_float(float A, float B, out float Out)
            {
                Out = A - B;
            }
            
            void Unity_Divide_float(float A, float B, out float Out)
            {
                Out = A / B;
            }
        
            // Graph Vertex
            struct VertexDescriptionInputs
            {
                float3 ObjectSpaceNormal;
                float3 WorldSpaceNormal;
                float3 ObjectSpaceTangent;
                float3 WorldSpacePosition;
                float3 TimeParameters;
            };
            
            struct VertexDescription
            {
                float3 VertexPosition;
                float3 VertexNormal;
                float3 VertexTangent;
            };
            
            VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
            {
                VertexDescription description = (VertexDescription)0;
                float3 _RotateAboutAxis_91AD6AAA_Out_3;
                Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, float3 (0, 1, 0), 90, _RotateAboutAxis_91AD6AAA_Out_3);
                float _Property_440EEBE_Out_0 = Vector1_D4B45908;
                float _Multiply_914B86AC_Out_2;
                Unity_Multiply_float(IN.TimeParameters.x, _Property_440EEBE_Out_0, _Multiply_914B86AC_Out_2);
                float2 _TilingAndOffset_6D6DAF34_Out_3;
                Unity_TilingAndOffset_float((_RotateAboutAxis_91AD6AAA_Out_3.xy), float2 (1, 1), (_Multiply_914B86AC_Out_2.xx), _TilingAndOffset_6D6DAF34_Out_3);
                float _Property_BB4F9425_Out_0 = Vector1_D7E2ED5C;
                float _GradientNoise_18198810_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_6D6DAF34_Out_3, _Property_BB4F9425_Out_0, _GradientNoise_18198810_Out_2);
                float3 _Divide_7C88F776_Out_2;
                Unity_Divide_float3(IN.WorldSpaceNormal, float3(1.5, 1.5, 1.5), _Divide_7C88F776_Out_2);
                float3 _Absolute_ECFC2C75_Out_1;
                Unity_Absolute_float3(_Divide_7C88F776_Out_2, _Absolute_ECFC2C75_Out_1);
                float _Split_21AEC44A_R_1 = _Absolute_ECFC2C75_Out_1[0];
                float _Split_21AEC44A_G_2 = _Absolute_ECFC2C75_Out_1[1];
                float _Split_21AEC44A_B_3 = _Absolute_ECFC2C75_Out_1[2];
                float _Split_21AEC44A_A_4 = 0;
                float _Multiply_8B950EF7_Out_2;
                Unity_Multiply_float(_GradientNoise_18198810_Out_2, _Split_21AEC44A_R_1, _Multiply_8B950EF7_Out_2);
                float3 _RotateAboutAxis_AFC207A1_Out_3;
                Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, float3 (1, 0, 0), 90, _RotateAboutAxis_AFC207A1_Out_3);
                float _Add_E7BCDB67_Out_2;
                Unity_Add_float(_Multiply_914B86AC_Out_2, 10, _Add_E7BCDB67_Out_2);
                float2 _TilingAndOffset_FEAB0DCE_Out_3;
                Unity_TilingAndOffset_float((_RotateAboutAxis_AFC207A1_Out_3.xy), float2 (1, 1), (_Add_E7BCDB67_Out_2.xx), _TilingAndOffset_FEAB0DCE_Out_3);
                float _GradientNoise_6537B291_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_FEAB0DCE_Out_3, _Property_BB4F9425_Out_0, _GradientNoise_6537B291_Out_2);
                float _Multiply_F8FE6501_Out_2;
                Unity_Multiply_float(_GradientNoise_6537B291_Out_2, _Split_21AEC44A_G_2, _Multiply_F8FE6501_Out_2);
                float _Add_9F8877A3_Out_2;
                Unity_Add_float(_Multiply_8B950EF7_Out_2, _Multiply_F8FE6501_Out_2, _Add_9F8877A3_Out_2);
                float _Add_6C11A02A_Out_2;
                Unity_Add_float(_Multiply_914B86AC_Out_2, 20, _Add_6C11A02A_Out_2);
                float2 _TilingAndOffset_CEF11ADD_Out_3;
                Unity_TilingAndOffset_float((IN.WorldSpacePosition.xy), float2 (1, 1), (_Add_6C11A02A_Out_2.xx), _TilingAndOffset_CEF11ADD_Out_3);
                float _GradientNoise_1C72BDE1_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_CEF11ADD_Out_3, _Property_BB4F9425_Out_0, _GradientNoise_1C72BDE1_Out_2);
                float _Multiply_21A8A37D_Out_2;
                Unity_Multiply_float(_GradientNoise_1C72BDE1_Out_2, _Split_21AEC44A_B_3, _Multiply_21A8A37D_Out_2);
                float _Add_88EE8F5F_Out_2;
                Unity_Add_float(_Add_9F8877A3_Out_2, _Multiply_21A8A37D_Out_2, _Add_88EE8F5F_Out_2);
                float _Saturate_2CDD9D86_Out_1;
                Unity_Saturate_float(_Add_88EE8F5F_Out_2, _Saturate_2CDD9D86_Out_1);
                float _Remap_B00EE626_Out_3;
                Unity_Remap_float(_Saturate_2CDD9D86_Out_1, float2 (0, 1), float2 (-1, 1), _Remap_B00EE626_Out_3);
                float _Absolute_CB429FCB_Out_1;
                Unity_Absolute_float(_Remap_B00EE626_Out_3, _Absolute_CB429FCB_Out_1);
                float _Preview_64FE413E_Out_1;
                Unity_Preview_float(_Absolute_CB429FCB_Out_1, _Preview_64FE413E_Out_1);
                float3 _Multiply_24E87ABD_Out_2;
                Unity_Multiply_float(IN.WorldSpaceNormal, (_Preview_64FE413E_Out_1.xxx), _Multiply_24E87ABD_Out_2);
                float _Property_824F2B83_Out_0 = Vector1_8C0B9D56;
                float3 _Multiply_D7E6F3AD_Out_2;
                Unity_Multiply_float(_Multiply_24E87ABD_Out_2, (_Property_824F2B83_Out_0.xxx), _Multiply_D7E6F3AD_Out_2);
                float3 _Add_48B19B00_Out_2;
                Unity_Add_float3(IN.WorldSpacePosition, _Multiply_D7E6F3AD_Out_2, _Add_48B19B00_Out_2);
                description.VertexPosition = _Add_48B19B00_Out_2;
                description.VertexNormal = IN.ObjectSpaceNormal;
                description.VertexTangent = IN.ObjectSpaceTangent;
                return description;
            }
            
            // Graph Pixel
            struct SurfaceDescriptionInputs
            {
                float3 TangentSpaceNormal;
                float3 WorldSpacePosition;
                float4 ScreenPosition;
            };
            
            struct SurfaceDescription
            {
                float Alpha;
                float AlphaClipThreshold;
            };
            
            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
            {
                SurfaceDescription surface = (SurfaceDescription)0;
                float _SceneDepth_4FAE51A0_Out_1;
                Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_4FAE51A0_Out_1);
                float4 _ScreenPosition_8E746D1E_Out_0 = IN.ScreenPosition;
                float _Split_94038860_R_1 = _ScreenPosition_8E746D1E_Out_0[0];
                float _Split_94038860_G_2 = _ScreenPosition_8E746D1E_Out_0[1];
                float _Split_94038860_B_3 = _ScreenPosition_8E746D1E_Out_0[2];
                float _Split_94038860_A_4 = _ScreenPosition_8E746D1E_Out_0[3];
                float _Subtract_42FE7ACD_Out_2;
                Unity_Subtract_float(_Split_94038860_A_4, 1, _Subtract_42FE7ACD_Out_2);
                float _Subtract_68104637_Out_2;
                Unity_Subtract_float(_SceneDepth_4FAE51A0_Out_1, _Subtract_42FE7ACD_Out_2, _Subtract_68104637_Out_2);
                float _Divide_564AD5D6_Out_2;
                Unity_Divide_float(_Subtract_68104637_Out_2, 100, _Divide_564AD5D6_Out_2);
                float _Saturate_2F42B045_Out_1;
                Unity_Saturate_float(_Divide_564AD5D6_Out_2, _Saturate_2F42B045_Out_1);
                surface.Alpha = _Saturate_2F42B045_Out_1;
                surface.AlphaClipThreshold = 0;
                return surface;
            }
        
            // --------------------------------------------------
            // Structs and Packing
        
            // Generated Type: Attributes
            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : INSTANCEID_SEMANTIC;
                #endif
            };
        
            // Generated Type: Varyings
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif
            };
            
            // Generated Type: PackedVaryings
            struct PackedVaryings
            {
                float4 positionCS : SV_POSITION;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif
                float3 interp00 : TEXCOORD0;
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif
            };
            
            // Packed Type: Varyings
            PackedVaryings PackVaryings(Varyings input)
            {
                PackedVaryings output = (PackedVaryings)0;
                output.positionCS = input.positionCS;
                output.interp00.xyz = input.positionWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif
                return output;
            }
            
            // Unpacked Type: Varyings
            Varyings UnpackVaryings(PackedVaryings input)
            {
                Varyings output = (Varyings)0;
                output.positionCS = input.positionCS;
                output.positionWS = input.interp00.xyz;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif
                return output;
            }
        
            // --------------------------------------------------
            // Build Graph Inputs
        
            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
            {
                VertexDescriptionInputs output;
                ZERO_INITIALIZE(VertexDescriptionInputs, output);
            
                output.ObjectSpaceNormal =           input.normalOS;
                output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
                output.ObjectSpaceTangent =          input.tangentOS;
                output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
                output.TimeParameters =              _TimeParameters.xyz;
            
                return output;
            }
            
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
            {
                SurfaceDescriptionInputs output;
                ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
            
            
            
                output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
            
            
                output.WorldSpacePosition =          input.positionWS;
                output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
            #else
            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
            #endif
            #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
            
                return output;
            }
            
        
            // --------------------------------------------------
            // Main
        
            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"
        
            ENDHLSL
        }
        
        Pass
        {
            Name "DepthOnly"
            Tags 
            { 
                "LightMode" = "DepthOnly"
            }
           
            // Render State
            Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
            Cull Off
            ZTest LEqual
            ZWrite On
            ColorMask 0
            
        
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
        
            // Debug
            // <None>
        
            // --------------------------------------------------
            // Pass
        
            // Pragmas
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            #pragma multi_compile_instancing
        
            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>
            
            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS 
            #define FEATURES_GRAPH_VERTEX
            #pragma multi_compile_instancing
            #define SHADERPASS_DEPTHONLY
            #define REQUIRE_DEPTH_TEXTURE
            
        
            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"
        
            // --------------------------------------------------
            // Graph
        
            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
            float4 Color_B178CEE1;
            float4 Color_8E13568A;
            float Vector1_8F542D29;
            float4 Color_1A413B9C;
            float Vector1_D7E2ED5C;
            float Vector1_D4B45908;
            float Vector1_48E1DFAE;
            float Vector1_8C0B9D56;
            float Vector1_CF216209;
            float Vector1_B33D0616;
            float Vector1_68A1BB04;
            CBUFFER_END
        
            // Graph Functions
            
            void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
            {
                Rotation = radians(Rotation);
            
                float s = sin(Rotation);
                float c = cos(Rotation);
                float one_minus_c = 1.0 - c;
                
                Axis = normalize(Axis);
            
                float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                          one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                          one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                        };
            
                Out = mul(rot_mat,  In);
            }
            
            void Unity_Multiply_float(float A, float B, out float Out)
            {
                Out = A * B;
            }
            
            void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
            {
                Out = UV * Tiling + Offset;
            }
            
            
            float2 Unity_GradientNoise_Dir_float(float2 p)
            {
                // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
                p = p % 289;
                float x = (34 * p.x + 1) * p.x % 289 + p.y;
                x = (34 * x + 1) * x % 289;
                x = frac(x / 41) * 2 - 1;
                return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
            }
            
            void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
            { 
                float2 p = UV * Scale;
                float2 ip = floor(p);
                float2 fp = frac(p);
                float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
                float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
                float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
                float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
                fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
                Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
            }
            
            void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
            {
                Out = A / B;
            }
            
            void Unity_Absolute_float3(float3 In, out float3 Out)
            {
                Out = abs(In);
            }
            
            void Unity_Add_float(float A, float B, out float Out)
            {
                Out = A + B;
            }
            
            void Unity_Saturate_float(float In, out float Out)
            {
                Out = saturate(In);
            }
            
            void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
            {
                Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
            }
            
            void Unity_Absolute_float(float In, out float Out)
            {
                Out = abs(In);
            }
            
            void Unity_Preview_float(float In, out float Out)
            {
                Out = In;
            }
            
            void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
            {
                Out = A * B;
            }
            
            void Unity_Add_float3(float3 A, float3 B, out float3 Out)
            {
                Out = A + B;
            }
            
            void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
            {
                Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
            }
            
            void Unity_Subtract_float(float A, float B, out float Out)
            {
                Out = A - B;
            }
            
            void Unity_Divide_float(float A, float B, out float Out)
            {
                Out = A / B;
            }
        
            // Graph Vertex
            struct VertexDescriptionInputs
            {
                float3 ObjectSpaceNormal;
                float3 WorldSpaceNormal;
                float3 ObjectSpaceTangent;
                float3 WorldSpacePosition;
                float3 TimeParameters;
            };
            
            struct VertexDescription
            {
                float3 VertexPosition;
                float3 VertexNormal;
                float3 VertexTangent;
            };
            
            VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
            {
                VertexDescription description = (VertexDescription)0;
                float3 _RotateAboutAxis_91AD6AAA_Out_3;
                Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, float3 (0, 1, 0), 90, _RotateAboutAxis_91AD6AAA_Out_3);
                float _Property_440EEBE_Out_0 = Vector1_D4B45908;
                float _Multiply_914B86AC_Out_2;
                Unity_Multiply_float(IN.TimeParameters.x, _Property_440EEBE_Out_0, _Multiply_914B86AC_Out_2);
                float2 _TilingAndOffset_6D6DAF34_Out_3;
                Unity_TilingAndOffset_float((_RotateAboutAxis_91AD6AAA_Out_3.xy), float2 (1, 1), (_Multiply_914B86AC_Out_2.xx), _TilingAndOffset_6D6DAF34_Out_3);
                float _Property_BB4F9425_Out_0 = Vector1_D7E2ED5C;
                float _GradientNoise_18198810_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_6D6DAF34_Out_3, _Property_BB4F9425_Out_0, _GradientNoise_18198810_Out_2);
                float3 _Divide_7C88F776_Out_2;
                Unity_Divide_float3(IN.WorldSpaceNormal, float3(1.5, 1.5, 1.5), _Divide_7C88F776_Out_2);
                float3 _Absolute_ECFC2C75_Out_1;
                Unity_Absolute_float3(_Divide_7C88F776_Out_2, _Absolute_ECFC2C75_Out_1);
                float _Split_21AEC44A_R_1 = _Absolute_ECFC2C75_Out_1[0];
                float _Split_21AEC44A_G_2 = _Absolute_ECFC2C75_Out_1[1];
                float _Split_21AEC44A_B_3 = _Absolute_ECFC2C75_Out_1[2];
                float _Split_21AEC44A_A_4 = 0;
                float _Multiply_8B950EF7_Out_2;
                Unity_Multiply_float(_GradientNoise_18198810_Out_2, _Split_21AEC44A_R_1, _Multiply_8B950EF7_Out_2);
                float3 _RotateAboutAxis_AFC207A1_Out_3;
                Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, float3 (1, 0, 0), 90, _RotateAboutAxis_AFC207A1_Out_3);
                float _Add_E7BCDB67_Out_2;
                Unity_Add_float(_Multiply_914B86AC_Out_2, 10, _Add_E7BCDB67_Out_2);
                float2 _TilingAndOffset_FEAB0DCE_Out_3;
                Unity_TilingAndOffset_float((_RotateAboutAxis_AFC207A1_Out_3.xy), float2 (1, 1), (_Add_E7BCDB67_Out_2.xx), _TilingAndOffset_FEAB0DCE_Out_3);
                float _GradientNoise_6537B291_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_FEAB0DCE_Out_3, _Property_BB4F9425_Out_0, _GradientNoise_6537B291_Out_2);
                float _Multiply_F8FE6501_Out_2;
                Unity_Multiply_float(_GradientNoise_6537B291_Out_2, _Split_21AEC44A_G_2, _Multiply_F8FE6501_Out_2);
                float _Add_9F8877A3_Out_2;
                Unity_Add_float(_Multiply_8B950EF7_Out_2, _Multiply_F8FE6501_Out_2, _Add_9F8877A3_Out_2);
                float _Add_6C11A02A_Out_2;
                Unity_Add_float(_Multiply_914B86AC_Out_2, 20, _Add_6C11A02A_Out_2);
                float2 _TilingAndOffset_CEF11ADD_Out_3;
                Unity_TilingAndOffset_float((IN.WorldSpacePosition.xy), float2 (1, 1), (_Add_6C11A02A_Out_2.xx), _TilingAndOffset_CEF11ADD_Out_3);
                float _GradientNoise_1C72BDE1_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_CEF11ADD_Out_3, _Property_BB4F9425_Out_0, _GradientNoise_1C72BDE1_Out_2);
                float _Multiply_21A8A37D_Out_2;
                Unity_Multiply_float(_GradientNoise_1C72BDE1_Out_2, _Split_21AEC44A_B_3, _Multiply_21A8A37D_Out_2);
                float _Add_88EE8F5F_Out_2;
                Unity_Add_float(_Add_9F8877A3_Out_2, _Multiply_21A8A37D_Out_2, _Add_88EE8F5F_Out_2);
                float _Saturate_2CDD9D86_Out_1;
                Unity_Saturate_float(_Add_88EE8F5F_Out_2, _Saturate_2CDD9D86_Out_1);
                float _Remap_B00EE626_Out_3;
                Unity_Remap_float(_Saturate_2CDD9D86_Out_1, float2 (0, 1), float2 (-1, 1), _Remap_B00EE626_Out_3);
                float _Absolute_CB429FCB_Out_1;
                Unity_Absolute_float(_Remap_B00EE626_Out_3, _Absolute_CB429FCB_Out_1);
                float _Preview_64FE413E_Out_1;
                Unity_Preview_float(_Absolute_CB429FCB_Out_1, _Preview_64FE413E_Out_1);
                float3 _Multiply_24E87ABD_Out_2;
                Unity_Multiply_float(IN.WorldSpaceNormal, (_Preview_64FE413E_Out_1.xxx), _Multiply_24E87ABD_Out_2);
                float _Property_824F2B83_Out_0 = Vector1_8C0B9D56;
                float3 _Multiply_D7E6F3AD_Out_2;
                Unity_Multiply_float(_Multiply_24E87ABD_Out_2, (_Property_824F2B83_Out_0.xxx), _Multiply_D7E6F3AD_Out_2);
                float3 _Add_48B19B00_Out_2;
                Unity_Add_float3(IN.WorldSpacePosition, _Multiply_D7E6F3AD_Out_2, _Add_48B19B00_Out_2);
                description.VertexPosition = _Add_48B19B00_Out_2;
                description.VertexNormal = IN.ObjectSpaceNormal;
                description.VertexTangent = IN.ObjectSpaceTangent;
                return description;
            }
            
            // Graph Pixel
            struct SurfaceDescriptionInputs
            {
                float3 TangentSpaceNormal;
                float3 WorldSpacePosition;
                float4 ScreenPosition;
            };
            
            struct SurfaceDescription
            {
                float Alpha;
                float AlphaClipThreshold;
            };
            
            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
            {
                SurfaceDescription surface = (SurfaceDescription)0;
                float _SceneDepth_4FAE51A0_Out_1;
                Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_4FAE51A0_Out_1);
                float4 _ScreenPosition_8E746D1E_Out_0 = IN.ScreenPosition;
                float _Split_94038860_R_1 = _ScreenPosition_8E746D1E_Out_0[0];
                float _Split_94038860_G_2 = _ScreenPosition_8E746D1E_Out_0[1];
                float _Split_94038860_B_3 = _ScreenPosition_8E746D1E_Out_0[2];
                float _Split_94038860_A_4 = _ScreenPosition_8E746D1E_Out_0[3];
                float _Subtract_42FE7ACD_Out_2;
                Unity_Subtract_float(_Split_94038860_A_4, 1, _Subtract_42FE7ACD_Out_2);
                float _Subtract_68104637_Out_2;
                Unity_Subtract_float(_SceneDepth_4FAE51A0_Out_1, _Subtract_42FE7ACD_Out_2, _Subtract_68104637_Out_2);
                float _Divide_564AD5D6_Out_2;
                Unity_Divide_float(_Subtract_68104637_Out_2, 100, _Divide_564AD5D6_Out_2);
                float _Saturate_2F42B045_Out_1;
                Unity_Saturate_float(_Divide_564AD5D6_Out_2, _Saturate_2F42B045_Out_1);
                surface.Alpha = _Saturate_2F42B045_Out_1;
                surface.AlphaClipThreshold = 0;
                return surface;
            }
        
            // --------------------------------------------------
            // Structs and Packing
        
            // Generated Type: Attributes
            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : INSTANCEID_SEMANTIC;
                #endif
            };
        
            // Generated Type: Varyings
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif
            };
            
            // Generated Type: PackedVaryings
            struct PackedVaryings
            {
                float4 positionCS : SV_POSITION;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif
                float3 interp00 : TEXCOORD0;
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif
            };
            
            // Packed Type: Varyings
            PackedVaryings PackVaryings(Varyings input)
            {
                PackedVaryings output = (PackedVaryings)0;
                output.positionCS = input.positionCS;
                output.interp00.xyz = input.positionWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif
                return output;
            }
            
            // Unpacked Type: Varyings
            Varyings UnpackVaryings(PackedVaryings input)
            {
                Varyings output = (Varyings)0;
                output.positionCS = input.positionCS;
                output.positionWS = input.interp00.xyz;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif
                return output;
            }
        
            // --------------------------------------------------
            // Build Graph Inputs
        
            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
            {
                VertexDescriptionInputs output;
                ZERO_INITIALIZE(VertexDescriptionInputs, output);
            
                output.ObjectSpaceNormal =           input.normalOS;
                output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
                output.ObjectSpaceTangent =          input.tangentOS;
                output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
                output.TimeParameters =              _TimeParameters.xyz;
            
                return output;
            }
            
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
            {
                SurfaceDescriptionInputs output;
                ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
            
            
            
                output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
            
            
                output.WorldSpacePosition =          input.positionWS;
                output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
            #else
            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
            #endif
            #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
            
                return output;
            }
            
        
            // --------------------------------------------------
            // Main
        
            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"
        
            ENDHLSL
        }
        
        Pass
        {
            Name "Meta"
            Tags 
            { 
                "LightMode" = "Meta"
            }
           
            // Render State
            Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
            Cull Off
            ZTest LEqual
            ZWrite On
            // ColorMask: <None>
            
        
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
        
            // Debug
            // <None>
        
            // --------------------------------------------------
            // Pass
        
            // Pragmas
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
        
            // Keywords
            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            // GraphKeywords: <None>
            
            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            #define VARYINGS_NEED_POSITION_WS 
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define FEATURES_GRAPH_VERTEX
            #pragma multi_compile_instancing
            #define SHADERPASS_META
            #define REQUIRE_DEPTH_TEXTURE
            
        
            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"
        
            // --------------------------------------------------
            // Graph
        
            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
            float4 Color_B178CEE1;
            float4 Color_8E13568A;
            float Vector1_8F542D29;
            float4 Color_1A413B9C;
            float Vector1_D7E2ED5C;
            float Vector1_D4B45908;
            float Vector1_48E1DFAE;
            float Vector1_8C0B9D56;
            float Vector1_CF216209;
            float Vector1_B33D0616;
            float Vector1_68A1BB04;
            CBUFFER_END
        
            // Graph Functions
            
            void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
            {
                Rotation = radians(Rotation);
            
                float s = sin(Rotation);
                float c = cos(Rotation);
                float one_minus_c = 1.0 - c;
                
                Axis = normalize(Axis);
            
                float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                          one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                          one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                        };
            
                Out = mul(rot_mat,  In);
            }
            
            void Unity_Multiply_float(float A, float B, out float Out)
            {
                Out = A * B;
            }
            
            void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
            {
                Out = UV * Tiling + Offset;
            }
            
            
            float2 Unity_GradientNoise_Dir_float(float2 p)
            {
                // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
                p = p % 289;
                float x = (34 * p.x + 1) * p.x % 289 + p.y;
                x = (34 * x + 1) * x % 289;
                x = frac(x / 41) * 2 - 1;
                return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
            }
            
            void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
            { 
                float2 p = UV * Scale;
                float2 ip = floor(p);
                float2 fp = frac(p);
                float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
                float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
                float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
                float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
                fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
                Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
            }
            
            void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
            {
                Out = A / B;
            }
            
            void Unity_Absolute_float3(float3 In, out float3 Out)
            {
                Out = abs(In);
            }
            
            void Unity_Add_float(float A, float B, out float Out)
            {
                Out = A + B;
            }
            
            void Unity_Saturate_float(float In, out float Out)
            {
                Out = saturate(In);
            }
            
            void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
            {
                Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
            }
            
            void Unity_Absolute_float(float In, out float Out)
            {
                Out = abs(In);
            }
            
            void Unity_Preview_float(float In, out float Out)
            {
                Out = In;
            }
            
            void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
            {
                Out = A * B;
            }
            
            void Unity_Add_float3(float3 A, float3 B, out float3 Out)
            {
                Out = A + B;
            }
            
            // 00222216c70f3619080ea66073823d54
            #include "Assets/Shaders/Includes/CustomLighting.hlsl"
            
            struct Bindings_GetMainLight_fc884d5c668d29144bb1456de0af6c36
            {
                float3 WorldSpacePosition;
            };
            
            void SG_GetMainLight_fc884d5c668d29144bb1456de0af6c36(Bindings_GetMainLight_fc884d5c668d29144bb1456de0af6c36 IN, out half3 Direction_0, out half3 Color_1, out half DistanceAtten_2, out half ShadowAtten_3)
            {
                half3 _CustomFunction_4BD45C5E_Direction_0;
                half3 _CustomFunction_4BD45C5E_Color_1;
                half _CustomFunction_4BD45C5E_DistanceAtten_2;
                half _CustomFunction_4BD45C5E_ShadowAtten_3;
                MainLight_half(IN.WorldSpacePosition, _CustomFunction_4BD45C5E_Direction_0, _CustomFunction_4BD45C5E_Color_1, _CustomFunction_4BD45C5E_DistanceAtten_2, _CustomFunction_4BD45C5E_ShadowAtten_3);
                Direction_0 = _CustomFunction_4BD45C5E_Direction_0;
                Color_1 = _CustomFunction_4BD45C5E_Color_1;
                DistanceAtten_2 = _CustomFunction_4BD45C5E_DistanceAtten_2;
                ShadowAtten_3 = _CustomFunction_4BD45C5E_ShadowAtten_3;
            }
            
            void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
            {
                Out = dot(A, B);
            }
            
            void Unity_Preview_float3(float3 In, out float3 Out)
            {
                Out = In;
            }
            
            struct Bindings_DirectSpecular_24c933b5392073e41adadf0d05cf8566
            {
                float3 WorldSpaceNormal;
                float3 WorldSpaceViewDirection;
            };
            
            void SG_DirectSpecular_24c933b5392073e41adadf0d05cf8566(float4 Color_F53B5328, float Vector1_74C1FACA, float3 Vector3_640FEED, float4 Color_C7E12EF8, Bindings_DirectSpecular_24c933b5392073e41adadf0d05cf8566 IN, out half3 Out_0)
            {
                float4 _Property_A34525CE_Out_0 = Color_F53B5328;
                float _Property_AF244E1C_Out_0 = Vector1_74C1FACA;
                float3 _Property_DF569F59_Out_0 = Vector3_640FEED;
                float4 _Property_B4E24E06_Out_0 = Color_C7E12EF8;
                half3 _CustomFunction_202FE61C_Out_6;
                DirectSpecular_half((_Property_A34525CE_Out_0.xyz), _Property_AF244E1C_Out_0, _Property_DF569F59_Out_0, (_Property_B4E24E06_Out_0.xyz), IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _CustomFunction_202FE61C_Out_6);
                Out_0 = _CustomFunction_202FE61C_Out_6;
            }
            
            struct Bindings_CalculateMainLight_92e70ea51fac8a443b9f65ee2812eea0
            {
                float3 WorldSpaceNormal;
                float3 WorldSpaceViewDirection;
                float3 WorldSpacePosition;
            };
            
            void SG_CalculateMainLight_92e70ea51fac8a443b9f65ee2812eea0(float4 Color_822DDD52, float Vector1_38A6B18D, Bindings_CalculateMainLight_92e70ea51fac8a443b9f65ee2812eea0 IN, out float3 Diffuse_0, out float3 Specular_1)
            {
                Bindings_GetMainLight_fc884d5c668d29144bb1456de0af6c36 _GetMainLight_2D1CB1B7;
                _GetMainLight_2D1CB1B7.WorldSpacePosition = IN.WorldSpacePosition;
                half3 _GetMainLight_2D1CB1B7_Direction_0;
                half3 _GetMainLight_2D1CB1B7_Color_1;
                half _GetMainLight_2D1CB1B7_DistanceAtten_2;
                half _GetMainLight_2D1CB1B7_ShadowAtten_3;
                SG_GetMainLight_fc884d5c668d29144bb1456de0af6c36(_GetMainLight_2D1CB1B7, _GetMainLight_2D1CB1B7_Direction_0, _GetMainLight_2D1CB1B7_Color_1, _GetMainLight_2D1CB1B7_DistanceAtten_2, _GetMainLight_2D1CB1B7_ShadowAtten_3);
                float _DotProduct_E144B168_Out_2;
                Unity_DotProduct_float3(IN.WorldSpaceNormal, _GetMainLight_2D1CB1B7_Direction_0, _DotProduct_E144B168_Out_2);
                float _Saturate_F1939154_Out_1;
                Unity_Saturate_float(_DotProduct_E144B168_Out_2, _Saturate_F1939154_Out_1);
                float _Multiply_BAF06DE_Out_2;
                Unity_Multiply_float(_GetMainLight_2D1CB1B7_DistanceAtten_2, _GetMainLight_2D1CB1B7_ShadowAtten_3, _Multiply_BAF06DE_Out_2);
                float3 _Multiply_C480EEAE_Out_2;
                Unity_Multiply_float(_GetMainLight_2D1CB1B7_Color_1, (_Multiply_BAF06DE_Out_2.xxx), _Multiply_C480EEAE_Out_2);
                float3 _Multiply_98E31ED4_Out_2;
                Unity_Multiply_float((_Saturate_F1939154_Out_1.xxx), _Multiply_C480EEAE_Out_2, _Multiply_98E31ED4_Out_2);
                float4 _Property_B38B1CFA_Out_0 = Color_822DDD52;
                float _Property_C1B6C566_Out_0 = Vector1_38A6B18D;
                float3 _Preview_634436FD_Out_1;
                Unity_Preview_float3(_GetMainLight_2D1CB1B7_Direction_0, _Preview_634436FD_Out_1);
                Bindings_DirectSpecular_24c933b5392073e41adadf0d05cf8566 _DirectSpecular_44AFF988;
                _DirectSpecular_44AFF988.WorldSpaceNormal = IN.WorldSpaceNormal;
                _DirectSpecular_44AFF988.WorldSpaceViewDirection = IN.WorldSpaceViewDirection;
                half3 _DirectSpecular_44AFF988_Out_0;
                SG_DirectSpecular_24c933b5392073e41adadf0d05cf8566(_Property_B38B1CFA_Out_0, _Property_C1B6C566_Out_0, _Preview_634436FD_Out_1, (float4(_Multiply_C480EEAE_Out_2, 1.0)), _DirectSpecular_44AFF988, _DirectSpecular_44AFF988_Out_0);
                Diffuse_0 = _Multiply_98E31ED4_Out_2;
                Specular_1 = _DirectSpecular_44AFF988_Out_0;
            }
            
            struct Bindings_CalculateAdditionalLights_fa66af11a916f9f42a5c85287ac3bd4b
            {
                float3 WorldSpaceNormal;
                float3 WorldSpaceViewDirection;
                float3 WorldSpacePosition;
            };
            
            void SG_CalculateAdditionalLights_fa66af11a916f9f42a5c85287ac3bd4b(float4 Color_E64814B9, float Vector1_CFCF55A, Bindings_CalculateAdditionalLights_fa66af11a916f9f42a5c85287ac3bd4b IN, out half3 Diffuse_0, out half3 Specular_1)
            {
                float4 _Property_9F8E76EC_Out_0 = Color_E64814B9;
                float _Property_EB4B8C51_Out_0 = Vector1_CFCF55A;
                half3 _CustomFunction_F94AA2B1_Diffuse_5;
                half3 _CustomFunction_F94AA2B1_Specular_6;
                AdditionalLights_half((_Property_9F8E76EC_Out_0.xyz), _Property_EB4B8C51_Out_0, IN.WorldSpacePosition, IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _CustomFunction_F94AA2B1_Diffuse_5, _CustomFunction_F94AA2B1_Specular_6);
                Diffuse_0 = _CustomFunction_F94AA2B1_Diffuse_5;
                Specular_1 = _CustomFunction_F94AA2B1_Specular_6;
            }
            
            void Unity_Normalize_float3(float3 In, out float3 Out)
            {
                Out = normalize(In);
            }
            
            void Unity_Multiply_float(float2 A, float2 B, out float2 Out)
            {
                Out = A * B;
            }
            
            void Unity_Add_float2(float2 A, float2 B, out float2 Out)
            {
                Out = A + B;
            }
            
            void Unity_Negate_float2(float2 In, out float2 Out)
            {
                Out = -1 * In;
            }
            
            void Unity_DotProduct_float2(float2 A, float2 B, out float Out)
            {
                Out = dot(A, B);
            }
            
            void Unity_Power_float(float A, float B, out float Out)
            {
                Out = pow(A, B);
            }
            
            void Unity_DotProduct_float(float A, float B, out float Out)
            {
                Out = dot(A, B);
            }
            
            void Unity_Multiply_float(float4 A, float4 B, out float4 Out)
            {
                Out = A * B;
            }
            
            void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
            {
                Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
            }
            
            void Unity_Subtract_float(float A, float B, out float Out)
            {
                Out = A - B;
            }
            
            void Unity_Divide_float(float A, float B, out float Out)
            {
                Out = A / B;
            }
        
            // Graph Vertex
            struct VertexDescriptionInputs
            {
                float3 ObjectSpaceNormal;
                float3 WorldSpaceNormal;
                float3 ObjectSpaceTangent;
                float3 WorldSpacePosition;
                float3 TimeParameters;
            };
            
            struct VertexDescription
            {
                float3 VertexPosition;
                float3 VertexNormal;
                float3 VertexTangent;
            };
            
            VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
            {
                VertexDescription description = (VertexDescription)0;
                float3 _RotateAboutAxis_91AD6AAA_Out_3;
                Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, float3 (0, 1, 0), 90, _RotateAboutAxis_91AD6AAA_Out_3);
                float _Property_440EEBE_Out_0 = Vector1_D4B45908;
                float _Multiply_914B86AC_Out_2;
                Unity_Multiply_float(IN.TimeParameters.x, _Property_440EEBE_Out_0, _Multiply_914B86AC_Out_2);
                float2 _TilingAndOffset_6D6DAF34_Out_3;
                Unity_TilingAndOffset_float((_RotateAboutAxis_91AD6AAA_Out_3.xy), float2 (1, 1), (_Multiply_914B86AC_Out_2.xx), _TilingAndOffset_6D6DAF34_Out_3);
                float _Property_BB4F9425_Out_0 = Vector1_D7E2ED5C;
                float _GradientNoise_18198810_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_6D6DAF34_Out_3, _Property_BB4F9425_Out_0, _GradientNoise_18198810_Out_2);
                float3 _Divide_7C88F776_Out_2;
                Unity_Divide_float3(IN.WorldSpaceNormal, float3(1.5, 1.5, 1.5), _Divide_7C88F776_Out_2);
                float3 _Absolute_ECFC2C75_Out_1;
                Unity_Absolute_float3(_Divide_7C88F776_Out_2, _Absolute_ECFC2C75_Out_1);
                float _Split_21AEC44A_R_1 = _Absolute_ECFC2C75_Out_1[0];
                float _Split_21AEC44A_G_2 = _Absolute_ECFC2C75_Out_1[1];
                float _Split_21AEC44A_B_3 = _Absolute_ECFC2C75_Out_1[2];
                float _Split_21AEC44A_A_4 = 0;
                float _Multiply_8B950EF7_Out_2;
                Unity_Multiply_float(_GradientNoise_18198810_Out_2, _Split_21AEC44A_R_1, _Multiply_8B950EF7_Out_2);
                float3 _RotateAboutAxis_AFC207A1_Out_3;
                Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, float3 (1, 0, 0), 90, _RotateAboutAxis_AFC207A1_Out_3);
                float _Add_E7BCDB67_Out_2;
                Unity_Add_float(_Multiply_914B86AC_Out_2, 10, _Add_E7BCDB67_Out_2);
                float2 _TilingAndOffset_FEAB0DCE_Out_3;
                Unity_TilingAndOffset_float((_RotateAboutAxis_AFC207A1_Out_3.xy), float2 (1, 1), (_Add_E7BCDB67_Out_2.xx), _TilingAndOffset_FEAB0DCE_Out_3);
                float _GradientNoise_6537B291_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_FEAB0DCE_Out_3, _Property_BB4F9425_Out_0, _GradientNoise_6537B291_Out_2);
                float _Multiply_F8FE6501_Out_2;
                Unity_Multiply_float(_GradientNoise_6537B291_Out_2, _Split_21AEC44A_G_2, _Multiply_F8FE6501_Out_2);
                float _Add_9F8877A3_Out_2;
                Unity_Add_float(_Multiply_8B950EF7_Out_2, _Multiply_F8FE6501_Out_2, _Add_9F8877A3_Out_2);
                float _Add_6C11A02A_Out_2;
                Unity_Add_float(_Multiply_914B86AC_Out_2, 20, _Add_6C11A02A_Out_2);
                float2 _TilingAndOffset_CEF11ADD_Out_3;
                Unity_TilingAndOffset_float((IN.WorldSpacePosition.xy), float2 (1, 1), (_Add_6C11A02A_Out_2.xx), _TilingAndOffset_CEF11ADD_Out_3);
                float _GradientNoise_1C72BDE1_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_CEF11ADD_Out_3, _Property_BB4F9425_Out_0, _GradientNoise_1C72BDE1_Out_2);
                float _Multiply_21A8A37D_Out_2;
                Unity_Multiply_float(_GradientNoise_1C72BDE1_Out_2, _Split_21AEC44A_B_3, _Multiply_21A8A37D_Out_2);
                float _Add_88EE8F5F_Out_2;
                Unity_Add_float(_Add_9F8877A3_Out_2, _Multiply_21A8A37D_Out_2, _Add_88EE8F5F_Out_2);
                float _Saturate_2CDD9D86_Out_1;
                Unity_Saturate_float(_Add_88EE8F5F_Out_2, _Saturate_2CDD9D86_Out_1);
                float _Remap_B00EE626_Out_3;
                Unity_Remap_float(_Saturate_2CDD9D86_Out_1, float2 (0, 1), float2 (-1, 1), _Remap_B00EE626_Out_3);
                float _Absolute_CB429FCB_Out_1;
                Unity_Absolute_float(_Remap_B00EE626_Out_3, _Absolute_CB429FCB_Out_1);
                float _Preview_64FE413E_Out_1;
                Unity_Preview_float(_Absolute_CB429FCB_Out_1, _Preview_64FE413E_Out_1);
                float3 _Multiply_24E87ABD_Out_2;
                Unity_Multiply_float(IN.WorldSpaceNormal, (_Preview_64FE413E_Out_1.xxx), _Multiply_24E87ABD_Out_2);
                float _Property_824F2B83_Out_0 = Vector1_8C0B9D56;
                float3 _Multiply_D7E6F3AD_Out_2;
                Unity_Multiply_float(_Multiply_24E87ABD_Out_2, (_Property_824F2B83_Out_0.xxx), _Multiply_D7E6F3AD_Out_2);
                float3 _Add_48B19B00_Out_2;
                Unity_Add_float3(IN.WorldSpacePosition, _Multiply_D7E6F3AD_Out_2, _Add_48B19B00_Out_2);
                description.VertexPosition = _Add_48B19B00_Out_2;
                description.VertexNormal = IN.ObjectSpaceNormal;
                description.VertexTangent = IN.ObjectSpaceTangent;
                return description;
            }
            
            // Graph Pixel
            struct SurfaceDescriptionInputs
            {
                float3 WorldSpaceNormal;
                float3 TangentSpaceNormal;
                float3 WorldSpaceViewDirection;
                float3 WorldSpacePosition;
                float4 ScreenPosition;
                float3 TimeParameters;
            };
            
            struct SurfaceDescription
            {
                float3 Albedo;
                float3 Emission;
                float Alpha;
                float AlphaClipThreshold;
            };
            
            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
            {
                SurfaceDescription surface = (SurfaceDescription)0;
                float4 _Property_B4F6F86A_Out_0 = Color_B178CEE1;
                float4 _Property_3A4FEE1_Out_0 = Color_8E13568A;
                float _Property_43B46B5B_Out_0 = Vector1_8F542D29;
                Bindings_CalculateMainLight_92e70ea51fac8a443b9f65ee2812eea0 _CalculateMainLight_B6933DFF;
                _CalculateMainLight_B6933DFF.WorldSpaceNormal = IN.WorldSpaceNormal;
                _CalculateMainLight_B6933DFF.WorldSpaceViewDirection = IN.WorldSpaceViewDirection;
                _CalculateMainLight_B6933DFF.WorldSpacePosition = IN.WorldSpacePosition;
                float3 _CalculateMainLight_B6933DFF_Diffuse_0;
                float3 _CalculateMainLight_B6933DFF_Specular_1;
                SG_CalculateMainLight_92e70ea51fac8a443b9f65ee2812eea0(_Property_3A4FEE1_Out_0, _Property_43B46B5B_Out_0, _CalculateMainLight_B6933DFF, _CalculateMainLight_B6933DFF_Diffuse_0, _CalculateMainLight_B6933DFF_Specular_1);
                Bindings_CalculateAdditionalLights_fa66af11a916f9f42a5c85287ac3bd4b _CalculateAdditionalLights_9BC46348;
                _CalculateAdditionalLights_9BC46348.WorldSpaceNormal = IN.WorldSpaceNormal;
                _CalculateAdditionalLights_9BC46348.WorldSpaceViewDirection = IN.WorldSpaceViewDirection;
                _CalculateAdditionalLights_9BC46348.WorldSpacePosition = IN.WorldSpacePosition;
                half3 _CalculateAdditionalLights_9BC46348_Diffuse_0;
                half3 _CalculateAdditionalLights_9BC46348_Specular_1;
                SG_CalculateAdditionalLights_fa66af11a916f9f42a5c85287ac3bd4b(_Property_3A4FEE1_Out_0, _Property_43B46B5B_Out_0, _CalculateAdditionalLights_9BC46348, _CalculateAdditionalLights_9BC46348_Diffuse_0, _CalculateAdditionalLights_9BC46348_Specular_1);
                float3 _Add_1CD24747_Out_2;
                Unity_Add_float3(_CalculateMainLight_B6933DFF_Diffuse_0, _CalculateAdditionalLights_9BC46348_Diffuse_0, _Add_1CD24747_Out_2);
                float3 _Add_F5A8978D_Out_2;
                Unity_Add_float3(_CalculateMainLight_B6933DFF_Specular_1, _CalculateAdditionalLights_9BC46348_Specular_1, _Add_F5A8978D_Out_2);
                float3 _Add_811BA667_Out_2;
                Unity_Add_float3(_Add_1CD24747_Out_2, _Add_F5A8978D_Out_2, _Add_811BA667_Out_2);
                float3 _Multiply_DEE8590F_Out_2;
                Unity_Multiply_float((_Property_B4F6F86A_Out_0.xyz), _Add_811BA667_Out_2, _Multiply_DEE8590F_Out_2);
                float3 _Normalize_ADBDED10_Out_1;
                Unity_Normalize_float3(IN.WorldSpaceViewDirection, _Normalize_ADBDED10_Out_1);
                Bindings_GetMainLight_fc884d5c668d29144bb1456de0af6c36 _GetMainLight_F1F4647E;
                _GetMainLight_F1F4647E.WorldSpacePosition = IN.WorldSpacePosition;
                half3 _GetMainLight_F1F4647E_Direction_0;
                half3 _GetMainLight_F1F4647E_Color_1;
                half _GetMainLight_F1F4647E_DistanceAtten_2;
                half _GetMainLight_F1F4647E_ShadowAtten_3;
                SG_GetMainLight_fc884d5c668d29144bb1456de0af6c36(_GetMainLight_F1F4647E, _GetMainLight_F1F4647E_Direction_0, _GetMainLight_F1F4647E_Color_1, _GetMainLight_F1F4647E_DistanceAtten_2, _GetMainLight_F1F4647E_ShadowAtten_3);
                float3 _RotateAboutAxis_91AD6AAA_Out_3;
                Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, float3 (0, 1, 0), 90, _RotateAboutAxis_91AD6AAA_Out_3);
                float _Property_440EEBE_Out_0 = Vector1_D4B45908;
                float _Multiply_914B86AC_Out_2;
                Unity_Multiply_float(IN.TimeParameters.x, _Property_440EEBE_Out_0, _Multiply_914B86AC_Out_2);
                float2 _TilingAndOffset_6D6DAF34_Out_3;
                Unity_TilingAndOffset_float((_RotateAboutAxis_91AD6AAA_Out_3.xy), float2 (1, 1), (_Multiply_914B86AC_Out_2.xx), _TilingAndOffset_6D6DAF34_Out_3);
                float _Property_BB4F9425_Out_0 = Vector1_D7E2ED5C;
                float _GradientNoise_18198810_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_6D6DAF34_Out_3, _Property_BB4F9425_Out_0, _GradientNoise_18198810_Out_2);
                float3 _Divide_7C88F776_Out_2;
                Unity_Divide_float3(IN.WorldSpaceNormal, float3(1.5, 1.5, 1.5), _Divide_7C88F776_Out_2);
                float3 _Absolute_ECFC2C75_Out_1;
                Unity_Absolute_float3(_Divide_7C88F776_Out_2, _Absolute_ECFC2C75_Out_1);
                float _Split_21AEC44A_R_1 = _Absolute_ECFC2C75_Out_1[0];
                float _Split_21AEC44A_G_2 = _Absolute_ECFC2C75_Out_1[1];
                float _Split_21AEC44A_B_3 = _Absolute_ECFC2C75_Out_1[2];
                float _Split_21AEC44A_A_4 = 0;
                float _Multiply_8B950EF7_Out_2;
                Unity_Multiply_float(_GradientNoise_18198810_Out_2, _Split_21AEC44A_R_1, _Multiply_8B950EF7_Out_2);
                float3 _RotateAboutAxis_AFC207A1_Out_3;
                Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, float3 (1, 0, 0), 90, _RotateAboutAxis_AFC207A1_Out_3);
                float _Add_E7BCDB67_Out_2;
                Unity_Add_float(_Multiply_914B86AC_Out_2, 10, _Add_E7BCDB67_Out_2);
                float2 _TilingAndOffset_FEAB0DCE_Out_3;
                Unity_TilingAndOffset_float((_RotateAboutAxis_AFC207A1_Out_3.xy), float2 (1, 1), (_Add_E7BCDB67_Out_2.xx), _TilingAndOffset_FEAB0DCE_Out_3);
                float _GradientNoise_6537B291_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_FEAB0DCE_Out_3, _Property_BB4F9425_Out_0, _GradientNoise_6537B291_Out_2);
                float _Multiply_F8FE6501_Out_2;
                Unity_Multiply_float(_GradientNoise_6537B291_Out_2, _Split_21AEC44A_G_2, _Multiply_F8FE6501_Out_2);
                float _Add_9F8877A3_Out_2;
                Unity_Add_float(_Multiply_8B950EF7_Out_2, _Multiply_F8FE6501_Out_2, _Add_9F8877A3_Out_2);
                float _Add_6C11A02A_Out_2;
                Unity_Add_float(_Multiply_914B86AC_Out_2, 20, _Add_6C11A02A_Out_2);
                float2 _TilingAndOffset_CEF11ADD_Out_3;
                Unity_TilingAndOffset_float((IN.WorldSpacePosition.xy), float2 (1, 1), (_Add_6C11A02A_Out_2.xx), _TilingAndOffset_CEF11ADD_Out_3);
                float _GradientNoise_1C72BDE1_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_CEF11ADD_Out_3, _Property_BB4F9425_Out_0, _GradientNoise_1C72BDE1_Out_2);
                float _Multiply_21A8A37D_Out_2;
                Unity_Multiply_float(_GradientNoise_1C72BDE1_Out_2, _Split_21AEC44A_B_3, _Multiply_21A8A37D_Out_2);
                float _Add_88EE8F5F_Out_2;
                Unity_Add_float(_Add_9F8877A3_Out_2, _Multiply_21A8A37D_Out_2, _Add_88EE8F5F_Out_2);
                float _Saturate_2CDD9D86_Out_1;
                Unity_Saturate_float(_Add_88EE8F5F_Out_2, _Saturate_2CDD9D86_Out_1);
                float _Remap_B00EE626_Out_3;
                Unity_Remap_float(_Saturate_2CDD9D86_Out_1, float2 (0, 1), float2 (-1, 1), _Remap_B00EE626_Out_3);
                float _Absolute_CB429FCB_Out_1;
                Unity_Absolute_float(_Remap_B00EE626_Out_3, _Absolute_CB429FCB_Out_1);
                float _Preview_C22952E7_Out_1;
                Unity_Preview_float(_Absolute_CB429FCB_Out_1, _Preview_C22952E7_Out_1);
                float _Property_BB76C5B6_Out_0 = Vector1_48E1DFAE;
                float _Multiply_81A6A00C_Out_2;
                Unity_Multiply_float(_Preview_C22952E7_Out_1, _Property_BB76C5B6_Out_0, _Multiply_81A6A00C_Out_2);
                float2 _TilingAndOffset_312095F8_Out_3;
                Unity_TilingAndOffset_float((IN.WorldSpaceNormal.xy), float2 (1, 1), (_Multiply_81A6A00C_Out_2.xx), _TilingAndOffset_312095F8_Out_3);
                float _Property_EEE36D56_Out_0 = Vector1_CF216209;
                float2 _Multiply_D39564EF_Out_2;
                Unity_Multiply_float(_TilingAndOffset_312095F8_Out_3, (_Property_EEE36D56_Out_0.xx), _Multiply_D39564EF_Out_2);
                float2 _Add_48906C90_Out_2;
                Unity_Add_float2((_GetMainLight_F1F4647E_Direction_0.xy), _Multiply_D39564EF_Out_2, _Add_48906C90_Out_2);
                float2 _Negate_738EA4EA_Out_1;
                Unity_Negate_float2(_Add_48906C90_Out_2, _Negate_738EA4EA_Out_1);
                float _DotProduct_38B3399_Out_2;
                Unity_DotProduct_float2((_Normalize_ADBDED10_Out_1.xy), _Negate_738EA4EA_Out_1, _DotProduct_38B3399_Out_2);
                float _Property_49C48C1_Out_0 = Vector1_B33D0616;
                float _Power_36F9A28C_Out_2;
                Unity_Power_float(_DotProduct_38B3399_Out_2, _Property_49C48C1_Out_0, _Power_36F9A28C_Out_2);
                float _Property_EE224157_Out_0 = Vector1_68A1BB04;
                float _DotProduct_3F168FC8_Out_2;
                Unity_DotProduct_float(_Power_36F9A28C_Out_2, _Property_EE224157_Out_0, _DotProduct_3F168FC8_Out_2);
                float _Saturate_FFB08A4E_Out_1;
                Unity_Saturate_float(_DotProduct_3F168FC8_Out_2, _Saturate_FFB08A4E_Out_1);
                Bindings_GetMainLight_fc884d5c668d29144bb1456de0af6c36 _GetMainLight_9F13029;
                _GetMainLight_9F13029.WorldSpacePosition = IN.WorldSpacePosition;
                half3 _GetMainLight_9F13029_Direction_0;
                half3 _GetMainLight_9F13029_Color_1;
                half _GetMainLight_9F13029_DistanceAtten_2;
                half _GetMainLight_9F13029_ShadowAtten_3;
                SG_GetMainLight_fc884d5c668d29144bb1456de0af6c36(_GetMainLight_9F13029, _GetMainLight_9F13029_Direction_0, _GetMainLight_9F13029_Color_1, _GetMainLight_9F13029_DistanceAtten_2, _GetMainLight_9F13029_ShadowAtten_3);
                float3 _Multiply_4ADD9031_Out_2;
                Unity_Multiply_float((_Saturate_FFB08A4E_Out_1.xxx), _GetMainLight_9F13029_Color_1, _Multiply_4ADD9031_Out_2);
                float3 _Multiply_59470CF4_Out_2;
                Unity_Multiply_float((_Property_B4F6F86A_Out_0.xyz), _Multiply_4ADD9031_Out_2, _Multiply_59470CF4_Out_2);
                float3 _Add_4F9D38F7_Out_2;
                Unity_Add_float3(_Multiply_DEE8590F_Out_2, _Multiply_59470CF4_Out_2, _Add_4F9D38F7_Out_2);
                float4 _Property_3351416A_Out_0 = Color_1A413B9C;
                float4 _Multiply_42A7AC12_Out_2;
                Unity_Multiply_float(_Property_3351416A_Out_0, _Property_B4F6F86A_Out_0, _Multiply_42A7AC12_Out_2);
                float3 _Add_B33784D3_Out_2;
                Unity_Add_float3(_Add_4F9D38F7_Out_2, (_Multiply_42A7AC12_Out_2.xyz), _Add_B33784D3_Out_2);
                float _SceneDepth_4FAE51A0_Out_1;
                Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_4FAE51A0_Out_1);
                float4 _ScreenPosition_8E746D1E_Out_0 = IN.ScreenPosition;
                float _Split_94038860_R_1 = _ScreenPosition_8E746D1E_Out_0[0];
                float _Split_94038860_G_2 = _ScreenPosition_8E746D1E_Out_0[1];
                float _Split_94038860_B_3 = _ScreenPosition_8E746D1E_Out_0[2];
                float _Split_94038860_A_4 = _ScreenPosition_8E746D1E_Out_0[3];
                float _Subtract_42FE7ACD_Out_2;
                Unity_Subtract_float(_Split_94038860_A_4, 1, _Subtract_42FE7ACD_Out_2);
                float _Subtract_68104637_Out_2;
                Unity_Subtract_float(_SceneDepth_4FAE51A0_Out_1, _Subtract_42FE7ACD_Out_2, _Subtract_68104637_Out_2);
                float _Divide_564AD5D6_Out_2;
                Unity_Divide_float(_Subtract_68104637_Out_2, 100, _Divide_564AD5D6_Out_2);
                float _Saturate_2F42B045_Out_1;
                Unity_Saturate_float(_Divide_564AD5D6_Out_2, _Saturate_2F42B045_Out_1);
                surface.Albedo = IsGammaSpace() ? float3(0, 0, 0) : SRGBToLinear(float3(0, 0, 0));
                surface.Emission = _Add_B33784D3_Out_2;
                surface.Alpha = _Saturate_2F42B045_Out_1;
                surface.AlphaClipThreshold = 0;
                return surface;
            }
        
            // --------------------------------------------------
            // Structs and Packing
        
            // Generated Type: Attributes
            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float4 uv1 : TEXCOORD1;
                float4 uv2 : TEXCOORD2;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : INSTANCEID_SEMANTIC;
                #endif
            };
        
            // Generated Type: Varyings
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS;
                float3 normalWS;
                float3 viewDirectionWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif
            };
            
            // Generated Type: PackedVaryings
            struct PackedVaryings
            {
                float4 positionCS : SV_POSITION;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif
                float3 interp00 : TEXCOORD0;
                float3 interp01 : TEXCOORD1;
                float3 interp02 : TEXCOORD2;
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif
            };
            
            // Packed Type: Varyings
            PackedVaryings PackVaryings(Varyings input)
            {
                PackedVaryings output = (PackedVaryings)0;
                output.positionCS = input.positionCS;
                output.interp00.xyz = input.positionWS;
                output.interp01.xyz = input.normalWS;
                output.interp02.xyz = input.viewDirectionWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif
                return output;
            }
            
            // Unpacked Type: Varyings
            Varyings UnpackVaryings(PackedVaryings input)
            {
                Varyings output = (Varyings)0;
                output.positionCS = input.positionCS;
                output.positionWS = input.interp00.xyz;
                output.normalWS = input.interp01.xyz;
                output.viewDirectionWS = input.interp02.xyz;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif
                return output;
            }
        
            // --------------------------------------------------
            // Build Graph Inputs
        
            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
            {
                VertexDescriptionInputs output;
                ZERO_INITIALIZE(VertexDescriptionInputs, output);
            
                output.ObjectSpaceNormal =           input.normalOS;
                output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
                output.ObjectSpaceTangent =          input.tangentOS;
                output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
                output.TimeParameters =              _TimeParameters.xyz;
            
                return output;
            }
            
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
            {
                SurfaceDescriptionInputs output;
                ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
            
            	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            	float3 unnormalizedNormalWS = input.normalWS;
                const float renormFactor = 1.0 / length(unnormalizedNormalWS);
            
            
                output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
                output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
            
            
                output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
                output.WorldSpacePosition =          input.positionWS;
                output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
                output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
            #else
            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
            #endif
            #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
            
                return output;
            }
            
        
            // --------------------------------------------------
            // Main
        
            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"
        
            ENDHLSL
        }
        
        Pass
        {
            // Name: <None>
            Tags 
            { 
                "LightMode" = "Universal2D"
            }
           
            // Render State
            Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
            Cull Off
            ZTest LEqual
            ZWrite On
            // ColorMask: <None>
            
        
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
        
            // Debug
            // <None>
        
            // --------------------------------------------------
            // Pass
        
            // Pragmas
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            #pragma multi_compile_instancing
        
            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>
            
            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS 
            #define FEATURES_GRAPH_VERTEX
            #pragma multi_compile_instancing
            #define SHADERPASS_2D
            #define REQUIRE_DEPTH_TEXTURE
            
        
            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"
        
            // --------------------------------------------------
            // Graph
        
            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
            float4 Color_B178CEE1;
            float4 Color_8E13568A;
            float Vector1_8F542D29;
            float4 Color_1A413B9C;
            float Vector1_D7E2ED5C;
            float Vector1_D4B45908;
            float Vector1_48E1DFAE;
            float Vector1_8C0B9D56;
            float Vector1_CF216209;
            float Vector1_B33D0616;
            float Vector1_68A1BB04;
            CBUFFER_END
        
            // Graph Functions
            
            void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
            {
                Rotation = radians(Rotation);
            
                float s = sin(Rotation);
                float c = cos(Rotation);
                float one_minus_c = 1.0 - c;
                
                Axis = normalize(Axis);
            
                float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                          one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                          one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                        };
            
                Out = mul(rot_mat,  In);
            }
            
            void Unity_Multiply_float(float A, float B, out float Out)
            {
                Out = A * B;
            }
            
            void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
            {
                Out = UV * Tiling + Offset;
            }
            
            
            float2 Unity_GradientNoise_Dir_float(float2 p)
            {
                // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
                p = p % 289;
                float x = (34 * p.x + 1) * p.x % 289 + p.y;
                x = (34 * x + 1) * x % 289;
                x = frac(x / 41) * 2 - 1;
                return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
            }
            
            void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
            { 
                float2 p = UV * Scale;
                float2 ip = floor(p);
                float2 fp = frac(p);
                float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
                float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
                float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
                float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
                fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
                Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
            }
            
            void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
            {
                Out = A / B;
            }
            
            void Unity_Absolute_float3(float3 In, out float3 Out)
            {
                Out = abs(In);
            }
            
            void Unity_Add_float(float A, float B, out float Out)
            {
                Out = A + B;
            }
            
            void Unity_Saturate_float(float In, out float Out)
            {
                Out = saturate(In);
            }
            
            void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
            {
                Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
            }
            
            void Unity_Absolute_float(float In, out float Out)
            {
                Out = abs(In);
            }
            
            void Unity_Preview_float(float In, out float Out)
            {
                Out = In;
            }
            
            void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
            {
                Out = A * B;
            }
            
            void Unity_Add_float3(float3 A, float3 B, out float3 Out)
            {
                Out = A + B;
            }
            
            void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
            {
                Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
            }
            
            void Unity_Subtract_float(float A, float B, out float Out)
            {
                Out = A - B;
            }
            
            void Unity_Divide_float(float A, float B, out float Out)
            {
                Out = A / B;
            }
        
            // Graph Vertex
            struct VertexDescriptionInputs
            {
                float3 ObjectSpaceNormal;
                float3 WorldSpaceNormal;
                float3 ObjectSpaceTangent;
                float3 WorldSpacePosition;
                float3 TimeParameters;
            };
            
            struct VertexDescription
            {
                float3 VertexPosition;
                float3 VertexNormal;
                float3 VertexTangent;
            };
            
            VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
            {
                VertexDescription description = (VertexDescription)0;
                float3 _RotateAboutAxis_91AD6AAA_Out_3;
                Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, float3 (0, 1, 0), 90, _RotateAboutAxis_91AD6AAA_Out_3);
                float _Property_440EEBE_Out_0 = Vector1_D4B45908;
                float _Multiply_914B86AC_Out_2;
                Unity_Multiply_float(IN.TimeParameters.x, _Property_440EEBE_Out_0, _Multiply_914B86AC_Out_2);
                float2 _TilingAndOffset_6D6DAF34_Out_3;
                Unity_TilingAndOffset_float((_RotateAboutAxis_91AD6AAA_Out_3.xy), float2 (1, 1), (_Multiply_914B86AC_Out_2.xx), _TilingAndOffset_6D6DAF34_Out_3);
                float _Property_BB4F9425_Out_0 = Vector1_D7E2ED5C;
                float _GradientNoise_18198810_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_6D6DAF34_Out_3, _Property_BB4F9425_Out_0, _GradientNoise_18198810_Out_2);
                float3 _Divide_7C88F776_Out_2;
                Unity_Divide_float3(IN.WorldSpaceNormal, float3(1.5, 1.5, 1.5), _Divide_7C88F776_Out_2);
                float3 _Absolute_ECFC2C75_Out_1;
                Unity_Absolute_float3(_Divide_7C88F776_Out_2, _Absolute_ECFC2C75_Out_1);
                float _Split_21AEC44A_R_1 = _Absolute_ECFC2C75_Out_1[0];
                float _Split_21AEC44A_G_2 = _Absolute_ECFC2C75_Out_1[1];
                float _Split_21AEC44A_B_3 = _Absolute_ECFC2C75_Out_1[2];
                float _Split_21AEC44A_A_4 = 0;
                float _Multiply_8B950EF7_Out_2;
                Unity_Multiply_float(_GradientNoise_18198810_Out_2, _Split_21AEC44A_R_1, _Multiply_8B950EF7_Out_2);
                float3 _RotateAboutAxis_AFC207A1_Out_3;
                Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, float3 (1, 0, 0), 90, _RotateAboutAxis_AFC207A1_Out_3);
                float _Add_E7BCDB67_Out_2;
                Unity_Add_float(_Multiply_914B86AC_Out_2, 10, _Add_E7BCDB67_Out_2);
                float2 _TilingAndOffset_FEAB0DCE_Out_3;
                Unity_TilingAndOffset_float((_RotateAboutAxis_AFC207A1_Out_3.xy), float2 (1, 1), (_Add_E7BCDB67_Out_2.xx), _TilingAndOffset_FEAB0DCE_Out_3);
                float _GradientNoise_6537B291_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_FEAB0DCE_Out_3, _Property_BB4F9425_Out_0, _GradientNoise_6537B291_Out_2);
                float _Multiply_F8FE6501_Out_2;
                Unity_Multiply_float(_GradientNoise_6537B291_Out_2, _Split_21AEC44A_G_2, _Multiply_F8FE6501_Out_2);
                float _Add_9F8877A3_Out_2;
                Unity_Add_float(_Multiply_8B950EF7_Out_2, _Multiply_F8FE6501_Out_2, _Add_9F8877A3_Out_2);
                float _Add_6C11A02A_Out_2;
                Unity_Add_float(_Multiply_914B86AC_Out_2, 20, _Add_6C11A02A_Out_2);
                float2 _TilingAndOffset_CEF11ADD_Out_3;
                Unity_TilingAndOffset_float((IN.WorldSpacePosition.xy), float2 (1, 1), (_Add_6C11A02A_Out_2.xx), _TilingAndOffset_CEF11ADD_Out_3);
                float _GradientNoise_1C72BDE1_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_CEF11ADD_Out_3, _Property_BB4F9425_Out_0, _GradientNoise_1C72BDE1_Out_2);
                float _Multiply_21A8A37D_Out_2;
                Unity_Multiply_float(_GradientNoise_1C72BDE1_Out_2, _Split_21AEC44A_B_3, _Multiply_21A8A37D_Out_2);
                float _Add_88EE8F5F_Out_2;
                Unity_Add_float(_Add_9F8877A3_Out_2, _Multiply_21A8A37D_Out_2, _Add_88EE8F5F_Out_2);
                float _Saturate_2CDD9D86_Out_1;
                Unity_Saturate_float(_Add_88EE8F5F_Out_2, _Saturate_2CDD9D86_Out_1);
                float _Remap_B00EE626_Out_3;
                Unity_Remap_float(_Saturate_2CDD9D86_Out_1, float2 (0, 1), float2 (-1, 1), _Remap_B00EE626_Out_3);
                float _Absolute_CB429FCB_Out_1;
                Unity_Absolute_float(_Remap_B00EE626_Out_3, _Absolute_CB429FCB_Out_1);
                float _Preview_64FE413E_Out_1;
                Unity_Preview_float(_Absolute_CB429FCB_Out_1, _Preview_64FE413E_Out_1);
                float3 _Multiply_24E87ABD_Out_2;
                Unity_Multiply_float(IN.WorldSpaceNormal, (_Preview_64FE413E_Out_1.xxx), _Multiply_24E87ABD_Out_2);
                float _Property_824F2B83_Out_0 = Vector1_8C0B9D56;
                float3 _Multiply_D7E6F3AD_Out_2;
                Unity_Multiply_float(_Multiply_24E87ABD_Out_2, (_Property_824F2B83_Out_0.xxx), _Multiply_D7E6F3AD_Out_2);
                float3 _Add_48B19B00_Out_2;
                Unity_Add_float3(IN.WorldSpacePosition, _Multiply_D7E6F3AD_Out_2, _Add_48B19B00_Out_2);
                description.VertexPosition = _Add_48B19B00_Out_2;
                description.VertexNormal = IN.ObjectSpaceNormal;
                description.VertexTangent = IN.ObjectSpaceTangent;
                return description;
            }
            
            // Graph Pixel
            struct SurfaceDescriptionInputs
            {
                float3 TangentSpaceNormal;
                float3 WorldSpacePosition;
                float4 ScreenPosition;
            };
            
            struct SurfaceDescription
            {
                float3 Albedo;
                float Alpha;
                float AlphaClipThreshold;
            };
            
            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
            {
                SurfaceDescription surface = (SurfaceDescription)0;
                float _SceneDepth_4FAE51A0_Out_1;
                Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_4FAE51A0_Out_1);
                float4 _ScreenPosition_8E746D1E_Out_0 = IN.ScreenPosition;
                float _Split_94038860_R_1 = _ScreenPosition_8E746D1E_Out_0[0];
                float _Split_94038860_G_2 = _ScreenPosition_8E746D1E_Out_0[1];
                float _Split_94038860_B_3 = _ScreenPosition_8E746D1E_Out_0[2];
                float _Split_94038860_A_4 = _ScreenPosition_8E746D1E_Out_0[3];
                float _Subtract_42FE7ACD_Out_2;
                Unity_Subtract_float(_Split_94038860_A_4, 1, _Subtract_42FE7ACD_Out_2);
                float _Subtract_68104637_Out_2;
                Unity_Subtract_float(_SceneDepth_4FAE51A0_Out_1, _Subtract_42FE7ACD_Out_2, _Subtract_68104637_Out_2);
                float _Divide_564AD5D6_Out_2;
                Unity_Divide_float(_Subtract_68104637_Out_2, 100, _Divide_564AD5D6_Out_2);
                float _Saturate_2F42B045_Out_1;
                Unity_Saturate_float(_Divide_564AD5D6_Out_2, _Saturate_2F42B045_Out_1);
                surface.Albedo = IsGammaSpace() ? float3(0, 0, 0) : SRGBToLinear(float3(0, 0, 0));
                surface.Alpha = _Saturate_2F42B045_Out_1;
                surface.AlphaClipThreshold = 0;
                return surface;
            }
        
            // --------------------------------------------------
            // Structs and Packing
        
            // Generated Type: Attributes
            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : INSTANCEID_SEMANTIC;
                #endif
            };
        
            // Generated Type: Varyings
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif
            };
            
            // Generated Type: PackedVaryings
            struct PackedVaryings
            {
                float4 positionCS : SV_POSITION;
                #if UNITY_ANY_INSTANCING_ENABLED
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif
                float3 interp00 : TEXCOORD0;
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                #endif
            };
            
            // Packed Type: Varyings
            PackedVaryings PackVaryings(Varyings input)
            {
                PackedVaryings output = (PackedVaryings)0;
                output.positionCS = input.positionCS;
                output.interp00.xyz = input.positionWS;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif
                return output;
            }
            
            // Unpacked Type: Varyings
            Varyings UnpackVaryings(PackedVaryings input)
            {
                Varyings output = (Varyings)0;
                output.positionCS = input.positionCS;
                output.positionWS = input.interp00.xyz;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                #endif
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                output.cullFace = input.cullFace;
                #endif
                return output;
            }
        
            // --------------------------------------------------
            // Build Graph Inputs
        
            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
            {
                VertexDescriptionInputs output;
                ZERO_INITIALIZE(VertexDescriptionInputs, output);
            
                output.ObjectSpaceNormal =           input.normalOS;
                output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
                output.ObjectSpaceTangent =          input.tangentOS;
                output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
                output.TimeParameters =              _TimeParameters.xyz;
            
                return output;
            }
            
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
            {
                SurfaceDescriptionInputs output;
                ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
            
            
            
                output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
            
            
                output.WorldSpacePosition =          input.positionWS;
                output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
            #else
            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
            #endif
            #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
            
                return output;
            }
            
        
            // --------------------------------------------------
            // Main
        
            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"
        
            ENDHLSL
        }
        
    }
    CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
    FallBack "Hidden/Shader Graph/FallbackError"
}
