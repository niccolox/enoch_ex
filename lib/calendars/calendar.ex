defmodule EnochEx.Calendar do
  @moduledoc """
  Calendars app runs calendar processes on a basis of 1 calendar per timezone.
  A calendar calibrates itself using the current years solstice and then becomes available
  to provide dates forward or backwards in time.
  """
  alias EnochEx.Calendar.Model.Calendar, as: ModelCalendar
  alias EnochEx.Calendar.Model.Day, as: Day
  alias EnochEx.Calendar.Model.Month, as: Month
  alias EnochEx.Calendar.Model.Year, as: Year
  alias EnochEx.Enoch.Date, as: EnochDate
  alias EnochEx.Calendar.Model.CurrentDatetime, as: CDT
  alias EnochEx.Calendar.Job
  alias EnochEx.Enoch.Date
  alias EnochEx.Enoch.Gregorian

  # Cougar Mountain Greater Seattle Area
  @default_lat 47.526212840200216
  @default_long -122.10657286376953 

  @doc """
  Start the calendar after initializing if it hasn't yet been created
  """
  def start_calendar(), do: start_calendar({@default_lat, @default_long})

  def start_calendar({latitude, longitude}) do
    tz = get_approximate_tz(latitude, longitude)
    now = Timex.now(tz)

    {:ok, vernal_equinox} = Astro.equinox(now.year, :march)

    new_years_day = Timex.add(vernal_equinox, Timex.Duration.from_days(1)) 

    {:ok, spring_sunrise} = Astro.sunrise({longitude, latitude}, new_years_day)
    {:ok, sunrise} = Astro.sunrise({longitude, latitude}, now)

    {_, _, _, {parts_day, parts_night}} = EnochDate.get_month_info("spring")

    sunrise_hour = Date.get_sunrise_hour(spring_sunrise)

    %ModelCalendar{
      coord: %{"lat" => latitude, "long" => longitude}, 
      timezone: tz,
      current_datetime: %CDT{
        year: now.year,
        day: 1,
        week_day: 4,
        month_day: 1,
        year_day: 1,
        event_day: nil,
        hour: 0,
        minute: 0,
        month: 1,
        parts_day: parts_day,
        parts_night: parts_night,
        sunrise_hour: Gregorian.to_enoch_hour(spring_sunrise, true)
      },
      sunrise: sunrise,
      spring_sunrise: spring_sunrise,
      sunrise_hour: sunrise_hour,
      year: Date.fill_cal_year(%Day{}, now.year, %Month{}, %Year{number: now.year})
    }
    |> Gregorian.calendar_now_to_enoch_cdt()
    |> EnochEx.Calendar.Application.add_child()
    |> Job.if_new_calendar_start_ticking(sunrise_hour)
  end

  @doc """
  Return the current datetime of the calendar at the given coords

  @return CurrentDatetime 
  """
  def now(sunrise_hour) do
    case Registry.lookup(CalendarRegistry, "calendar:#{sunrise_hour}") do
      [] -> {}
      [{pid, _}] -> GenServer.call(pid, :now)
    end
  end

  def get_approximate_tz(latitude, longitude) do
    case WhereTZ.get(latitude, longitude) do
      [tz|_] -> tz
      tz -> tz
    end
  end

  def update_tick_callback(sunrise_hour, tick_callback) do
    case Registry.lookup(CalendarRegistry, "calendar:#{sunrise_hour}") do
      [] -> {:error, "no calendar started for this hour"}
      [{pid, _}] -> {:ok, GenServer.call(pid, {:update_tick_callback, tick_callback})}
    end
  end
end