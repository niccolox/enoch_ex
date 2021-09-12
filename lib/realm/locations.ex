defmodule EnochEx.Locations do
  @moduledoc """
  Location data that helps calibrate clocks
  """

  # Approximations that help calibrate for certain cities
  # city => {Latitude, Longitude}
  @city_approx %{
    "seattle" => {47.526212840200216, -122.10657286376953}
  }
end