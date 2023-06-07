#include <renderer/RenderSetup.hlsl>

struct VS_INPUT
{
   float3 ssPosition   : POSITION;
   float2 texCoord     : TEXCOORD0;
   float4 color        : COLOR0;
};

struct VS_OUTPUT
{
   float2 texCoord     : TEXCOORD0;
   float4 color        : COLOR0;
   float4 ssPosition   : SV_POSITION;
};

struct PS_INPUT
{
   float2 texCoord     : TEXCOORD0;
   float4 color        : COLOR0;
};

sampler2D       baseTexture;
sampler2D       depthTexture;
sampler2D       normalTexture;

cbuffer LayerConstants
{
    float        startTime;
    float        amount;
};

/**
* Vertex shader.
*/  
VS_OUTPUT SFXBasicVS(VS_INPUT input)
{

   VS_OUTPUT output;

   output.ssPosition = float4(input.ssPosition, 1);
   output.texCoord   = input.texCoord + texelCenter;
   output.color      = input.color;

   return output;

}

float2 clamp_tex2D( sampler2D tex, float2 coord )
{
    // TODO: remove this and fix sampler using wrapped instead of clamped addressing for depthTexture
    return tex2D( tex, clamp( coord, float2( 0.001, 0.001 ), float2( 0.999, 0.999 ) ) );
}

const float4 edgeColorBlue = float4(0.0, 0.35, 1, 0) * 6.0;
const float4 edgeColorDarkBlue = float4(0, 0.5, 1, 0) * 6.0;
const float4 edgeColorOrange = float4(1.0, 0.05, 0.0, 0) * 8.0;
const float4 edgeColorDarkOrange = float4(0.8, 0.2, 0, 0) * 6.0;
const float4 edgeColorGreen = float4(0.2, 0.7, 0.00, 0) * 4.0;

const float4 geometryEdgeColor = float4(0.25, 0.25, 0.25, 0);
const float4 geometryDarkEdgeColor = float4(0.67,0.92,0.77,0);
const float4 geometryDarkSurfaceColor = float4(0.25, 0.5, 0.35,0) ;

float invlerp(float _a, float _b, float _value){
    return (_value - _a) * rcp(_b - _a);
}

float4 SFXDarkVisionPS(PS_INPUT input) : COLOR0
{
    float2 texCoord = input.texCoord;
    float4 inputPixel = tex2D(baseTexture, texCoord);
    
    if (amount == 0) 
    {
        return inputPixel;
    }
    
    float2 depth1 = tex2D(depthTexture, input.texCoord).rg;
    
    // Flashlight on
    float offset = 0.0005;
    float depth2 = clamp_tex2D(depthTexture, texCoord + float2(-offset, -offset)).r;
    float depth3 = clamp_tex2D(depthTexture, texCoord + float2(-offset,  offset)).r;
    float depth4 = clamp_tex2D(depthTexture, texCoord + float2( offset, -offset)).r;
    float depth5 = clamp_tex2D(depthTexture, texCoord + float2( offset,  offset)).r;
    
    float fadeout = pow(2.0,-depth1.r*.5);
    float4 baseColor=float4(.9,.9,.9,0);

    float edge = 
            abs(depth2 - depth1.r) +
            abs(depth3 - depth1.r) +
            abs(depth4 - depth1.r) +
            abs(depth5 - depth1.r);
    
    if (depth1.g > 0.5) // entities
    {
    
        if (depth1.r < 0.4) // view model
        {
            return inputPixel;
        }

        float4 edgeColor;
        
            if ( depth1.g > 0.99 ) // marines 1
            {
               return saturate(lerp(inputPixel, edgeColorOrange * edge, (0.45 + edge) * amount));
            }
            else if ( depth1.g > 0.97 ) // marine structures 0.98
            {
                return saturate( inputPixel + edgeColorDarkBlue * 0.075 * amount * edge );
            }
            else if ( depth1.g > 0.95 ) // alien players 0.96
            {
                float4 edgeColor=edgeColorGreen*clamp((fadeout*5),0.05, 0.02);
                return saturate(lerp(inputPixel, max(inputPixel*baseColor,edge*edgeColor), 0.4));
            } 
            else if ( depth1.g > 0.93 ) // gorges 0.94
            {
                return saturate( inputPixel + edgeColorGreen * 0.035 * amount * edge );
            } 
            else { // targets and world ents 0.9
                return saturate( inputPixel + edgeColorGreen * 0.1 * amount * edge );
            }

    } else // world geometry
    {
        float geometryStrength = edge * step(1.0,edge) * step( depth1.r , 100.0);

        //Let there be light
        float luminance = inputPixel.r * 0.2126729 + inputPixel.g * 0.7151522 + inputPixel.b * 0.0721750;
        float darkParameter = saturate(smoothstep(0.1,0,luminance));
        darkParameter *= darkParameter;
        
        float3 normal = tex2D(normalTexture, texCoord).xyz;
        float normalIntensity = saturate(pow((abs(normal.z - 0.5) + abs(normal.y - 0.5) + abs(normal.x - 0.5)) * 1.3, 8));
        
        float surfaceIntensity = darkParameter * normalIntensity;
        
        float4 geometryColor = lerp(geometryEdgeColor,geometryDarkEdgeColor ,darkParameter )  * geometryStrength;
        geometryColor += geometryDarkSurfaceColor * surfaceIntensity * saturate(invlerp(15.0,12.0,depth1.r));
        //Lights out
        
        return lerp(inputPixel, geometryColor, ( 0.01 * amount ));  //Animation
    }
}