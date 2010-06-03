#include "gdal.h"
#include "cpl_string.h"

GDALDatasetH make_me_a_sandwitch(GDALDatasetH *in_dataset, char *copy_file_name)
{
    char **papszOptions = NULL;
    const char *pszFormat = "GTiff";
    GDALDriverH hDriver;
    
    hDriver = GDALGetDriverByName( pszFormat );
    papszOptions = CSLSetNameValue( papszOptions, "TILED", "YES" );
    papszOptions = CSLSetNameValue( papszOptions, "COMPRESS", "DEFLATE" );
    /*papszOptions = CSLSetNameValue( papszOptions, "BIGTIFF", "YES" );*/
    
    return ( GDALCreateCopy( hDriver, copy_file_name, in_dataset, FALSE, 
                             papszOptions, NULL, NULL ));
}


int main( int argc, const char* argv[] )
{
    GDALDriverH   hDriver;
    double        adfGeoTransform[6];
    GDALDatasetH  hDataset;

    GDALAllRegister();

    hDataset = GDALOpen( argv[1], GA_ReadOnly );
    if( hDataset == NULL )
    {
        printf("Hmm, could not open '%s' for reading.. this be an error, exiting..\n", argv[1]);
        return -1;
    }
    
    hDriver = GDALGetDatasetDriver( hDataset );
    printf( "Driver: %s/%s\n",
            GDALGetDriverShortName( hDriver ),
            GDALGetDriverLongName( hDriver ) );

    printf( "Size is %dx%dx%d\n",
            GDALGetRasterXSize( hDataset ), 
            GDALGetRasterYSize( hDataset ),
            GDALGetRasterCount( hDataset ) );

    if( GDALGetProjectionRef( hDataset ) != NULL )
        printf( "Projection is `%s'\n", GDALGetProjectionRef( hDataset ) );

    if( GDALGetGeoTransform( hDataset, adfGeoTransform ) == CE_None )
    {
        printf( "Origin = (%.6f,%.6f)\n",
                adfGeoTransform[0], adfGeoTransform[3] );

        printf( "Pixel Size = (%.6f,%.6f)\n",
                adfGeoTransform[1], adfGeoTransform[5] );
    }


}