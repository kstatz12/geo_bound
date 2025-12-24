# GeoBound

GeoBound is an elixir library to support efficient geoqueries. 

## Data Setup
this depends on data from [geonames](https://www.geonames.org/)
### Docker

Build the docker container for processing geonames data

``` sh
docker build -t geonames-process scripts/.
```

you will need do mount a directory. 

``` sh
mkdir data \\
docker run --rm -v "$PWD/data:/data:Z" geonames-process
```

This will
- download the geonames data for the US and Canada
- unzip the archives
- run the `process.py` script over the data to transform it into the right shape

## Configuration
to use GeoBound you need to configure the data location

``` elixir
Application.put_env(:geo, :data_file_path, "data/geonames.json")
```

you cna optionally also set a name for the `:ets` table in case you are running multiple copies


``` elixir
Application.put_env(:geo, :geo_table_name, :some_atom)
```




