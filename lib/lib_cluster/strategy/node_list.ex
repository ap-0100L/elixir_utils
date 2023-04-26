defmodule LibCluster.Strategy.NodeList do
  @moduledoc """

  ## Usage

      config :libcluster,
        topologies: [
          node_list_example: [
            strategy: #{__MODULE__},
            config: [
              interval: 5_000,
              node_list: [:node1, :node2, :node3],
              exit_on_fail: true
          ]]]
  """

  use GenServer
  use Utils

  alias Cluster.Strategy.State, as: State
  alias Cluster.Strategy, as: Strategy

  @default_interval 5_000

  ##############################################################################
  @doc """
  ## Function
  """
  def start_link([%State{config: config} = _state] = args) do
    node_list = Keyword.get(config, :node_list, [])

    case node_list do
      [] ->
        :ignore

      nodes when is_list(nodes) ->
        GenServer.start_link(__MODULE__, args)

      _ ->
        UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["node_list must be a list"])
    end
  end

  @impl true
  def init([%State{} = state]) do
    {:ok, do_connect(state)}
  end

  @impl true
  def handle_info(:connect, state), do: {:noreply, do_connect(state)}
  def handle_info(_, state), do: {:noreply, state}

  defp do_connect(
         %State{
           topology: topology,
           config: config,
           connect: connect,
           disconnect: _disconnect,
           list_nodes: list_nodes
         } = state
       ) do
    node_list = Keyword.get(config, :node_list, [])

    case Strategy.connect_nodes(
           topology,
           connect,
           list_nodes,
           node_list
         ) do
      :ok ->
        node_list

      {:error, bad_nodes} ->
        exit_on_fail = Keyword.get(config, :exit_on_fail, false)

        if exit_on_fail do
          exit("[#{inspect(__MODULE__)}][#{inspect(__ENV__.function)}] Cannot connect to nodes: #{inspect(bad_nodes)}")
        else
          Logger.error("[#{inspect(__MODULE__)}][#{inspect(__ENV__.function)}] Cannot connect to nodes: #{inspect(bad_nodes)}")
        end
    end

    connect_interval = Keyword.get(config, :interval, @default_interval)
    Process.send_after(self(), :connect, connect_interval)

    state
  end
end
