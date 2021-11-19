#ifndef GPULib
#define GPULib

#include <cuda.h>
#include <curand.h>
#include <curand_kernel.h>
#include <cuda_texture_types.h>

#define cH2D            cudaMemcpyHostToDevice
#define cD2D            cudaMemcpyDeviceToDevice
#define cD2H            cudaMemcpyDeviceToHost

struct GPU_Palette{

    unsigned int palette_width;
    unsigned int palette_height;
    unsigned long num_pixels;
    unsigned long memSize;

    dim3 gThreads;
    dim3 gBlocks;

    float* gray;
    float* red;
    float* green;
    float* blue;
};

GPU_Palette initGPUPalette(unsigned int, unsigned int);
int probeGPU(void);
int updatePalette(GPU_Palette*);
int freeGPUPalette(GPU_Palette* P1);

// kernel calls:
//__global__ void updateGrays(float* gray);
__global__ void runRotation(float* green, float* red, float* blue, long num_pixels);
__global__ void updateReds(float* red);
__global__ void updateGreens(float* green);
__global__ void updateBlues(float* blue);

#endif
