defmodule EnochEx.Realm.Locations do
  @moduledoc """
  Location data that helps calibrate clocks

  NOTE that cities are currently in northern hemisphere. Support for south not ready
  """

  # Geo Point presets that help calibrate for certain cities without resorting to a larger database
  # city => {Latitude, Longitude}
  @city_approx %{
    "seattle" => {47.526212840200216, -122.10657286376953}, # WA, USA
    "sand point" => {48.28058001136279, -116.55201846326904}, # ID, USA
    "dallas" => {32.838225703929595, -96.64421300862456}, # TX, USA
    "thunder bay" => {48.38922242266776, -88.65165929768708}, # ON, CA
    "sandy hook bay" => {40.4417778, -74.0293158}, # NJ, USA
    "sermersooq" => {64.27027468009624, -51.232684940625}, # Greenland
    "dublin" => {53.349775777071414, -6.264270633984372}, # IR
    "athens" => {37.94317290635824, 23.733898311328126}, # GR
    "qumran" => {31.762098568407893, 35.499686820993425},
    "chelyabinsk" => {55.019405810224406, 62.21843682099339}, # RU
    "kochi" => {9.93240364587887, 76.29741631318089}, # Kerala, INDIA
    "lhasa" => {29.61292946037415, 91.19625054169651}, # Tibet
    "ulaanbaatar" => {47.924675404140665, 106.95613823700901}, # Mongolia
    "bardon" => {27.45825398191289, 152.96688042450901}, # Australia
    "sapporo" => {42.8689741450508, 141.48616753388401}, # Japan
    "egvekinot" => {66.27186057072166, -179.11685980986599}, # Russia
    "chukotski" => {65.51811614032593, -170.9004596633816}, # Russia
    "honolulu" => {21.3060780051964, -157.8377155227566} # Hawaii, USA
  }

  def city_coords(city), do: Map.get(@city_approx, city, :not_found)
end