defmodule EnochEx.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    Supervisor.start_link([], strategy: :one_for_one, name: EnochEx.Supervisor)
  end

  def init(:ok) do
    children = [
      {Registry, keys: :unique, name: CalendarRegistry},
      TzWorld.Backend.EtsWithIndexCache,
      EnochEx.Calendar.Application,
      EnochEx.Scheduler
    ]

    Supervisor.init(children, strategy: :one_for_one, name: EnochEx.Supervisor)
  end

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, [])
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
end
