#include "gdal.h"
#include "cpl_conv.h" /* for CPLMalloc() */
/*Compile like: gcc $(gdal-config --cflags) -o get_gcp get_gcp.c $(gdal-config --libs)*/


int main(int argc, char **argv)
{
    GDALDatasetH  hDataset;

    GDALAllRegister();

    hDataset = GDALOpen( argv[1], GA_ReadOnly );
    if( hDataset != NULL )
    {
	int a;
	GDAL_GCP* gcp_list;
	
	gcp_list = GDALGetGCPs(hDataset);
	/*Something like: "--- \n- a: 2\n  b: 4\n- 2\n- 3\n- 4\n" */
	printf("--- \n");
	for (a=0; a<GDALGetGCPCount(hDataset); a++ ) {
		printf("- x: %g\n", gcp_list[a].dfGCPPixel);
		printf("  y: %g\n", gcp_list[a].dfGCPLine);
                printf("  gx: %15.5f\n", gcp_list[a].dfGCPX);
                printf("  gy: %15.5f\n", gcp_list[a].dfGCPY);
		printf("  name: '%s'\n", gcp_list[a].pszId);
		printf("  info: '%s'\n", gcp_list[a].pszInfo);
		printf("  id: %d\n", a);
	};
    }
    else {

		fprintf(stderr, "ERROR: could not open \"%s\"\n", argv[1]);
 	}

}
