defmodule Geo.Fence do
  @moduledoc """
  Point-in-convex-polygon test for a convex hull (CW or CCW).

  Hull vertices must be ordered around the perimeter.
  Vertex format: {lat, lng}
  Point format:  {lat, lng}

  Uses planar approximation: x=lng, y=lat (good for local/regional hulls).
  """

  @type point :: {number(), number()}

  @spec contains_point?(hull :: [point()], p :: point(), keyword()) :: boolean()
  def contains_point?(hull, p, opts \\ []) do
    eps = Keyword.get(opts, :eps, 0.0)
    include_boundary? = Keyword.get(opts, :include_boundary?, true)

    hull = normalize_hull(hull)

    cond do
      not valid_point?(p) ->
        false

      length(hull) < 3 ->
        false

      # quick reject: bounding box
      not in_bbox?(hull, p, eps) ->
        false

      true ->
        convex_contains?(hull, p, eps, include_boundary?)
    end
  end

  # --- Core test (O(n)) ---
  defp convex_contains?(hull, p, eps, include_boundary?) do
    # Determine expected orientation sign from first non-zero cross
    expected =
      hull
      |> edges()
      |> Enum.reduce_while(nil, fn {a, b}, acc ->
        c = cross(a, b, p)

        cond do
          near_zero?(c, eps) -> {:cont, acc}
          true -> {:halt, sign(c)}
        end
      end)

    # If all crosses are ~0, polygon is degenerate or point lies on same line;
    # treat as "inside" only if boundary counts.
    if expected == nil do
      include_boundary?
    else
      Enum.all?(edges(hull), fn {a, b} ->
        c = cross(a, b, p)

        cond do
          near_zero?(c, eps) ->
            include_boundary? and on_segment?(a, b, p, eps)

          true ->
            sign(c) == expected
        end
      end)
    end
  end

  # --- Geometry helpers ---
  # cross( (b-a), (p-a) ) using x=lng, y=lat
  defp cross({alat, alng}, {blat, blng}, {plat, plng}) do
    ax = alng
    ay = alat
    bx = blng
    by = blat
    px = plng
    py = plat

    (bx - ax) * (py - ay) - (by - ay) * (px - ax)
  end

  defp sign(x) when x > 0, do: 1
  defp sign(x) when x < 0, do: -1

  defp near_zero?(x, eps), do: abs(x) <= eps

  # Point on segment AB (with eps)
  defp on_segment?(a, b, p, eps) do
    # collinear already assumed (cross ~ 0), so just check bounding box of segment
    {min_lat, max_lat, min_lng, max_lng} = seg_bbox(a, b)
    {plat, plng} = p

    plat >= min_lat - eps and plat <= max_lat + eps and
      plng >= min_lng - eps and plng <= max_lng + eps
  end

  defp seg_bbox({alat, alng}, {blat, blng}) do
    {min(alat, blat), max(alat, blat), min(alng, blng), max(alng, blng)}
  end

  defp edges([_a, _b] = hull), do: [{Enum.at(hull, 0), Enum.at(hull, 1)}]
  defp edges(hull) do
    hull
    |> Enum.with_index()
    |> Enum.map(fn {a, i} -> {a, Enum.at(hull, rem(i + 1, length(hull)))} end)
  end

  # --- Input hygiene / quick reject ---
  defp normalize_hull(hull) when is_list(hull) do
    hull
    |> Enum.filter(&valid_point?/1)
    |> drop_repeated_last()
  end

  # If last vertex equals first, drop last
  defp drop_repeated_last([first | _] = hull) do
    case List.last(hull) do
      ^first -> Enum.drop(hull, -1)
      _ -> hull
    end
  end

  defp drop_repeated_last([]), do: []

  defp valid_point?({lat, lng})
       when is_number(lat) and is_number(lng) and
              lat >= -90 and lat <= 90 and lng >= -180 and lng <= 180,
       do: true

  defp valid_point?(_), do: false

  defp in_bbox?(hull, {plat, plng}, eps) do
    {min_lat, max_lat, min_lng, max_lng} =
      Enum.reduce(hull, {1.0e99, -1.0e99, 1.0e99, -1.0e99}, fn {lat, lng},
                                                                  {min_lat, max_lat, min_lng, max_lng} ->
        {min(min_lat, lat), max(max_lat, lat), min(min_lng, lng), max(max_lng, lng)}
      end)

    plat >= min_lat - eps and plat <= max_lat + eps and
      plng >= min_lng - eps and plng <= max_lng + eps
  end
end
