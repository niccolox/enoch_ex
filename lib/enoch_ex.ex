defmodule EnochEx do
  @moduledoc """
  EnochEx is an elixir based library to help track where you are at on Enoch's original solar calendar granted by Uriel. It 
  uses your location as determined by IP (or long/lat input) to orient sunrise and spring equinox.

  @see https://www.enochcalendar.com/enoch-calendar-explained
  """
  alias EnochEx.Enoch.Gregorian
  
  @default_city "seattle"

  
  @doc """
  Return a prettified version of the current Enoch datetime, using a lookup such as a sunrise hour or lat/long
  """
  def now(), do: now(@default_city)

  def now(lookup) do
    lookup
    |> EnochEx.Calendar.now()
    |> EnochEx.Calendar.CurrentDatetime.pretty()
  end

  @doc """
  Starts a calendar for a specific timezone (or default zone)
  """
  def start_calendar(options \\ []), do: EnochEx.Calendar.start_calendar(options)

  def start_calendar(city, options), do: EnochEx.Calendar.start_calendar(city, options)

  @doc """
  Return the rounded sunrise hour for a coordinate. Note that the rounded sunrise represents a
  key for a 'timezoned' calendar
  """
  def spring_equinox_sunrise({lat, long}) do
    tz = EnochEx.Calendar.get_approximate_tz(lat, long)
    now = Timex.now(tz)

    {:ok, vernal_equinox} = Astro.equinox(now.year, :march)

    new_years_day = Timex.add(vernal_equinox, Timex.Duration.from_days(1)) 

    {:ok, spring_sunrise} = Astro.sunrise({long, lat}, new_years_day)

    Gregorian.to_enoch_hour(spring_sunrise, true)
  end

  def spring_equinox_sunrise(city) do
    EnochEx.Realm.Locations.city_coords(city)
    |> spring_equinox_sunrise()
  end

  @doc """
  Return a preset of coordinates from a list of cities hardcoded into the application. Returns a tuple
  with lat and long. Returns :not_found if no preset for the given name

  @returns {latitude, longitude}
  """
  def city_preset_coords(city), do: EnochEx.Realm.Locations.city_coords(city)
end
