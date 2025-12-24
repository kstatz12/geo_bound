if Code.ensure_loaded?(Explorer) do
  defmodule Mix.Tasks.Geo.Process do
    use Mix.Task
    alias Explorer.DataFrame, as: DF
    require Explorer.DataFrame
    @shortdoc "process data for geonames"
    @aliases [g: :geo, p: :postal, v: :verbose]
    @switches [geo: [:string, :keep], postal: [:string, :keep], verbose: :count]
    @moduledoc """
    Process raw geonames files into the data format used in this library.

    ## Processing Steps

    1. Load geonames feature files (cities, towns, etc.)
    2. Load geonames postal code files
    3. Filter feature files to only include populated places
    4. Transform postal code data to normalize place names and state codes
    5. Transform feature data to normalize place names and state codes
    6. Join postal code and feature data on cleaned names and states
    7. Structure the joined data into the final format
    8. Export as JSON to the specified output file

    ## Usage

    mix geonames.process [options] output_file

    ## Command line options

      * `-g`, `--geo` - a geonames features file (can be specified multiple times)
      * `-p`, `--postal` - a geonames postal code file (can be specified multiple times)
      * `-v`, `--verbose` - prints process steps
    """
    @preferred_cli_env :dev
    @requirements []

    # Map for normalizing admin codes
    @admin_code_map %{
      "01" => "AB",
      "02" => "BC",
      "03" => "MB",
      "04" => "NB",
      "05" => "NL",
      "07" => "NS",
      "08" => "ON",
      "09" => "PE",
      "10" => "QC",
      "11" => "SK",
      "12" => "YT",
      "13" => "NT",
      "14" => "NU"
    }

    @impl true
    def run(args) do
      {parsed, pos, _invalid} = OptionParser.parse(args, aliases: @aliases, strict: @switches)

      geo_paths = List.wrap(parsed[:geo])
      postal_paths = List.wrap(parsed[:postal])

      unless geo_paths != [] && postal_paths != [] && match?([_], pos) do
        [
          :bright,
          "Processing with:",
          :green,
          inspect(args, pretty: true)
        ]
        |> IO.ANSI.format()
        |> IO.puts()

        Mix.raise("""
        must provide at least one geo file, at least one postal file, and exactly one output.

          mix geonames.process --geo ./data/geo/us_geonames.txt \
                               --geo ./data/geo/ca_geonames.txt \
                               --postal ./data/postal/us_postal_codes.txt \
                               --postal ./data/postal/ca_postal_codes.txt \
              ./data/geonames.json
        """)
      end

      [output_path] = pos

      with {:ok, geo_dfs} <- load_geo_dfs(geo_paths, parsed[:verbose]),
           {:ok, postal_dfs} <- load_postal_dfs(postal_paths, parsed[:verbose]),
           geo_df <- DF.concat_rows(geo_dfs),
           postal_df <- DF.concat_rows(postal_dfs),
           joined_df =
             postal_df |> join_from_postal(geo_df, parsed[:verbose]) |> structure_joined_df(),
           {:ok, json_string} <-
             joined_df
             |> DF.to_rows(atom_keys: true)
             |> Poison.encode_to_iodata() do
        if parsed[:verbose] do
          [:bright, "writing to file: ", :green, output_path]
          |> IO.ANSI.format()
          |> IO.puts()
        end

        File.write!(output_path, json_string)
      else
        err ->
          Mix.raise("""
          error while processing:
          #{inspect(err, pretty: true)}
          """)
      end
    end

    defp load_geo_dfs(paths, verbose) do
      if verbose do
        [:bright, "loading geo files: ", :green, inspect(paths)]
        |> IO.ANSI.format()
        |> IO.puts()
      end

      results = Enum.map(paths, &load_geo_df(&1, verbose))
      errors = Enum.filter(results, &(elem(&1, 0) != :ok))

      if length(errors) > 0 do
        {:error, errors}
      else
        {:ok, Enum.map(results, &elem(&1, 1))}
      end
    end

    defp load_postal_dfs(paths, verbose) do
      if verbose do
        [:bright, "loading postal files: ", :green, inspect(paths)]
        |> IO.ANSI.format()
        |> IO.puts()
      end

      results = Enum.map(paths, &load_postal_df(&1, verbose))
      errors = Enum.filter(results, &(elem(&1, 0) != :ok))

      if length(errors) > 0 do
        {:error, errors}
      else
        {:ok, Enum.map(results, &elem(&1, 1))}
      end
    end

    defp load_geo_df(path, verbose) do
      if verbose do
        [:bright, "loading geo file: ", :green, path]
        |> IO.ANSI.format()
        |> IO.puts()
      end

      case load_file_as_df(path, column_11: :string) do
        {:ok, df} -> {:ok, df |> as_geo_df_frame() |> with_only_populated_features()}
        other -> other
      end
    end

    defp load_postal_df(path, verbose) do
      if verbose do
        [:bright, "loading postal file: ", :green, path]
        |> IO.ANSI.format()
        |> IO.puts()
      end

      case load_file_as_df(path, column_2: :string) do
        {:ok, df} -> {:ok, as_postal_df_frame(df)}
        other -> other
      end
    end

    defp load_file_as_df(path, dtypes),
      do: DF.from_csv(path, delimiter: "\t", header: false, dtypes: dtypes)

    defp as_geo_df_frame(df) do
      DF.rename(df, [
        "geonameid",
        "name",
        "asciiname",
        "alternatenames",
        "latitude",
        "longitude",
        "feature_class",
        "feature_code",
        "country_code",
        "cc2",
        "admin1_code",
        "admin2_code",
        "admin3_code",
        "admin4_code",
        "population",
        "elevation",
        "dem",
        "timezone",
        "modification date"
      ])
    end

    defp with_only_populated_features(df) do
      DF.filter(
        df,
        feature_class == "P" and
          feature_code != "PPLQ" and
          feature_code != "PPLX" and
          feature_code != "PPLW"
      )
    end

    defp as_postal_df_frame(df) do
      DF.rename(df, [
        "country_code",
        "postal_code",
        "place_name",
        "admin_name1",
        "admin_code1",
        "admin_name2",
        "admin_code2",
        "admin_name3",
        "admin_code3",
        "latitude",
        "longitude",
        "accuracy"
      ])
    end

    defp join_from_postal(postal_df, geo_df, verbose) do
      if verbose do
        IO.puts("")

        [:yellow, "joining files ", :green, "."]
        |> IO.ANSI.format()
        |> IO.write()
      end

      left = transform_postal_df(postal_df)
      IO.write(IO.ANSI.format([:green, "."]))

      right = transform_geo_df(geo_df)
      IO.write(IO.ANSI.format([:green, "."]))

      df = perform_join(left, right)
      IO.write(IO.ANSI.format([:green, "."]))
      IO.puts("")
      df
    end

    defp transform_postal_df(df) do
      DF.transform(df, [names: ["place_name", "admin_code1"]], &transform_postal_row/1)
    end

    defp transform_postal_row(row) do
      name = clean_postal_name(row["place_name"])
      state = (row["admin_code1"] || "") |> String.upcase()
      %{cleaned_name: name, cleaned_state: state}
    end

    defp clean_postal_name(name) do
      name
      |> String.replace("Saint", "St.")
      |> String.replace(~r/^Mc\s/, "Mc")
      |> String.downcase()
      |> clean_parentheticals()
    end

    defp clean_parentheticals(name) do
      Regex.replace(~r/\s*\(.*\)$/, name, "")
    end

    defp transform_geo_df(df) do
      DF.transform(df, [names: ["asciiname", "admin1_code"]], &transform_geo_row/1)
    end

    defp transform_geo_row(row) do
      name = row["asciiname"] |> String.downcase()
      state = normalize_admin_code(row["admin1_code"] || "") |> String.upcase()
      %{cleaned_name: name, cleaned_state: state}
    end

    defp normalize_admin_code(code) do
      Map.get(@admin_code_map, code, code)
    end

    defp perform_join(left, right) do
      DF.join(left, right,
        how: :outer,
        on: [
          cleaned_state: :cleaned_state,
          cleaned_name: :cleaned_name
        ]
      )
    end

    defp structure_joined_df(df) do
      df
      |> DF.select([
        "cleaned_name_right",
        "alternatenames",
        "latitude_right",
        "longitude_right",
        "cleaned_state_right",
        "postal_code",
        "latitude",
        "longitude"
      ])
      |> DF.rename([
        "city_name",
        "alt_name",
        "city_latitude",
        "city_longitude",
        "state_code",
        "postal_code",
        "latitude",
        "longitude"
      ])
    end
  end
end
