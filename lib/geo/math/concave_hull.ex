# coveralls-ignore-start
defmodule Geo.Math.ConcaveHull do
  @moduledoc """
  Compute the concave hull of a set of points using the k-nearest neighbors algorithm.
  Returns a list of points representing the hull.
  """

  def centroid(points) do
    {sum_lat, sum_lon} =
      Enum.reduce(points, {0.0, 0.0}, fn {lat, lon}, {acc_lat, acc_lon} ->
        {acc_lat + lat, acc_lon + lon}
      end)

    count = length(points)
    {sum_lat / count, sum_lon / count}
  end

  def concave_hull(points, k \\ 3) when length(points) >= 3 and k >= 3 do
    points = Enum.uniq(points)
    start = Enum.min_by(points, fn {lat, _lon} -> lat end)
    remaining = MapSet.new(points) |> MapSet.delete(start)

    hull = build_hull(start, 0.0, remaining, [start])
    hull ++ [start]
  end

  defp build_hull(current, last_angle, remaining, acc) do
    Stream.unfold({current, last_angle, remaining, acc}, &unfold_hull_step/1)
    |> Enum.reduce([hd(acc)], fn seg, acc -> acc ++ seg end)
  end

  defp unfold_hull_step({_curr, _last_angle, remaining, _acc}) when map_size(remaining) == 0 do
    nil
  end

  defp unfold_hull_step({curr, last_angle, remaining, acc}) do
    k_nearest = find_k_nearest_neighbors(curr, remaining, 3)

    case find_next_valid_point(curr, last_angle, k_nearest, acc) do
      nil ->
        nil

      {point, angle} ->
        new_acc = acc ++ [point]
        new_remaining = MapSet.delete(remaining, point)
        {new_acc, {point, angle, new_remaining, new_acc}}
    end
  end

  defp find_k_nearest_neighbors(current_point, remaining_points, k) do
    remaining_points
    |> Enum.map(fn p -> {distance(current_point, p), p} end)
    |> Enum.sort_by(fn {d, _p} -> d end)
    |> Enum.take(k)
    |> Enum.map(fn {_d, p} -> p end)
  end

  defp find_next_valid_point(current, last_angle, k_nearest, acc) do
    k_nearest
    |> Enum.map(fn p ->
      angle = angle_between(current, p)
      delta = angle_delta(last_angle, angle)
      {delta, p, angle}
    end)
    |> Enum.sort_by(fn {delta, _p, _angle} -> delta end)
    |> Enum.find_value(nil, fn {_delta, p, angle} ->
      if line_segments_valid?(acc ++ [p]) do
        {p, angle}
      else
        nil
      end
    end)
  end

  defp distance({lat1, lon1}, {lat2, lon2}) do
    :math.sqrt(:math.pow(lat1 - lat2, 2) + :math.pow(lon1 - lon2, 2))
  end

  defp angle_between({x1, y1}, {x2, y2}) do
    :math.atan2(y2 - y1, x2 - x1)
  end

  defp angle_delta(a1, a2) do
    delta = a2 - a1
    :math.fmod(delta + :math.pi() * 2, :math.pi() * 2)
  end

  defp line_segments_valid?([_]), do: true

  defp line_segments_valid?([a, b | rest]) do
    segments = Enum.chunk_every([a, b | rest], 2, 1, :discard)

    not Enum.any?(segments, fn [p1, p2] ->
      segment_intersect?({a, b}, {p1, p2})
    end)
  end

  defp segment_intersect?({a, b}, {c, d}) do
    ccw = fn {x1, y1}, {x2, y2}, {x3, y3} ->
      (y3 - y1) * (x2 - x1) > (y2 - y1) * (x3 - x1)
    end

    ccw.(a, c, d) != ccw.(b, c, d) and ccw.(a, b, c) != ccw.(a, b, d)
  end
end

# coveralls-ignore-stop
