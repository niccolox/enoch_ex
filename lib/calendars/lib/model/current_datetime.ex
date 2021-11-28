defmodule EnochEx.Calendar.Model.CurrentDatetime do
  defstruct [
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
    coord: %{"lat" => nil, "long" => nil}]
end