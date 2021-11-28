defmodule EnochEx.Calendar.CurrentDatetime do
  @moduledoc """
  The date and clock, ticking minute by minute, returning the advanced current datetime. Note that this module
  knows only to move time forward, minute by minute, it has no awareness of the equinox (handled upstream of this).

  [
    day: 1,
    week: 1,
    week_day: 4,
    month_day: 1,
    year_day: 1,
    event_day: [],
    hour: 0,
    minute: 0,
    year: 2021,
    month: 1,
    parts_day: 10,
    parts_night: 8,
    gregorian_sunrise: nil,
    true_noon: {0, {4, 40}},
    coord: %{"lat" => nil, "long" => nil}
  ]
  """
  import EnochEx.Calendar.Guards, only: [not_equinox_month?: 1]
  alias EnochEx.Calendar.Model.Calendar
  alias EnochEx.Calendar.Model.CurrentDatetime, as: CDT
  alias EnochEx.Enoch.Date
  alias EnochEx.Enoch.Gregorian

  @doc """
  Tick a minute! Increment hour if it is time, and increment day.. if it is time.
  """
  # During the great sign spring equinox mins/hours will tick until the event of the sunrise following the equinox
  # has been placed on the cdt
  def tick(%CDT{year_day: 364} = cdt), do: inc_day(cdt)

  def tick(%CDT{minute: 39, hour: 17, month_day: 30, month: m} = cdt) when not_equinox_month?(m) do
    # Portal update, sunrise is expanding 40 minutes in either direction
    cdt
    |> inc_day()
    |> Map.put(:minute, 0)
    |> Map.put(:hour, 0)
  end
  def tick(%CDT{minute: 39, hour: 17, month_day: 31} = cdt) do
    # Portal update, sunrise is expanding 40 minutes in either direction
    cdt
    |> inc_day()
    |> Map.put(:minute, 0)
    |> Map.put(:hour, 0)
  end
  def tick(%CDT{minute: 79, hour: 17} = cdt), do: inc_day(cdt) |> Map.put(:minute, 0) |> Map.put(:hour, 0)
  def tick(%CDT{minute: 79, hour: hour} = cdt), do: %{cdt | minute: 0, hour: hour + 1}
  def tick(%CDT{minute: min} = cdt), do: %{cdt | minute: min + 1}

  @doc """
  Tick during the great spring equinox! Do not advance the day because until the following sunrise
  of the equinox event, we are in the same year.
  """
  def tick_spring_equinox(%CDT{minute: 79, hour: h} = cdt), do: %{cdt | minute: 0, hour: h + 1}
  def tick_spring_equinox(%CDT{minute: min} = cdt), do: %{cdt | minute: min + 1}

  def inc_day(%CDT{year_day: 364} = cdt) do
    case cdt do
      %{events: ["New Years Day"|_], coord: %{"lat" => lat, "long" => long}} ->
        tz = EnochEx.Calendar.get_approximate_tz(lat, long)
        now = Timex.now(tz)
        {:ok, sunrise} = Astro.sunrise({long, lat}, now)

        cdt
        |> inc_week()
        |> inc_month()
        |> inc_year()
        |> Map.put(:day, 1)
        |> Map.put(:week_day, 4)
        |> Map.put(:minute, 0)
        |> Map.put(:hour, 0)
        |> Map.put(:gregorian_sunrise, sunrise)
      %{events: _, minute: 79, hour: h} ->
        %{cdt | minute: 0, hour: h + 1}

      %{events: _, minute: m} ->
        %{cdt | minute: m + 1}
    end
  end

  def inc_day(%CDT{day: d, coord: %{"lat" => lat, "long" => long}} = cdt) do
    tz = EnochEx.Calendar.get_approximate_tz(lat, long)
    now = Timex.now(tz)
    {:ok, sunrise} = Astro.sunrise({long, lat}, now)

    cdt
    |> inc_week()
    |> inc_month()
    |> inc_year()
    |> Map.put(:day, d + 1)
    |> Map.put(:gregorian_sunrise, sunrise)
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
      "true_noon" => true_noon_clock(cdt),
      "year_day" => cdt.year_day,
      "holidays" => Date.special_days(cdt),
      "parts_day" => cdt.parts_day,
      "parts_night" => cdt.parts_night
    }
  end

  def pretty(_), do: nil

  @doc """
  Create a new CurrentDateTime model for the start of a new year, for the given Calendar
  """
  def initialize(%Calendar{coord: coord, spring_sunrise: sunrise, current_datetime: cdt} = cal) do
    {_, _, _, {parts_day, parts_night}} = EnochEx.Enoch.Date.get_month_info("spring")

    true_noon = true_noon(cal)
    
    cal
    |> Map.put(:current_datetime, %{cdt | true_noon: {1, true_noon}, 
      parts_day: parts_day, 
      parts_night: parts_night,
      coord: coord,
      gregorian_sunrise: sunrise})
    |> Gregorian.calendar_now_to_enoch_cdt()
    |> Map.get(:current_datetime)
  end

  @doc """
  Return the Enoch time at which the sun reaches it's halfway point for the current day.

  # TODO: need to add option to get EXACT instead of approximate. We are using portal
  # math only currently (sunrise after equinox and then portal hour additions)

  @returns {hour of current day of true noon, minute of current day of true noon}
  """
  def true_noon(%Calendar{current_datetime: %CDT{parts_day: parts_day}}) do  
    # Take daylight hours portal and cut in half
    hours_after_sunrise = div(parts_day, 2)
    mins_after_sunrise = round(((parts_day / 2) - hours_after_sunrise) * 80)

    {hours_after_sunrise, mins_after_sunrise}
  end

  # PRIVATE FUNCTIONS
  ###################
  defp update_day_parts(%CDT{month: month_num} = cdt) do
    parts = Date.get_month_info_by_number(month_num) |> elem(3)
    parts_day = parts |> elem(0)
    parts_night = parts |> elem(1)
    
    %{cdt | parts_day: parts_day, parts_night: parts_night}
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

  defp true_noon_clock(%CDT{true_noon: {_, {hour, minute}}}), do: clock(hour, minute, "")
end