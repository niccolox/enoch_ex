defmodule EnochEx.Calendar.Model.Calendar do
  alias EnochEx.Calendar.Model.Year
  alias EnochEx.Calendar.Model.CurrentDatetime, as: CDT


  defstruct [
    city: "default",
    coord: %{"lat" => nil, "long" => nil},
    timezone: nil,       # Gregorian
    spring_sunrise: nil, # Gregorian
    year: %Year{}, 
    current_datetime: %CDT{},
    tick_callback: nil
  ]
end