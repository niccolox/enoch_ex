defmodule EnochEx.Calendar.CurrentDatetime do
  @moduledoc """
  The date and clock, ticking minute by minute, returning the advanced current datetime. Note that this module
  knows only to move time forward, minute by minute, it has no awareness of the equinox (handled upstream of this).

  day: 1,
  week_day: 4,
  hour: 0,
  minute: 0,
  year_day: 1,
  parts_day: 10,
  parts_night: 8,
  season: "spring",
  sign: "aries",
  year: 2021,
  month: 1,
  gate: 4
  """
  import EnochEx.Calendar.Guards, only: [not_equinox_month?: 1, descrease_sunrise_minute?: 1]
  alias EnochEx.Calendar.Model.CurrentDatetime, as: CDT
  alias EnochEx.Enoch.Date

  @doc """
  Tick a minute! Increment hour if it is time, and increment day.. if it is time.
  """
  # During the great sign spring equinox hours will tick until upstream notes that sunrise past the equinox has passed
  def tick(%CDT{year_day: 364, minute: m, hour: 17, sunrise_minute: sm} = cdt) when m == (80 - sm), do: cdt |> Map.put(:minute, 0) |> Map.put(:hour, 18) |> inc_day()
  def tick(%CDT{year_day: 364, minute: 79, hour: 17} = cdt), do: cdt |> Map.put(:minute, 0) |> Map.put(:hour, 18) |> inc_day()

  def tick(%CDT{minute: m, hour: 17, sunrise_minute: sm} = cdt) when m == (80 - sm), do: inc_day(cdt) |> Map.put(:minute, 0) |> Map.put(:hour, 0)
  def tick(%CDT{minute: 79, hour: 17} = cdt), do: inc_day(cdt) |> Map.put(:minute, 0) |> Map.put(:hour, 0)
  def tick(%CDT{minute: 79, hour: hour} = cdt), do: %{cdt | minute: 0, hour: hour + 1}
  def tick(%CDT{minute: min} = cdt), do: %{cdt | minute: min + 1}

  @doc """
  Tick during the great spring equinox! Do not advance the day because until the following sunrise
  of the equinox event, we are in the same year.
  """
  def tick_spring_equinox(%CDT{minute: 79, hour: h} = cdt), do: %{cdt | minute: 0, hour: h + 1}
  def tick_spring_equinox(%CDT{minute: min} = cdt), do: %{cdt | minute: min + 1}

  def inc_day(%CDT{day: d, month_day: md} = cdt) when descrease_sunrise_minute?(md) do
    cdt
    |> inc_week()
    |> inc_month()
    |> inc_year()
    |> Map.put(:day, d + 1)
    |> Map.put(:sunrise_minute, trunc(md / 7 * 20))
  end
  def inc_day(%CDT{year_day: 364, event_day: events} = cdt) do
    case events do
      [] -> 
        cdt
      ["New Years Day"|_] ->
        # Note on equinox the hours tick continuously
        cdt
        |> inc_week()
        |> inc_month()
        |> inc_year()
        |> Map.put(:day, 1)
        |> Map.put(:week_day, 4)
        |> Map.put(:minute, 0)
        |> Map.put(:hour, 0)
    end
  end
  def inc_day(%CDT{day: d} = cdt) do
    cdt
    |> inc_week()
    |> inc_month()
    |> inc_year()
    |> Map.put(:day, d + 1)
  end

  def inc_week(%CDT{year_day: 364} = cdt), do: %{cdt | week_day: 4, week: 1}
  def inc_week(%CDT{week_day: 7, week: w} = cdt), do: %{cdt | week_day: 1, week: w + 1}
  def inc_week(%CDT{week_day: wd} = cdt), do: %{cdt | week_day: wd + 1}

  def inc_month(%CDT{month_day: 31, month: 12} = cdt) do
    %{cdt | month_day: 1, month: 1}
    |> update_day_parts()
  end
  def inc_month(%CDT{month_day: 31, month: m} = cdt) do
    %{cdt | month_day: 1, month: m + 1}
    |> update_day_parts()
  end
  def inc_month(%CDT{month_day: 30, month: m} = cdt) when not_equinox_month?(m) do
    %{cdt | month_day: 1, month: m + 1}
    |> update_day_parts()
  end
  def inc_month(%CDT{month_day: md} = cdt), do: %{cdt | month_day: md + 1}
  
  def inc_year(%CDT{year_day: 364, year: y} = cdt), do: %{cdt | year: y + 1, year_day: 1}
  def inc_year(%CDT{year_day: yd} = cdt), do: %{cdt | year_day: yd + 1}

  def pretty(%CDT{} = cdt) do
    %{
      "season" => Date.get_month_info_by_number(cdt.month) |> Tuple.to_list(),
      "hour" => cdt.hour,
      "minute" => cdt.minute,
      "month" => cdt.month,
      "year" => cdt.year,
      "week_day" => cdt.week_day,
      "week_day_postfix" => week_postfix(cdt),
      "month_day" => cdt.month_day,
      "month_day_postfix" => month_postfix(cdt),
      "clock" => clock(cdt),
      "year_day" => cdt.year_day
      "holidays" => Date.special_days(cdt),
      "parts_day" => cdt.parts_day,
      "parts_night" => cdt.parts_night,
      "sunrise_hour" => cdt.sunrise_hour
    }
  end

  # PRIVATE FUNCTIONS
  ###################
  defp update_day_parts(%CDT{sunrise_hour: curr_sh, parts_day: curr_parts_day, month: month_num} = cdt) do
    parts = Date.get_month_info_by_number(month_num) |> elem(3)
    parts_day = parts |> elem(0)
    parts_night = parts |> elem(1)
    sunrise_hour = cond do
      curr_parts_day > parts_day -> curr_sh + 1
      true -> curr_sh - 1
    end
    %{cdt | parts_day: parts_day, parts_night: parts_night, sunrise_hour: sunrise_hour, sunrise_minute: 0}
  end

  defp month_postfix(%CDT{month_day: md}) when md < 21 and md > 3, do: "th"
  defp month_postfix(%CDT{month_day: md}) when md in [1, 21, 31], do: "st"
  defp month_postfix(%CDT{month_day: md}) when md in [2, 22], do: "nd"
  defp month_postfix(%CDT{month_day: md}) when md in [3, 23], do: "rd"
  defp month_postfix(_), do: "th"

  defp week_postfix(%CDT{week_day: md}) when md == 1, do: "st"
  defp week_postfix(%CDT{week_day: md}) when md == 2, do: "nd"
  defp week_postfix(%CDT{week_day: md}) when md == 3, do: "rd"
  defp week_postfix(_), do: "th"

  defp clock(%CDT{hour: hour, minute: minute}), do: clock(hour, minute, "")

  defp clock(hour, minute, "") when hour < 10, do: clock(hour, minute, "0#{hour}")
  defp clock(hour, minute, ""), do: clock(hour, minute, "#{hour}")
  defp clock(_, minute, clock) when minute < 10, do: "#{clock}:0#{minute}"
  defp clock(_, minute, clock), do: "#{clock}:#{minute}"
end