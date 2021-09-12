defmodule EnochEx.Enoch.Date do
  @moduledoc """
  """
  alias EnochEx.Calendar.Model.CurrentDatetime, as: CDT
  alias EnochEx.Calendar.Model.Day
  alias EnochEx.Calendar.Model.Month
  alias EnochEx.Calendar.Model.Year

  # {Sign, Gate, Season, Portals}
  @months %{
    "spring" => {"aries", 4, "mid spring", {10, 8}},
    "mid spring" => {"taurus", 5, "late spring", {11, 7}},
    "late spring" => {"gemini", 6, "summer", {12, 6}},
    "summer" => {"cancer", 6, "mid summer", {11, 7}},
    "mid summer" => {"leo", 5, "late summer", {10, 8}},
    "late summer" => {"virgo", 4, "autumn", {9, 9}},
    "autumn" => {"libra", 3, "mid autumn", {8, 10}},
    "mid autumn" => {"scorpio", 2, "late autumn", {7, 11}},
    "late autumn" => {"sagittarius", 1, "winter", {6, 12}},
    "winter" => {"capricorn", 1, "mid winter", {7, 11}},
    "mid winter" => {"aquarius", 2, "late winter", {8, 10}},
    "late winter" => {"pisces", 3, "spring", {9, 9}}
  }
  @month_numbers %{
    1  => "spring",
    2  => "mid spring",
    3  => "late spring",
    4  => "summer",
    5  => "mid summer",
    6  => "late summer",
    7  => "autumn",
    8  => "mid autumn",
    9  => "late autumn",
    10 => "winter",
    11 => "mid winter",
    12 => "late winter"
  }
  @holidays %{
    "week_day" => %{
      7 => "Sabbath"
    },
    "year_day" => %{
      91 => "Summer Solstice",
      182 => "Autumnal Equinox",
      273 => "Winter Solstice",
      364 => "Spring Equinox"
    }
  }

  def special_days(%CDT{} = cdt), do: special_days("week_day", cdt, [])

  def special_days("week_day", %CDT{week_day: wd} = cdt, acc) do
    case Map.get(@holdays["week_day"], wd) do
      nil -> special_days("year_day", cdt, acc)
      holiday -> special_days("year_day", cdt, [holiday|acc])
    end
  end

  def special_days("year_day", %CDT{year_day: yd} = cdt, acc) do
    case Map.get(@holdays["year_day"], yd) do
      nil -> acc
      holiday -> [holiday|acc]
    end
  end

  def get_month_info(season), do: Map.get(@months, season)
  def get_month_info_by_number(num), do: Map.get(@month_numbers, num) |> get_month_info()

  def increment_year(%CDT{year: year} = cdt, amt), do: %{cdt | year: year + amt}

  def get_sunrise_hour(sunrise) do
    cond do
      sunrise.minute >= 40 -> sunrise.hour + 1
      true -> sunrise.hour
    end
  end

  def fill_cal_year(_, cy, _, %Year{number: new_y} = y) when new_y > cy, do: %{y | number: cy}

  def fill_cal_year(%Day{day_of_month: dom} = d, cy, %Month{season: season, days: days} = m, %Year{months: months} = y) do
    # Fill current month and day into year
    new_m = %{m | days: Map.put(days, dom, d)}
    new_y = %{y | months: %{months | season => new_m}}
    # Increment day and continue
    new_d = d
    |> next_day_of_week()
    |> next_day_of_month(new_m)
    |> next_day_of_year()

    fill_cal_year(new_d, cy, next_month(new_d, new_m), next_year(new_d, new_y))
  end
  
  # Spring Equinox (non-day event) reached
  def next_day_of_week(%Day{day_of_year: 363} = d), do: %{d | day_of_week: :spring_equinox}
  # New year! (starts on 4th day, when luminaries created)
  def next_day_of_week(%Day{day_of_week: :spring_equinox, day_of_year: 364} = d), do: %{d | day_of_week: 4}
  def next_day_of_week(%Day{day_of_week: 7} = d), do: %{d | day_of_week: 1}
  def next_day_of_week(%Day{day_of_week: dow} = d), do: %{d | day_of_week: dow + 1}
  # Find the next day of month
  def next_day_of_month(%Day{day_of_month: 30} = d, %Month{solstice_equinox: nil}), do: %{d | day_of_month: 1}
  def next_day_of_month(%Day{day_of_month: 31} = d, _), do: %{d | day_of_month: 1}
  def next_day_of_month(%Day{day_of_month: dom} = d, _), do: %{d | day_of_month: dom + 1}
  # Find the next day of year
  def next_day_of_year(%Day{day_of_year: 364} = d), do: %{d | day_of_year: 1}
  def next_day_of_year(%Day{day_of_year: doy} = d), do: %{d | day_of_year: doy + 1}
  # Increment the month if it is time
  def next_month(%Day{day_of_month: 1}, m), do: m |> next_season()
  def next_month(_d, m), do: m
  # Increment the year if it is time
  def next_year(%Day{day_of_year: 1}, %Year{number: curr_year} = y), do: %{y | number: curr_year + 1}
  def next_year(_, y), do: y
  # Increment the season for the curr month
  def next_season(%Month{season: season} = m) do
    {sign, portal, next_season, {parts_day, parts_night}} = get_month_info(season)

    %{m | portal: portal, season: next_season, sign: sign, day_hours: parts_day, night_hours: parts_night}
  end
end