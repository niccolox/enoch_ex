defmodule EnochExTest do
  use ExUnit.Case
  doctest EnochEx

  test "greets the world" do
    assert EnochEx.hello() == :world
  end
end
