defmodule EnochEx.Calendar.Job do
  @moduledoc """
  Control timed cron jobs related to calendars
  """
  import Crontab.CronExpression


  def if_new_calendar_start_ticking({:error, {:already_started, _pid}}, city, options) do
    Registry.lookup(CalendarRegistry, "calendar:#{city}")
    |> List.first()
    |> elem(0)
    |> process_options(options)
  end

  def if_new_calendar_start_ticking({:ok, _}, city, options) do
    Registry.lookup(CalendarRegistry, "calendar:#{city}")
    |> List.first()
    |> elem(0)
    |> process_options(options)
    |> start_calendar_job(city)
  end

  def start_calendar_job(pid, city) do
    EnochEx.Scheduler.new_job()
    |> Quantum.Job.set_name(String.to_atom("ticker:#{city}"))
    |> Quantum.Job.set_schedule(~e[* * * * *])
    |> Quantum.Job.set_task(fn ->
      _ = pid
      |> GenServer.call(:tick)
      |> Map.get(:current_datetime)
    end)
    |> EnochEx.Scheduler.add_job()
  end

  defp process_options(pid, [{:tick_callback, callback}|t]) do
    _ = GenServer.call(pid, {:update_tick_callback, callback})
    process_options(pid, t)
  end

  defp process_options(pid, _), do: pid
end