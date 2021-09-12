defmodule EnochEx.Enoch.Gregorian do
  @moduledoc """
  For transforming gregorian times and dates to enoch as best as possible.
  """
  alias EnochEx.Calendar.CurrentDatetime
  alias EnochEx.Calendar.Model.Calendar, as: Cal
  alias EnochEx.Calendar.Model.CurrentDatetime, as: CDT
  alias EnochEx.Enoch.Date

  @doc """
  Taking the current time in gregorian, find and return a CDT map containing the current Enoch Time, using
  a calendar calibrated for a lat/long. Note that it is assumed the passed Calendar is initialized with default
  day, year etc..
  """
  def calendar_now_to_enoch_cdt(%Cal{timezone: tz, current_datetime: cdt} = cal) do
    now = Timex.now(tz)

    {:ok, vernal_equinox} = Astro.equinox(now.year, :march)

    equinox_delta = Timex.diff(now, vernal_equinox, :days) - 1

    if equinox_delta < 0 do
      {:ok, vernal_equinox} = Astro.equinox(now.year - 1, :march)

      equinox_delta = Timex.diff(vernal_equinox, now, :days) - 1

      cdt
      |> Date.increment_year(-1)
      |> update_cdt(cal)
      |> inc_days(equinox_delta)
      |> calendar_now_to_enoch_time()
    else
      cal
      |> inc_days(equinox_delta)
      |> calendar_now_to_enoch_time()
    end
  end

  def calendar_now_to_enoch_time(%Cal{timezone: tz, sunrise: sunrise, sunrise_hour: sunrise_hour} = cal) do
    now = Timex.now(tz)

    minutes = ((now.hour - sunrise_hour) * 60) + (now.minute - sunrise.minute)

    inc_time(cal, minutes)
  end

  def to_enoch_hour(datetime, rounded \\ false) do
    greg_minutes = datetime.hour * 60 + datetime.minute

    enoch_hour = trunc(greg_minutes / 80)
    enoch_minute = rem(greg_minutes, 80)

    case rounded do
      false ->
        {enoch_hour, enoch_minute}
      true ->
        cond do
          enoch_minute >= 40 -> enoch_hour + 1
          true -> enoch_hour
        end
    end
  end

  # PRIVATE FUNCTIONS
  #############################
  defp inc_days(%Cal{} = cal, 0), do: cal

  defp inc_days(%Cal{timezone: tz, current_datetime: cdt, coord: %{"lat" => lat, "long" => long}} = cal, 1) do
    now = Timex.now(tz)

    {:ok, now_sunrise} = Astro.sunrise({long, lat}, now)

    if now.hour >= now_sunrise.hour  do
      # Sunrise has passed
      cdt
      |> CurrentDatetime.inc_day()
      |> update_cdt(cal)
      |> inc_days(0)
    else
      cdt 
      |> CurrentDatetime.inc_day() 
      |> update_cdt(cal)
    end
  end

  defp inc_days(%Cal{current_datetime: cdt} = cal, num_days) do
    cdt
    |> CurrentDatetime.inc_day()
    |> update_cdt(cal)
    |> inc_days(num_days - 1)
  end

  defp inc_time(%Cal{} = cal, 0), do: cal

  defp inc_time(%Cal{current_datetime: cdt} = cal, minutes) do
    cdt
    |> CurrentDatetime.tick()
    |> update_cdt(cal)
    |> inc_time(minutes - 1)
  end

  defp update_cdt(%CDT{} = cdt, %Cal{} = cal), do: %{cal | current_datetime: cdt}
end