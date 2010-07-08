all: masker

masker: masker.c
	gcc $(gdal-config --cflags) -o masker masker.c $(gdal-config --libs)
