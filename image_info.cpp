#include <iostream>
#include "gdal_priv.h"
#include "cpl_conv.h" // for CPLMalloc()
#include <boost/array.hpp>
#include <boost/foreach.hpp>
#define MAX_BANDS (30)
#include <limits.h>
#include <float.h>



//Open
GDALDataset  *gdal_open( char *filename) {
 	GDALDataset  *poDataset;

    	poDataset = (GDALDataset *) GDALOpen( filename, GA_ReadOnly );
    	if( poDataset == NULL )
    	{
		std::cerr << "Could not open \'" << filename << "\'\n";
		exit(-1);
	}

 	return poDataset;
}

int ussage(char *name) {
	 std::cerr << "Ussage. TBD.\n";
         exit(-1);
}


//Get bands, put in vector, return. Dupilcates vector, but not the end of the world..
std::vector<GDALRasterBand  *> get_bands( GDALDataset  *poDataset)
  {
	std::vector<GDALRasterBand  *> bands;
	for (int i=0; i< poDataset->GetRasterCount(); i++) {
		 bands.push_back( poDataset->GetRasterBand(i+1));
	}

	return bands;
  }


void gdal_init() {
	 GDALAllRegister();
}

#define YAML_INDENT ("  ")
void examine_data ( std::vector<GDALRasterBand  *> bands, double nodatad, double *valid_start=NULL, double *valid_stop=NULL ) {
	float 		*pafScanline;
	int 		*paiScanline;
	int		nodata;
	float		nodataf;
	bool		floating_point=false;
	int		nXSize;
	int		nYSize;

	//less typing..
	nXSize=bands[0]->GetXSize();
	nYSize=bands[0]->GetYSize();
	//nYSize=2;


	//floating point flag..
	if (bands[0]->GetRasterDataType()==GDT_Float32) floating_point = true;

	if (floating_point) {
		nodataf = (float)nodatad;		
        	pafScanline = (float *) CPLMalloc(sizeof(float)*nXSize);
		}
	else {
		nodata = (int)nodatad;
		paiScanline = (int *) CPLMalloc(sizeof(float)*nXSize);
	}


	//start of yml output..
	std::cout << "bands:" << "\n";
	
        BOOST_FOREACH( GDALRasterBand  *band, bands )
        {
		//stats..
        	unsigned long   valid_data=0;
        	float           fmax=FLT_MIN,fmin=FLT_MAX;
        	int             max=INT_MIN,min=INT_MAX;

		for(int y=0; y <  nYSize; y++) { 
			if (floating_point) {
				band->RasterIO( GF_Read, 0, y, nXSize, 1, pafScanline, nXSize, 1, GDT_Float32, 0, 0 );	
				for(int x=0; x < nXSize;x++) {
					if (pafScanline[x] == nodataf) continue;
					if ( fmin > pafScanline[x] ) fmin =  pafScanline[x];
					else if ( fmax < pafScanline[x] ) fmax =  pafScanline[x];
					valid_data++;
                                }
			} else {
				band->RasterIO( GF_Read, 0, y, nXSize, 1, paiScanline, nXSize, 1, GDT_Int32, 0, 0 );
				for(int x=0; x < nXSize;x++) {
					if (paiScanline[x] == nodata) continue;
                                        if ( min > paiScanline[x] ) min =  paiScanline[x];
                                        else if ( max < paiScanline[x] ) max =  paiScanline[x];
					valid_data ++;
				}
			}

		}

		//print YAML stats..
		std::cout << "- " << "band_no: " << band->GetBand() << "\n";
		std::cout << YAML_INDENT << "overviews: " << band->GetOverviewCount() << "\n";
		std::cout << YAML_INDENT << "valid_pixels: " << valid_data << "\n";
		std::cout << YAML_INDENT << "nodata_pixels: " << nYSize*nXSize-valid_data << "\n";
		if ( floating_point ) {
			std::cout << YAML_INDENT << "min: " << fmin << "\n";
			std::cout << YAML_INDENT << "max: " << fmax << "\n";
		} else {
			std::cout << YAML_INDENT << "min: " << min << "\n";
                       	std::cout << YAML_INDENT << "max: " << max << "\n";
		}
        }
	
	
}


void get_basic_stats( GDALDataset  *poDataset) {
	double padfTransform[6];

	//get sizes
	std::cout << "width: " << poDataset->GetRasterXSize() << "\n";
	std::cout << "height: " << poDataset->GetRasterYSize() << "\n";
	//get projection
	std::cout << "projection: " << "'" << poDataset->GetProjectionRef() << "' \n";
	std::cout << "geo_transform: " << "\n";
	poDataset->GetGeoTransform(padfTransform);
	BOOST_FOREACH (double v,padfTransform ) 
		std::cout << "- " << v << "\n";
}



int main (int argc, char **argv) {
	GDALDataset  *poDataset;
	GDALRasterBand  *poBand;
	std::vector<GDALRasterBand  *> bands;

	gdal_init();

	poDataset = gdal_open(argv[1]);

	get_basic_stats(poDataset);	
	get_basic_stats(poDataset);
	bands = get_bands(poDataset);
	
	examine_data(bands, 0.0);
}
