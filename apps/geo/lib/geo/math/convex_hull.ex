# coveralls-ignore-start
defmodule Geo.ConvexHull do
  @moduledoc """
  Compute the convex hull of a set of points using Graham's scan algorithm.
  Returns a list of points representing the hull in counter-clockwise order.
  """

  @doc """
  Compute the convex hull of a set of points.
  Returns the points forming the convex hull in counter-clockwise order.
  """
  def convex_hull(points) when length(points) < 3, do: points

  def convex_hull(points) do
    points
    |> Enum.uniq()
    |> case do
      unique_points when length(unique_points) < 3 -> unique_points
      unique_points -> graham_scan(unique_points)
    end
  end

  @doc """
  Calculate the centroid of a set of points.
  """
  def centroid(points) do
    {sum_lat, sum_lon} =
      Enum.reduce(points, {0.0, 0.0}, fn {lat, lon}, {acc_lat, acc_lon} ->
        {acc_lat + lat, acc_lon + lon}
      end)

    count = length(points)
    {sum_lat / count, sum_lon / count}
  end

  # Graham scan algorithm implementation
  defp graham_scan(points) do
    # Find the bottom-most point (and leftmost in case of tie)
    start_point = find_start_point(points)

    # Sort points by polar angle with respect to start point
    sorted_points =
      points
      |> Enum.reject(&(&1 == start_point))
      |> Enum.sort_by(fn point ->
        {polar_angle(start_point, point), distance(start_point, point)}
      end)

    # Build the hull using a stack
    hull_points = [start_point | sorted_points]
    build_hull_stack(hull_points, [])
  end

  defp find_start_point(points) do
    Enum.min_by(points, fn {lat, lon} -> {lat, lon} end)
  end

  defp polar_angle({x1, y1}, {x2, y2}) do
    :math.atan2(y2 - y1, x2 - x1)
  end

  defp distance({lat1, lon1}, {lat2, lon2}) do
    :math.sqrt(:math.pow(lat1 - lat2, 2) + :math.pow(lon1 - lon2, 2))
  end

  defp build_hull_stack([], stack), do: Enum.reverse(stack)

  defp build_hull_stack([point | rest], stack) do
    new_stack = add_point_to_hull(stack, point)
    build_hull_stack(rest, new_stack)
  end

  defp add_point_to_hull(stack, point) when length(stack) < 2 do
    [point | stack]
  end

  defp add_point_to_hull([second | [first | rest]] = stack, point) do
    case cross_product(first, second, point) do
      cross when cross > 0 ->
        # Left turn - add point to hull
        [point | stack]

      _ ->
        # Right turn or collinear - remove second point and try again
        add_point_to_hull([first | rest], point)
    end
  end

  defp add_point_to_hull(stack, point) do
    [point | stack]
  end

  # Cross product to determine turn direction
  # Positive: counter-clockwise (left turn)
  # Negative: clockwise (right turn)
  # Zero: collinear
  defp cross_product({x1, y1}, {x2, y2}, {x3, y3}) do
    (x2 - x1) * (y3 - y1) - (y2 - y1) * (x3 - x1)
  end

  @doc """
  Check if a point is inside the convex hull.
  Uses the cross product method - point is inside if it's on the same side
  of all edges of the hull.
  """
  def point_inside_hull?(_point, hull) when length(hull) < 3, do: false

  def point_inside_hull?(point, hull) do
    hull_edges = get_hull_edges(hull)

    Enum.all?(hull_edges, fn {p1, p2} ->
      cross_product(p1, p2, point) >= 0
    end)
  end

  defp get_hull_edges(hull) do
    hull
    |> Enum.chunk_every(2, 1, [hd(hull)])
    |> Enum.map(fn [p1, p2] -> {p1, p2} end)
  end

  @doc """
  Calculate the area of the convex hull using the shoelace formula.
  """
  def hull_area(hull) when length(hull) < 3, do: 0.0

  def hull_area(hull) do
    hull
    |> Enum.chunk_every(2, 1, [hd(hull)])
    |> Enum.reduce(0.0, fn [{x1, y1}, {x2, y2}], acc ->
      acc + (x1 * y2 - x2 * y1)
    end)
    |> abs()
    |> Kernel./(2.0)
  end

  @doc """
  Calculate the perimeter of the convex hull.
  """
  def hull_perimeter(hull) when length(hull) < 2, do: 0.0

  def hull_perimeter(hull) do
    hull
    |> Enum.chunk_every(2, 1, [hd(hull)])
    |> Enum.reduce(0.0, fn [p1, p2], acc ->
      acc + distance(p1, p2)
    end)
  end
end

# coveralls-ignore-stop
