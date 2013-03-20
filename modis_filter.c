#include "gdal.h"
#include "cpl_string.h"
#include "cpl_conv.h"

/************************************************************/
/* Simple masking util.. */
/* Use like:            */
/* ./masker <infile> <maskfile> <outfile> */
/* <infile> and <maskfile> need to be in the same projection and be the same size for everything to work..*/
/* questions or comments? jc@alaska.edu     */
/* compile like: gcc $(gdal-config --cflags) -o modis_filter modis_filter.c $(gdal-config --libs) */
/************************************************************/



/* Makes a copy of a dataset, and opens it for writing.. */
GDALDatasetH make_me_a_sandwitch(GDALDatasetH *in_dataset, char *copy_file_name)
{
    char **papszOptions = NULL;
    const char *pszFormat = "GTiff";
    GDALDriverH hDriver;
    GDALDatasetH out_gdalfile;
    hDriver = GDALGetDriverByName( pszFormat );
    papszOptions = CSLSetNameValue( papszOptions, "TILED", "YES" );
    papszOptions = CSLSetNameValue( papszOptions, "COMPRESS", "DEFLATE" );
    
        /*Perhaps controversal - default to bigtiff... */
    papszOptions = CSLSetNameValue( papszOptions, "BIGTIFF", "YES" ); 
    
    return GDALCreateCopy( hDriver, copy_file_name, *in_dataset, FALSE, papszOptions, NULL, NULL );
}

GDALDatasetH GDAL_open_read(char *file_name)
{
    GDALDatasetH  gdalDataset;
    gdalDataset = GDALOpen( file_name, GA_ReadOnly );
    if( gdalDataset == NULL )
    {
        printf("Hmm, could not open '%s' for reading.. this be an error, exiting..\n", file_name);
        exit(-1);
    }
}


int main( int argc, const char* argv[] )
{
    GDALDriverH   hDriver;
    double        adfGeoTransform[6];
    GDALDatasetH  in_Dataset;
    GDALDatasetH  out_Dataset;
    unsigned int    *data_scan_line;
    int             nBlockXSize, nBlockYSize;
    int             bGotMin, bGotMax;
    int             bands;
    int             xsize;
    double          adfMinMax[2];
    
    GDALAllRegister();
    
    /* Set cache to something reasonable.. - 1/2 gig*/
    CPLSetConfigOption( "GDAL_CACHEMAX", "512" );

    /* open datasets..*/
    in_Dataset = GDAL_open_read( argv[1]);
    out_Dataset= make_me_a_sandwitch(&in_Dataset,argv[2]);
    
    /* Basic info on source dataset..*/
    GDALGetBlockSize(GDALGetRasterBand( in_Dataset, 1 ) , &nBlockXSize, &nBlockYSize );
    printf( "Block=%dx%d Type=%s, ColorInterp=%s\n",
                nBlockXSize, nBlockYSize,
                GDALGetDataTypeName(GDALGetRasterDataType( GDALGetRasterBand( in_Dataset, 1 ))),
                GDALGetColorInterpretationName(
                    GDALGetRasterColorInterpretation(GDALGetRasterBand( in_Dataset, 1 ))));
    
    /* Loop though bands, wiping values with mask values of 0.. */
    xsize = GDALGetRasterXSize( in_Dataset );
    data_scan_line = (unsigned int *) CPLMalloc(sizeof(unsigned int)*xsize);
    for (bands=1; bands <= GDALGetRasterCount( in_Dataset ); bands ++ ) {
        int x;
        GDALRasterBandH data_band, out_band;
        int y_index = 0;
        data_band =  GDALGetRasterBand( in_Dataset, bands);
        out_band =  GDALGetRasterBand( out_Dataset, bands);
	GDALSetRasterNoDataValue(out_band,0.0);

        for (y_index = 0; y_index <GDALGetRasterYSize( in_Dataset ); y_index ++ ) {
            /* Read data..*/
            GDALRasterIO( data_band, GF_Read, 0, y_index, xsize , 1, data_scan_line, xsize , 1,GDT_UInt32 , 0, 0 );
            
            for(x=0; x < xsize; x++) {
		if ( data_scan_line[x] == 0) data_scan_line[x] = 1;
		else  {
			if ( data_scan_line[x] > 65530 ) data_scan_line[x] = 0;
			else { 
				if ( data_scan_line[x] > 32760 ) data_scan_line[x] = 1;
				}
			}
            }
            
            /* now write out band..*/
            GDALRasterIO( out_band, GF_Write, 0, y_index, xsize , 1, data_scan_line, xsize , 1, GDT_UInt32, 0, 0 );
        }
        
    }
    
    
    GDALClose(out_Dataset);

 }


