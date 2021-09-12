defmodule EnochEx do
  @moduledoc """
  EnochEx is an elixir based library to help track where you are at on Enoch's original solar calendar granted by Uriel. It 
  uses your location as determined by IP (or long/lat input) to orient sunrise and spring equinox.

  @see https://www.enochcalendar.com/enoch-calendar-explained
  """
  # 

  @doc """
  Retrieve the current date.

  ## Examples

      iex> EnochEx.now()
      %{}

  """
  @default_sunrise_hour 7

  def now(), do: now(@default_sunrise_hour)

  def now(sunrise_hour) do
    sunrise_hour
    |> EnochEx.Calendar.now()
    |> EnochEx.Calendar.CurrentDatetime.pretty()
  end

  def start_calendar() do
    EnochEx.Calendar.start_calendar()
  end
end
