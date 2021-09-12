defmodule EnochEx.Calendar.Application do
  use DynamicSupervisor

  alias EnochEx.Calendar.Server, as: CalendarServer

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_child(calendar) do
    child_spec = {CalendarServer, calendar}

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def remove_child(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  def children() do
    DynamicSupervisor.which_children(__MODULE__)
  end

  def count_children do
    DynamicSupervisor.count_children(__MODULE__)
  end
end
