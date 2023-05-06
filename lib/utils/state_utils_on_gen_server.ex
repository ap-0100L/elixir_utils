defmodule StateUtils.OnGenServer do
  ##############################################################################
  ##############################################################################
  @moduledoc """
    children = [
      {Registry, keys: :unique, name: StateUtils.OnGenServer.get_registry_name()},
      {DynamicSupervisor, strategy: :one_for_one, name: StateUtils.OnGenServer.get_dynamic_supervisor_name()}
  ]
  """

  use GenServer
  use Utils

  @registry_name StateUtils.OnGenServer.Registry
  @dynamic_supervisor_name StateUtils.OnGenServer.DynamicSupervisor

  ##############################################################################
  @doc """
  ## Function
  """
  def get_registry_name() do
    @registry_name
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def get_dynamic_supervisor_name() do
    @dynamic_supervisor_name
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def init_registry() do
    Registry.start_link(keys: :unique, name: @registry_name)
    DynamicSupervisor.start_link(strategy: :one_for_one, name: @dynamic_supervisor_name)
  end


  ##############################################################################
  @doc """
  ## Function
  """
  @impl true
  def init(state) do
    name = Map.fetch!(state, :name)

    {:ok, state}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def start_link(state \\ %{}) do
    name = Map.fetch!(state, :name)

    GenServer.start_link(__MODULE__, state, name: {:via, Registry, {@registry_name, name}})
  end

  ##############################################################################
  @doc """
  ## Function
  """
  @impl true
  def handle_call({:get, key}, _from, state) do
    value = Map.get(state, key)

    {:reply, {:ok, value}, state}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_call({:set, state}, _from, old_state) do
    {:reply, {:ok, old_state}, state}
  end

  @impl true
  def handle_call({:set, key, value}, _from, state) do
    old_value = Map.get(state, key)
    state = Map.put(state, key, value)

    {:reply, {:ok, old_value}, state}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def init_state!(name, state \\ %{})

  def init_state!(name, state)
      when not is_atom(name) or not is_map(state),
      do:
        UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, [
          "name, state cannot be nil; name must be an atom; state must a map"
        ])

  def init_state!(name, state) do
    result =
      UniError.rescue_error!(
        (
          state = Map.put(state, :name, name)
          item = Supervisor.child_spec({__MODULE__, state}, id: name)

          DynamicSupervisor.start_child(@dynamic_supervisor_name, item)
        )
      )

    result =
      case result do
        {:ok, pid} ->
          {:ok, pid}

        {:error, {:already_started, pid}} ->
          {:ok, pid}

        {:error, reason} ->
          UniError.raise_error!(
            :CODE_CAN_NOT_START_AGENT_ERROR,
            ["Error occurred while starting agent"],
            previous: reason,
            name: name
          )

        unexpected ->
          UniError.raise_error!(
            :CODE_CAN_NOT_START_AGENT_UNEXPECTED_ERROR,
            ["Unexpected error while starting agent"],
            previous: unexpected,
            name: name
          )
      end

    result
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def get_state!(name)
      when not is_atom(name),
      do:
        UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, [
          "name cannot be nil; name must be an atom"
        ])

  def get_state!(name) do
    result = UniError.rescue_error!(GenServer.call(name, :get))

    result =
      case result do
        {:error, reason} ->
          UniError.raise_error!(
            :CODE_CAN_NOT_GET_STATE_BY_KEY_AGENT_ERROR,
            ["Error occurred while getting state agent"],
            previous: reason
          )

        result ->
          result
      end

    result
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def get_state!(name, key)
      when not is_atom(name) or (not is_atom(key) and not is_bitstring(key)),
      do:
        UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, [
          "name, key cannot be nil; name must be an atom; key must a string or an atom"
        ])

  def get_state!(name, key) do
    result = UniError.rescue_error!(GenServer.call(name, {:get, key}))

    result =
      case result do
        {:error, reason} ->
          UniError.raise_error!(
            :CODE_CAN_NOT_GET_STATE_BY_KEY_AGENT_ERROR,
            ["Error occurred while getting state by key agent"],
            previous: reason
          )

        result ->
          result
      end

    result
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def set_state!(name, state)
      when not is_atom(name) or not is_map(state),
      do:
        UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, [
          "name, state cannot be nil; name must be an atom; state must a map"
        ])

  def set_state!(name, state) do
    result = UniError.rescue_error!(GenServer.call(name, {:set, state}))

    result =
      case result do
        {:ok, _} ->
          result

        {:error, reason} ->
          UniError.raise_error!(
            :CODE_CAN_NOT_SET_STATE_AGENT_ERROR,
            ["Error occurred while starting agent"],
            previous: reason,
            name: name
          )

        unexpected ->
          UniError.raise_error!(
            :CODE_CAN_NOT_SET_STATE_AGENT_UNEXPECTED_ERROR,
            ["Unexpected error while starting agent"],
            previous: unexpected,
            name: name
          )
      end

    result
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def set_state!(name, key, _value)
      when not is_atom(name) or (not is_atom(key) and not is_bitstring(key)),
      do:
        UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, [
          "name, key, state cannot be nil; name must be an atom; key must an atom or a string"
        ])

  def set_state!(name, key, value) do
    result = UniError.rescue_error!(GenServer.call(name, {:set, key, value}))

    result =
      case result do
        {:ok, _} ->
          result

        {:error, reason} ->
          UniError.raise_error!(
            :CODE_CAN_NOT_SET_STATE_BY_KEY_AGENT_ERROR,
            ["Error occurred while starting agent"],
            previous: reason,
            name: name
          )

        unexpected ->
          UniError.raise_error!(
            :CODE_CAN_NOT_SET_STATE_BY_KEY_AGENT_UNEXPECTED_ERROR,
            ["Unexpected error while starting agent"],
            previous: unexpected,
            name: name
          )
      end

    result
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def is_exists?(name)
      when not is_atom(name),
      do:
        UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, [
          "name cannot be nil; name must be an atom"
        ])

  def is_exists?(name) do
    result =
      UniError.rescue_error!(
        Agent.get(name, fn state -> state end),
        false,
        false
      )

    result =
      case result do
        %UniError{} ->
          false

        {:error, _reason} ->
          false

        _ ->
          true
      end

    result
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def string_to_atom(val)
      when not is_bitstring(val) and not is_atom(val),
      do: UniError.build_error(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["val must be an atom or string"])

  def string_to_atom(val) when is_atom(val) do
    {:ok, val}
  end

  def string_to_atom(val) when is_nil(val) do
    {:ok, nil}
  end

  def string_to_atom(val) when is_bitstring(val) do
    result =
      try do
        String.to_existing_atom(val)
      rescue
        _ -> String.to_atom(val)
      end

    {:ok, result}
  end

  ##############################################################################
  ##############################################################################
end
