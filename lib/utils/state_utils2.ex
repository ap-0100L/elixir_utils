defmodule StateUtils2 do
  ##############################################################################
  ##############################################################################
  @moduledoc """
    children = [
      {Registry, keys: :unique, name: StateUtils.Registry},
      {DynamicSupervisor, strategy: :one_for_one, name: StateUtils.Supervisor},
  ]
  """

  use GenServer

  import Macros

  require Logger
  require Macros

  alias __MODULE__, as: SelfModule

  @registry_name StateUtils.Registry
  @supervisor_name StateUtils.Supervisor

  ##############################################################################
  @doc """

  """
  @impl true
  def init(state) do
    name = Map.fetch!(state, :name)
    Registry.register(@registry_name, name, :value)

    {:ok, state}
  end

  ##############################################################################
  @doc """

  """
  def start_link(state \\ %{}) do
    name = Map.fetch!(state, :name)

    GenServer.start_link(SelfModule, state, name: name)
  end

  ##############################################################################
  @doc """

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

  """
  def init_state!(name, state \\ %{})

  def init_state!(name, state)
      when not is_atom(name) or not is_map(state),
      do:
        throw_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, [
          "name, state cannot be nil; name must be an atom; state must a map"
        ])

  def init_state!(name, state) do
    result =
      catch_error!(
        (

          state = Map.put(state, :name, name)
          item = Supervisor.child_spec({SelfModule, state}, id: name)

          DynamicSupervisor.start_child(@supervisor_name, item)

          ),
        false
      )

    result =
      case result do
        {:ok, pid} ->
          {:ok, pid}

        {:error, {:already_started, pid}} ->
          {:ok, pid}

        {:error, _code, %{reason: reason} = _data, _messages} ->
          throw_error!(
            :CODE_CAN_NOT_START_AGENT_CAUGHT_ERROR,
            ["Error caught while starting agent"],
            reason: reason,
            name: name
          )

        {:error, reason} ->
          throw_error!(
            :CODE_CAN_NOT_START_AGENT_ERROR,
            ["Error occurred while starting agent"],
            reason: reason,
            name: name
          )

        unexpected ->
          throw_error!(
            :CODE_CAN_NOT_START_AGENT_UNEXPECTED_ERROR,
            ["Unexpected error while starting agent"],
            reason: unexpected,
            name: name
          )
      end
  end

  ##############################################################################
  @doc """

  """
  def get_state!(name)
      when not is_atom(name),
      do:
        throw_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, [
          "name cannot be nil; name must be an atom"
        ])

  def get_state!(name) do
    result =
      catch_error!(
        GenServer.call(name, :get),
        false
      )

    result =
      case result do
        {:error, _code, %{reason: reason} = _data, _messages} ->
          throw_error!(
            :CODE_CAN_NOT_GET_STATE_BY_KEY_AGENT_CAUGHT_ERROR,
            ["Error caught while getting state agent"],
            reason: reason
          )

        {:error, reason} ->
          throw_error!(
            :CODE_CAN_NOT_GET_STATE_BY_KEY_AGENT_ERROR,
            ["Error occurred while getting state agent"],
            reason: reason
          )

        result ->
          result
      end

    result
  end

  ##############################################################################
  @doc """

  """
  def get_state!(name, key)
      when not is_atom(name) or (not is_atom(key) and not is_bitstring(key)),
      do:
        throw_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, [
          "name, key cannot be nil; name must be an atom; key must a string or an atom"
        ])

  def get_state!(name, key) do
    result =
      catch_error!(
        GenServer.call(name, {:get, key}),
        false
      )

    result =
      case result do
        {:error, _code, %{reason: reason} = _data, _messages} ->
          throw_error!(
            :CODE_CAN_NOT_GET_STATE_BY_KEY_AGENT_CAUGHT_ERROR,
            ["Error caught while getting state by key agent"],
            reason: reason
          )

        {:error, reason} ->
          throw_error!(
            :CODE_CAN_NOT_GET_STATE_BY_KEY_AGENT_ERROR,
            ["Error occurred while getting state by key agent"],
            reason: reason
          )

        result ->
          result
      end

    result
  end

  ##############################################################################
  @doc """

  """
  def set_state!(name, state)
      when not is_atom(name) or not is_map(state),
      do:
        throw_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, [
          "name, state cannot be nil; name must be an atom; state must a map"
        ])

  def set_state!(name, state) do
    result =
      catch_error!(
        GenServer.call(name, {:set, state}),
        false
      )

    result =
      case result do
        {:ok, _} ->
          result

        {:error, _code, %{reason: reason} = _data, _messages} ->
          throw_error!(
            :CODE_CAN_NOT_SET_STATE_AGENT_CAUGHT_ERROR,
            ["Error caught while starting agent"],
            reason: reason,
            name: name
          )

        {:error, reason} ->
          throw_error!(
            :CODE_CAN_NOT_SET_STATE_AGENT_ERROR,
            ["Error occurred while starting agent"],
            reason: reason,
            name: name
          )

        unexpected ->
          throw_error!(
            :CODE_CAN_NOT_SET_STATE_AGENT_UNEXPECTED_ERROR,
            ["Unexpected error while starting agent"],
            reason: unexpected,
            name: name
          )
      end
  end

  ##############################################################################
  @doc """

  """
  def set_state!(name, key, value)
      when not is_atom(name) or (not is_atom(key) and not is_bitstring(key)),
      do:
        throw_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, [
          "name, key, state cannot be nil; name must be an atom; key must an atom or a string"
        ])

  def set_state!(name, key, value) do
    result =
      catch_error!(
        GenServer.call(name, {:set, key, value}),
        false
      )

    result =
      case result do
        {:ok, _} ->
          result

        {:error, _code, %{reason: reason} = _data, _messages} ->
          throw_error!(
            :CODE_CAN_NOT_SET_STATE_BY_KEY_AGENT_CAUGHT_ERROR,
            ["Error caught while starting agent"],
            reason: reason,
            name: name
          )

        {:error, reason} ->
          throw_error!(
            :CODE_CAN_NOT_SET_STATE_BY_KEY_AGENT_ERROR,
            ["Error occurred while starting agent"],
            reason: reason,
            name: name
          )

        unexpected ->
          throw_error!(
            :CODE_CAN_NOT_SET_STATE_BY_KEY_AGENT_UNEXPECTED_ERROR,
            ["Unexpected error while starting agent"],
            reason: unexpected,
            name: name
          )
      end
  end

  ##############################################################################
  @doc """

  """
  def is_exists?(name)
      when not is_atom(name),
      do:
        throw_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, [
          "name cannot be nil; name must be an atom"
        ])

  def is_exists?(name) do
    result =
      catch_error!(
        Agent.get(name, fn state -> state end),
        false,
        false
      )

    result =
      case result do
        {:error, _code, _data, _messages} ->
          false

        {:error, _reason} ->
          false

        result ->
          true
      end

    result
  end

  ##############################################################################
  @doc """

  """
  def string_to_atom(val)
      when not is_bitstring(val) and not is_atom(val),
      do: build_error_(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["val must be an atom or string"])

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
