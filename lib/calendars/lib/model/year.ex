defmodule EnochEx.Calendar.Model.Year do
  alias EnochEx.Calendar.Model.Month

  defstruct [
    number: 2021,
    months: %{
      "spring" => %Month{},
      "mid spring" => %Month{},
      "late spring" => %Month{},
      "summer" => %Month{},
      "mid summer" => %Month{},
      "late summer" => %Month{},
      "autumn" => %Month{},
      "mid autumn" => %Month{},
      "late autumn" => %Month{},
      "winter" => %Month{},
      "mid winter" => %Month{},
      "late winter" => %Month{}
    }
  ]
end