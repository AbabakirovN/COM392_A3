/*******************************************************************************
*
*   COMMENTS GO HERE
*
*   TODO LIST GOES HERE
*
*******************************************************************************/
#include <cuda.h>
#include <stdio.h>
#include "gpuCode.h"
#include "params.h"

/******************************************************************************/
// return information about CUDA GPU devices on this machine
int probeGPU(){

  cudaError_t err;
  err = cudaDeviceReset();

  cudaDeviceProp prop;
  int count;
  err = cudaGetDeviceCount(&count);
  if(err != cudaSuccess){
    printf("problem getting device count = %s\n", cudaGetErrorString(err));
    return 1;
    }
  printf("number of GPU devices: %d\n\n", count);

  for (int i = 0; i< count; i++){
    printf("************ GPU Device: %d ************\n\n", i);
    err = cudaGetDeviceProperties(&prop, i);
    if(err != cudaSuccess){
      printf("problem getting device properties = %s\n", cudaGetErrorString(err));
      return 1;
      }

    printf("\tName: %s\n", prop.name);
    printf( "\tCompute capability: %d.%d\n", prop.major, prop.minor);
    printf( "\tClock rate: %d\n", prop.clockRate );
    printf( "\tDevice copy overlap: " );
      if (prop.deviceOverlap)
        printf( "Enabled\n" );
      else
        printf( "Disabled\n" );
    printf( "\tKernel execition timeout: " );
      if (prop.kernelExecTimeoutEnabled)
        printf( "Enabled\n" );
      else
        printf( "Disabled\n" );
    printf( "--- Memory Information for device %d ---\n", i );
    printf("\tTotal global mem: %ld\n", prop.totalGlobalMem );
    printf("\tTotal constant Mem: %ld\n", prop.totalConstMem );
    printf("\tMax mem pitch: %ld\n", prop.memPitch );
    printf( "\tTexture Alignment: %ld\n", prop.textureAlignment );
    printf("\n");
    printf( "\tMultiprocessor count: %d\n", prop.multiProcessorCount );
    printf( "\tShared mem per processor: %ld\n", prop.sharedMemPerBlock );
    printf( "\tRegisters per processor: %d\n", prop.regsPerBlock );
    printf( "\tThreads in warp: %d\n", prop.warpSize );
    printf( "\tMax threads per block: %d\n", prop.maxThreadsPerBlock );
    printf( "\tMax block dimensions: (%d, %d, %d)\n",
                  prop.maxThreadsDim[0],
                  prop.maxThreadsDim[1],
                  prop.maxThreadsDim[2]);
    printf( "\tMax grid dimensions: (%d, %d, %d)\n",
                  prop.maxGridSize[0],
                  prop.maxGridSize[1],
                  prop.maxGridSize[2]);
    printf("\n");
  }

return 0;
}

/******************************************************************************/
int updatePalette(GPU_Palette* P){

  updateReds <<< P->gBlocks, P->gThreads >>> (P->red);
  //updateGreens <<< P->gBlocks, P->gThreads >>> (P->green);
	updateBlues <<< P->gBlocks, P->gThreads >>> (P->blue);

  runRotation <<< P->gBlocks, P->gThreads >>> (P->green, P->red, P->blue, P->num_pixels);

  return 0;
}

/******************************************************************************/
__global__ void updateReds(float* red){

  int x = threadIdx.x + (blockIdx.x * blockDim.x);
  int y = threadIdx.y + (blockIdx.y * blockDim.y);
  int vecIdx = x + (y * blockDim.x * gridDim.x);

  red[vecIdx] = 0;

}

/******************************************************************************/
__global__ void runRotation(float* green, float* red, float* blue, long strandLength){

  int x = threadIdx.x + (blockIdx.x * blockDim.x);
  int y = threadIdx.y + (blockIdx.y * blockDim.y);
  int tid = x + (y * blockDim.x * gridDim.x);

  //blue[tid] = green[strandLength - 1 - tid];
  // for(long i = startIdx; i < endIdx; i++){  // i = start index of strand2
  float acc = 0.0;
  long the_index;
  for(long j = 0; j < strandLength; j++){
    the_index = j+tid;
    if (the_index >= strandLength) the_index = the_index - strandLength;
    acc += abs((green[j] - green[strandLength - 1 - the_index]));
  }

  float avg = (float) (acc * 1.0 )/strandLength; // score for the rotation


  red[tid] = avg;
}

/******************************************************************************/
__global__ void updateGreens(float* green){

  int x = threadIdx.x + (blockIdx.x * blockDim.x);
  int y = threadIdx.y + (blockIdx.y * blockDim.y);
  int vecIdx = x + (y * blockDim.x * gridDim.x);

  green[vecIdx] = 0;
}

/******************************************************************************/
__global__ void updateBlues(float* blue){

  int x = threadIdx.x + (blockIdx.x * blockDim.x);
  int y = threadIdx.y + (blockIdx.y * blockDim.y);
  int vecIdx = x + (y * blockDim.x * gridDim.x);

  blue[vecIdx] = 0;
}


/******************************************************************************/
GPU_Palette initGPUPalette(unsigned int imageWidth, unsigned int imageHeight)
{
  GPU_Palette X;

  X.gThreads.x = 32;  // 32 x 32 = 1024 threads per block
  X.gThreads.y = 32;
  X.gThreads.z = 1;
  X.gBlocks.x = ceil(imageWidth/32);  // however many blocks needed for image
  X.gBlocks.y = ceil(imageHeight/32);
  X.gBlocks.z = 1;

  X.palette_width = imageWidth;       // save this info
  X.palette_height = imageHeight;
  X.num_pixels = imageWidth * imageHeight;
  X.memSize =  imageWidth * imageHeight * sizeof(float);

  // allocate memory on GPU
  cudaError_t err;
  err = cudaMalloc((void**) &X.red, X.memSize);
  if(err != cudaSuccess){
    printf("cuda error allocating red = %s\n", cudaGetErrorString(err));
    exit(EXIT_FAILURE);
    }
  err = cudaMalloc((void**) &X.green, X.memSize); // g
  if(err != cudaSuccess){
    printf("cuda error allocating green = %s\n", cudaGetErrorString(err));
    exit(EXIT_FAILURE);
    }
  err = cudaMalloc((void**) &X.blue, X.memSize);  // b
  if(err != cudaSuccess){
    printf("cuda error allocating blue = %s\n", cudaGetErrorString(err));
    exit(EXIT_FAILURE);
    }

  return X;
}

/******************************************************************************/
int freeGPUPalette(GPU_Palette* P) {

  // free gpu memory
  cudaFree(P->gray);
  cudaFree(P->red);
  cudaFree(P->green);
  cudaFree(P->blue);

  return 0;
}

/*************************************************************************/
