defmodule EnochEx.Calendar.Job do
  @moduledoc """
  Control timed cron jobs related to calendars
  """
  import Crontab.CronExpression


  def if_new_calendar_start_ticking({:error, {:already_started, _pid}}, sunrise_hour) do
    Registry.lookup(CalendarRegistry, "calendar:#{sunrise_hour}")
    |> List.first()
    |> elem(0)
  end

  def if_new_calendar_start_ticking({:ok, _}, sunrise_hour) do
    Registry.lookup(CalendarRegistry, "calendar:#{sunrise_hour}")
    |> List.first()
    |> elem(0)
    |> start_calendar_job(sunrise_hour)
  end

  def start_calendar_job(pid, sunrise_hour) do
    EnochEx.Scheduler.new_job()
    |> Quantum.Job.set_name(String.to_atom("ticker:#{sunrise_hour}"))
    |> Quantum.Job.set_schedule(~e[* * * * *])
    |> Quantum.Job.set_task(fn ->
      _ = pid
      |> GenServer.call(:tick)
      |> Map.get(:current_datetime)
      |> IO.inspect()
    end)
    |> EnochEx.Scheduler.add_job()
  end
end