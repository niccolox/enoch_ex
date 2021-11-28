defmodule EnochEx.Calendar.Guards do
  @moduledoc """
  Custom guard classes for the Calendar and CurrentDateTime
  """
  defguard equinox_month?(m) when m in [3, 6, 9, 12]

  defguard not_equinox_month?(m) when m in [1, 2, 4, 5, 7, 8, 10, 11]

  # This is if doing the sunrise decrease on a weekly cadence
  defguard descrease_sunrise_minute?(d) when d in [7, 14, 21, 28]

  defguard sunrise_hour?(h) when is_integer(h) and h >= 0 and h <= 17
end