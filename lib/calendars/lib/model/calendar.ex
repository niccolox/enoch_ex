defmodule EnochEx.Calendar.Model.Calendar do
  alias EnochEx.Calendar.Model.Year
  alias EnochEx.Calendar.Model.CurrentDatetime, as: CurrentDatetime


  defstruct [
    coord: %{"lat" => nil, "long" => nil},
    timezone: nil,       # Gregorian
    sunrise: nil,        # Gregorian
    sunrise_hour: 6,     # Gregorian (on spring equinox)
    spring_sunrise: nil, # Gregorian
    year: %Year{}, 
    current_datetime: %CurrentDatetime{},
    tick_callback: nil
  ]
end