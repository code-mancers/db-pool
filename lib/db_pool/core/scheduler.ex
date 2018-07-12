# https://github.com/code-mancers/dockup/blob/eadc53a8/apps/dockup_ui/lib/dockup_ui/scheduler.ex
# Copied from DockupUi.Scheduler to keep it simple :)
defmodule DbPool.Core.Scheduler do
  use GenServer
  require Logger

  import Ecto.Query, warn: false

  alias DbPool.Core.Database
  alias DbPool.Core.Importer

  @interval_5_mins_msec 5 * 60 * 1000

  @doc """
  Starts a Scheduler and kicks off the loop
  """
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    Process.send(self(), :import_if_any, [])
    {:ok, nil}
  end

  def handle_info(:import_if_any, state) do
    import_databases_if_any()

    {:noreply, state}
  end

  defp set_import_timer do
    Process.send_after(self(), :import_if_any, @interval_5_mins_msec)
  end

  defp import_databases_if_any do
    next_database_to_import =
      Database
      |> Ecto.Query.where(status: "importing")
      |> Ecto.Query.order_by([asc: :id])
      |> Ecto.Query.first
      |> DbPool.Repo.one

    if next_database_to_import do
      Importer.start_importing(next_database_to_import)
      Process.send(self(), :import_if_any, [])
    else
      set_import_timer()
    end
  end
end