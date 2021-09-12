defmodule EnochEx.Calendar.Debug do
  @moduledoc """
  Debugging / Printing / Speedup functions for calendars
  """
  alias EnochEx.Calendar.Model.Day
  alias EnochEx.Calendar.Model.Month
  alias EnochEx.Enoch.Date

  def print_calendar(%{year: year}) do
    print_year(year)
  end

  def print_year(%{months: months}) do
    Enum.each(months, fn {_, %Month{days: days} = month} ->
      print_month(month, Map.get(days, 1))
    end)
  end

  def print_month(_m, %Day{day_of_month: 31} = d), do: print_day(d)
  def print_month(%Month{solstice_equinox: nil}, %Day{day_of_month: 30} = d), do: print_day(d)
  def print_month(%Month{days: days} = m, d) do
    d = d
    |> print_day()
    |> Date.next_day_of_month(m)

    print_month(m, Map.get(days, d.day_of_month))
  end

  def print_day(day), do: day |> IO.inspect()
end