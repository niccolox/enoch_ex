defmodule EnochEx.Calendar.Server do
  @moduledoc """
  Serves a Calendar for a singular region. Each Calendar services a timezone determined by rounded runrise
  time in their zone at the first day after spring equinox.
  """
  use GenServer

  alias EnochEx.Calendar.Model.Calendar, as: Cal
  alias EnochEx.Calendar.CurrentDatetime
  alias EnochEx.Enoch.Gregorian


  def start_link(%Cal{sunrise_hour: sunrise_hour} = calendar) do
    GenServer.start_link(
      __MODULE__,
      calendar,
      name: {:via, Registry, {CalendarRegistry, "calendar:#{sunrise_hour}"}},
      timeout: :infinity
    )
  end

  @impl true
  def init(calendar), do: {:ok, calendar}

  @impl true
  def handle_call(:tick, _from, %Cal{current_datetime: cdt, tick_callback: tick_callback} = state) do
    IO.inspect("TICK")
    IO.inspect(tick_callback)
    cdt
    |> CurrentDatetime.tick()
    |> spring_equinox_check(state)
    |> callback_if_set(tick_callback)
    |> update_state_and_reply(:current_datetime, state)
  end

  @impl true
  def handle_call({:update_tick_callback, callback_func}, _from, %Cal{} = state) do
    update_state_and_reply(callback_func, :tick_callback, state)
  end

  @impl true
  def handle_call(:now, _from, %Cal{current_datetime: cdt} = state) do
    {:reply, cdt, state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  # PRIVATE FUNCTIONS
  ###################
  defp spring_equinox_check(%{year_day: 364} = cdt, %Cal{coord: coords}) do
    tz = EnochEx.Calendar.get_approximate_tz(coords["lat"], coords["long"])
    now = Timex.now(tz)

    {:ok, vernal_equinox} = Astro.equinox(now.year, :march)

    if vernal_equinox < now do
      {current_enoch_hour, _minutes} = Gregorian.to_enoch_hour(now)

      new_years_day = Timex.add(vernal_equinox, Timex.Duration.from_days(1))

      {:ok, spring_sunrise} = Astro.sunrise({coords["long"], coords["lat"]}, new_years_day)

      sunrise_hour = Gregorian.to_enoch_hour(spring_sunrise, true)

      if current_enoch_hour >= sunrise_hour do
        cdt
        |> Map.put(:events, ["New Years Day"])
        |> CurrentDatetime.inc_day()
      else
        cdt
      end
    else
      cdt
    end
  end

  defp spring_equinox_check(cdt, _), do: cdt

  defp update_state_and_reply(new_val, key, state) do
    state = %{state | key => new_val}

    {:reply, state, state}
  end

  defp callback_if_set(cdt, tick_callback) when is_function(tick_callback) do
    IO.inspect("TICK CALLBACK")
    _ = tick_callback.(cdt)
    cdt
  end

  defp callback_if_set(cdt, _), do: cdt
end
