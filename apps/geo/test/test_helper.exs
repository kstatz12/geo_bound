ExUnit.start()
Application.put_env(:geo, :data_file_path, "data/test_data.json")
Application.put_env(:geo, :geo_table_name, :test_data_table)
Geo.Servers.GeoSupervisor.start_link(%{})
