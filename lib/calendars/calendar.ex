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
  alias EnochEx.Calendar.Model.CurrentDatetime, as: CDT
  alias EnochEx.Calendar.CurrentDatetime
  alias EnochEx.Calendar.Job
  alias EnochEx.Enoch.Date

  # Cougar Mountain Greater Seattle Area
  @default_city "seattle"

  @doc """
  Initialize a calendar and start ticking it's clock if it hasn't yet been started
  """
  def start_calendar(options \\ []), do: start_calendar(@default_city, options)

  def start_calendar(city, options) do
    # TODO: handle city not found
    {latitude, longitude} = EnochEx.Realm.Locations.city_coords(city)

    tz = get_approximate_tz(latitude, longitude)
    now = Timex.now(tz)

    {:ok, vernal_equinox} = Astro.equinox(now.year, :march)

    new_years_day = Timex.add(vernal_equinox, Timex.Duration.from_days(1)) 

    {:ok, spring_sunrise} = Astro.sunrise({longitude, latitude}, new_years_day)

    %ModelCalendar{}
    |> set(
      city: city, 
      coord: %{"lat" => latitude, "long" => longitude},
      timezone: tz,
      spring_sunrise: spring_sunrise,
      year: Date.fill_cal_year(%Day{}, now.year, %Month{}, %Year{number: now.year}))
    |> set(cdt: :current)
    |> EnochEx.Calendar.Application.add_child()
    |> Job.if_new_calendar_start_ticking(city, options)
  end

  @doc """
  Return the current datetime of the calendar at the given coords

  @return %CDT{}
  """
  def now(city) do
    case Registry.lookup(CalendarRegistry, "calendar:#{city}") do
      [] ->
        _ = start_calendar(city, [])
        now(city)
      [{pid, _}] -> 
        GenServer.call(pid, :now)
    end
  end

  @doc """
  Get the approximate timezone for the given coords
  """
  def get_approximate_tz(latitude, longitude) do
    case WhereTZ.get(latitude, longitude) do
      [tz|_] -> tz
      tz -> tz
    end
  end

  @doc """
  Update the callback used upon each tick of the clock for a given city
  """
  def update_tick_callback(city, tick_callback) do
    case Registry.lookup(CalendarRegistry, "calendar:#{city}") do
      [] -> {:error, "no calendar started for this hour"}
      [{pid, _}] -> {:ok, GenServer.call(pid, {:update_tick_callback, tick_callback})}
    end
  end

  # PRIVATE FUNCTIONS ###############
  ###################################
  defp set(cal, []), do: cal
  defp set(cal, [{:cdt, %CDT{} = cdt}|t]), do: %{cal | current_datetime: cdt} |> set(t)
  defp set(cal, [{:cdt, :current}|t]), do: %{cal | current_datetime: CurrentDatetime.initialize(cal)} |> set(t)
  defp set(cal, [{:coord, %{"lat" => _, "long" => _} = coord}|t]), do: %{cal | coord: coord} |> set(t)
  defp set(cal, [{:city, city}|t]) when is_binary(city), do: %{cal | city: city} |> set(t)
  defp set(cal, [{:spring_sunrise, sunrise}|t]), do: %{cal | spring_sunrise: sunrise} |> set(t)
  defp set(cal, [{:timezone, tz}|t]), do: %{cal | timezone: tz} |> set(t)
  defp set(cal, [{:year, %Year{} = year}|t]), do: %{cal | year: year} |> set(t)
  defp set(cal, [opt|t]) do
    IO.inspect("INVALID OPT")
    IO.inspect(opt)
    set(cal, t)
  end
end