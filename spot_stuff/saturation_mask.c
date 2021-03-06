#include "gdal.h"
#include "cpl_string.h"
#include "cpl_conv.h"

/************************************************************/
/* Simple test for saturated pixels.. */
/* Use like:            */
/* ./saturate <infile> <outfile> */
/* <infile> .*/
/* questions or comments? jc@alaska.edu     */
/* complile like:  gcc $(gdal-config --cflags) -o saturation_mask saturation_mask.c $(gdal-config --libs) */
/* Warning - this c code should be enough to frighten small childen - don't read/look without protection. */
/************************************************************/


/* parse options.. */
int parse ( int argc, char ** argv,char * infile, char * outfile, char * driver)
{
    int aflag = 0;
    int bflag = 0;
    char *cvalue = NULL;
    int index;
    int c;
    /* Default to PNG..*/
    strcpy(driver, "PNM");
    opterr = 0;
    
    while ((c = getopt (argc, argv, "hf:")) != -1)
       switch (c)
         {
         case 'h':
            useage(argv[0]);
         case 'f':
           /* NULL is bad -> requires a valid driver..*/
           if ( optarg == NULL) useage (argv[0]);
           /* save driver */
           strcpy(driver, optarg);
           break;
         default:
           useage(argv[0]);
         }
    
    /* requires infile and outfile..*/
    if ( optind +2 != argc) useage(argv[0]);
    strcpy(infile, argv[optind]);
    strcpy(outfile, argv[optind+1]);
}



/* Makes a copy of a dataset, and opens it for writing.. */
GDALDatasetH make_me_a_sandwitch(GDALDatasetH *in_dataset, char *filename, char *driver)
{
    char **papszOptions = NULL;
    const char *pszFormat = "GTiff";
    GDALDriverH hDriver;
    GDALDatasetH out_gdalfile;
    char **papszMetadata;
    hDriver = GDALGetDriverByName(driver);
    
    
    /* check that you can use the "create" method..*/
    papszMetadata = GDALGetMetadata( hDriver, NULL );
    if( !CSLFetchBoolean( papszMetadata, GDAL_DCAP_CREATE, FALSE ) )
    {
        fprintf(stderr,"Driver %s does not support Create() method - can't use it.\n", pszFormat );
        exit(-1);
    }
    /*papszOptions = CSLSetNameValue( papszOptions, "TILED", "YES" );
    papszOptions = CSLSetNameValue( papszOptions, "COMPRESS", "DEFLATE" );*/
    
    /*Create copy..*/
    /*return GDALCreateCopy( hDriver, filename, *in_dataset, FALSE, papszOptions, NULL, NULL );*/
    return GDALCreate(hDriver, filename,
        GDALGetRasterXSize( *in_dataset ),
        GDALGetRasterYSize( *in_dataset ),
        1,
        GDT_Byte, papszOptions );
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

void useage(char *progname)
{
    fprintf(stderr, "Use me like:\n");
    fprintf(stderr, "%s [-h] [-f PNM] <infile> <outfile>\n", progname);
    fprintf(stderr, "\t-f PNM|GTiff -> make a mask in that particular format - defaults to PNM,\n\t should except any format gdal writes\n\tsee http://www.gdal.org/formats_list.html for a list\n");
    fprintf(stderr, "\t<infile> can be any image that gdal reads\n");
    fprintf(stderr, "\t<outfile> will be the output saturation mask)\n");
    fprintf(stderr, "Problems? Questions? Complain to jay@alaska.edu so he can ignore them..\n\nBy now.\n\n");
    exit(-1);
}

int main( int argc, const char* argv[] )
{
    GDALDriverH   hDriver;
    double        adfGeoTransform[6];
    GDALDatasetH  in_Dataset;
    GDALDatasetH  mask_Dataset;
    GDALDatasetH  out_Dataset;
    GDALRasterBandH mask_band;
    unsigned char   *out_scan_line, *data_scan_line;
    int             nBlockXSize, nBlockYSize;
    int             bGotMin, bGotMax;
    int             bands;
    int             xsize;
    double          adfMinMax[2];
    int             valid_data_pixels[10];
    int             saturated_data_pixels[10];
    int             y_index, x;
    char            infile[512], outfile[512], driver[32];   /*more elite action require..*/
    GDALRasterBandH  out_band;
    
    /* read command line..*/
    parse(argc, argv, infile, outfile, driver);
    
    GDALAllRegister();
    
    /* Set cache to something reasonable.. - 1/2 gig*/
    CPLSetConfigOption( "GDAL_CACHEMAX", "512" );

    /* open datasets..*/
    in_Dataset = GDAL_open_read( infile);
    out_Dataset = make_me_a_sandwitch(&in_Dataset, outfile, driver);
    
    /* Basic info on source dataset..*/
    GDALGetBlockSize(GDALGetRasterBand( in_Dataset, 1 ) , &nBlockXSize, &nBlockYSize );
    
    /* Loop though bands, checking for saturated pixels .... */
    xsize = GDALGetRasterXSize( in_Dataset );
    data_scan_line = (char *) CPLMalloc(sizeof(char)*xsize);
    out_scan_line = (char *) CPLMalloc(sizeof(char)*xsize);
    
    /* The output band... */
    out_band =  GDALGetRasterBand( out_Dataset, 1);

   
    /* wipe counters.. */ 
    for (bands=1; bands <= GDALGetRasterCount( in_Dataset ); bands ++ ) {
        valid_data_pixels[bands] = 0;
        saturated_data_pixels[bands] = 0;
    }
    
    /* loop though the lines of the data, looking for no data and saturated pixels..*/
    for (y_index = 0; y_index <GDALGetRasterYSize( in_Dataset ); y_index ++ ) {
        /* set line to 0..*/
        for(x=0; x < xsize; x++) { out_scan_line[x] = 0; }
        for (bands=1; bands <= GDALGetRasterCount( in_Dataset ); bands ++ ) {
            GDALRasterBandH data_band;
            /* Read data..*/
            data_band =  GDALGetRasterBand( in_Dataset, bands);
            GDALRasterIO( data_band, GF_Read, 0, y_index, xsize , 1, data_scan_line, xsize , 1, GDT_Byte, 0, 0 );
            
            /* Loop though, looking for saturated pixels and no-data values.. */
            
            for(x=0; x < xsize; x++) {
                if (  data_scan_line[x] != 0 )  {
                   valid_data_pixels[bands] += 1;
                   if ( data_scan_line[x] == 255 ) {
                    saturated_data_pixels[bands] += 1;
                    out_scan_line[x] = 255;
                   }
                }
            }
        }
        GDALRasterIO( out_band, GF_Write, 0, y_index, xsize , 1, out_scan_line, xsize , 1, GDT_Byte, 0, 0 );
    }
    
    GDALClose(out_Dataset);
    
    /* Print some output.. */
    printf("---\n");                /*YAML start...*/
    for (bands=1; bands <= GDALGetRasterCount( in_Dataset ); bands ++ ) {
        printf("- band: %d\n", bands);
        printf("  valid_data_pixels: %d\n", valid_data_pixels[bands]);
        printf("  saturated_data_pixels: %d\n", saturated_data_pixels[bands]);
    }

 return 0;
}
