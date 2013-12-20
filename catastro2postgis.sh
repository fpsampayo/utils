#!/bin/bash

#Personalizacion del proyecto catastro2postgis de Oscar Fonts
#Consiste en la importacion masiva de cartografia descargada de la sede electronica de catastro
#a una base de datos PostGIS existente.

#USO
#configurar los parametros que hay debajo y ejecutar.
#en el datadir deben estar todos los zips descargados de catastro tal cual.
#se reconienda generar el fichero .pgpass en el directorio de usuario para evitar que psql pida el pass por cada conexion a la base de datos

# Params
host=10.0.0.101
dbname=carto
dbuser=postgres
s_srs=25829
datadir=../descargas_catastro/trabajo/

#Esto quedaba muy feo, por lo que mejor usar el fichero .pgpass
#Solicitamos informacion del pass para el dbuser
#echo Introduzca la password para el usuario $dbuser :
#read passwd


# Shapefiles
for zipfile in ${datadir}*.zip
do
    folder=`basename $zipfile .zip`
    echo Descomprimiendo cartografia ${folder}
        
    # Unzip twice to tmp
    mkdir -p ${datadir}tmp/${folder}
    unzip -qo "$zipfile" -d ${datadir}tmp/${folder}
    for layerzip in ${datadir}tmp/${folder}/*.zip
    do
        unzip -qo "$layerzip" -d ${datadir}${folder}
#        rm $layerzip
    done
    
    delegacion=`basename $folder | cut -c 1-2`
    concello=`basename $folder | cut -d "_" -f 2`
    if [[ `echo $concello | wc -m` == 3 ]]
	then	concello=0$concello
    fi
    tipo=`basename $folder | cut -d "_" -f 3 | cut -c 1`
    schema=$delegacion$concello$tipo

    echo Intentando crear el esquema $schema
    sleep 2
    echo  CREATE SCHEMA "$schema"
    psql -h 10.0.0.101 -U postgres -d $dbname -c "CREATE SCHEMA \"$schema\""

    echo Creando/Actualizando la tabla de \'datos_cartografia\'
    psql -h $host -U $dbuser -d $dbname -c "CREATE TABLE \"$schema\".datos_cartografia(id serial, datos varchar(40), fecha_importacion date NOT NULL DEFAULT CURRENT_DATE)"
    psql -h $host -U $dbuser -d $dbname -c "INSERT INTO \"$schema\".datos_cartografia(datos) VALUES ('$folder')"

    for shapefile in ${datadir}${folder}/*.SHP
    do
        table=`basename $shapefile .SHP`
	echo Importando $shapefile a $schema.$table
	ogr2ogr -overwrite -skipfailures -progress -a_srs EPSG:$s_srs -f PostgreSQL PG:"dbname='$dbname' host='$host' port='5432' user='$dbuser' password='$passwd'" -nln $schema.$table $shapefile
#	ogr2ogr -overwrite -skipfailures -progress -f PostgreSQL PG:"dbname='$dbname' host='$host' port='5432' user='$dbuser' password='$passwd'" -nln $schema.$table $shapefile

#        shp2pgsql -p -s $s_srs $shapefile $schema.$table | psql -h $host -d $dbname -U $dbuser #> /dev/null
#        shp2pgsql -W ISO-8859-1 -a -s 4326 $shapefile $table | psql -d $dbname -U $dbuser #> /dev/null
    done
done

# Limpieza
rm -R ${datadir}/tmp

echo Importacion terminada.
echo Disfrute de su cartografia
sleep 1
