/*******************************************************************************
*
*
*
*******************************************************************************/
#include <stdio.h>
#include <cstdlib>
#include <string.h>
#include <time.h>

#include "interface.h"
#include "gpuCode.h"
#include "hostCode.h"
#include "params.h"
#include "animate.h"
#include "crack.h"

/******************************************************************************/
int main(int argc, char *argv[]){

	unsigned char ch;
//  clock_t start, end;	// <---- FIX THIS FOR MULTITHREADING
	AParams PARAMS;

	struct timespec start, finish;
	double elapsed;

  setDefaults(&PARAMS);

  // -- update default parameters entered from command line:
  if(argc<2){usage(); return 1;} // must be at least one arg (fileName)
	while((ch = crack(argc, argv, "r|v|f|", 0)) != NULL) {
	  switch(ch){
    	case 'r' : PARAMS.runMode = atoi(arg_option); break;
      case 'v' : PARAMS.verbosity = atoi(arg_option); break;
			case 'f' : strcpy(PARAMS.fileName, arg_option); break;
      default  : usage(); return(0);
    	}
  	}

  if (PARAMS.verbosity == 2) viewParams(&PARAMS);


  // -- run the system depending on runMode
  switch(PARAMS.runMode){
      case 0: // generate random array of bits of length N
				probeHost();
				probeGPU();
				break;
			case 1: // Exercise 1 - cpu multithreading small search
				break;
			case 2: // Exercise 2 - cpu multithreading search and replace
				if (PARAMS.verbosity == 1) printf("\n -- Exercise 3 -- \n");
				runEx2(&PARAMS);	// defined in hostCode.cpp
				break;
			case 3: // Exercise 3 - gpu search and replace while cpu multithreading
				if (PARAMS.verbosity == 1) printf("\n -- Exercise 4 -- \n");
				break;
			case 4: // Exercise 4 - gpu dynamical system, cpu cloud resources
				break;
			case 5: // Example code to test timing
				if (PARAMS.verbosity) printf("\n -- testing clock -- \n");
					clock_gettime(CLOCK_MONOTONIC, &start);
					for(unsigned long i =0; i < 1000000000; i++){ // burn 1G cycles
						}
					clock_gettime(CLOCK_MONOTONIC, &finish);
					elapsed = (finish.tv_sec - start.tv_sec);	// get the seconds
					elapsed += (finish.tv_nsec - start.tv_nsec) / 1000000000.0; // sec fraction
					printf("time used: %.2f\n", elapsed);
				break;
      case 6:
				break;
      default: printf("no valid run mode selected\n");
				break;
  }

return 0;
}


/******************************************************************************/
int setDefaults(AParams *PARAMS){

    PARAMS->verbosity       = 1;
    PARAMS->runMode         = 0;

    PARAMS->height     = 800;		// this should be loaded from image file
    PARAMS->width      = 800;
    PARAMS->size      = 800*800*3; // 800x800 pixels x 3 colors

    return 0;
}

/******************************************************************************/
int usage()
{
	printf("USAGE:\n");
	printf("-r[val] -v[val] filename\n\n");
  printf("e.g.> ex2 -r1 -v1 imagename.bmp\n");
  printf("v  verbose mode (0:none, 1:normal, 2:params\n");
  printf("r  run mode (1:CPU, 2:GPU)\n");

  return(0);
}

/******************************************************************************/
int viewParams(const AParams *PARAMS){

  printf("--- PARAMETERS: ---\n");
  printf("run mode: %d\n", PARAMS->runMode);
  printf("image height: %d\n", PARAMS->height);
  printf("image width: %d\n", PARAMS->width);
  printf("data size: %d\n", PARAMS->size);

  return 0;
}
/******************************************************************************/
