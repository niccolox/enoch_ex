defmodule EnochEx.Calendar.Guards do
  @moduledoc """
  Custom guard classes for the Calendar and CurrentDateTime
  """
  defguard equinox_month?(m) when m in [3, 6, 9, 12]

  defguard not_equinox_month?(m) when m in [1, 2, 4, 5, 7, 8, 10, 11]

  defguard descrease_sunrise_minute?(d) when d in [7, 14, 21, 28]
end