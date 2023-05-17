defmodule StateUtils.On.Agent do
  ##############################################################################
  ##############################################################################
  @moduledoc """
  ## Module

    children = [
      {Registry, keys: :unique, name: StateUtils.On.Agent.get_registry_name()}
  ]
  """

  use Utils

  @registry_name StateUtils.OnAgent.Registry

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
  def init_registry() do
    Registry.start_link(keys: :unique, name: @registry_name)
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def init_state(name, state \\ %{})

  def init_state(name, state)
      when is_nil(name) or not is_map(state),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["name, state cannot be nil; state must a map"])

  def init_state(name, state) do
    result = UniError.rescue_error!(Agent.start_link(fn -> state end, name: {:via, Registry, {@registry_name, name}}), {:CODE_STATE_AGENT_INIT_ERROR, ["Cannot init state on Agent"], name: name, registry_name: @registry_name})

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
  def get_state(name)
      when is_nil(name),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["name cannot be nil"])

  def get_state(name) do
    result = UniError.rescue_error!(Agent.get({:via, Registry, {@registry_name, name}}, fn state -> state end), {:CODE_STATE_AGENT_GET_ERROR, ["Cannot get state on Agent"], name: name, registry_name: @registry_name})

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

    {:ok, result}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def get_state(name, key)
      when is_nil(name) or (not is_atom(key) and not is_bitstring(key) and not is_list(key)),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["name, key cannot be nil; key must a string or an atom or an list"])

  def get_state(name, key) do
    result = UniError.rescue_error!(Agent.get({:via, Registry, {@registry_name, name}}, &Map.get(&1, key)))

    result =
      if is_list(key) do
        result = UniError.rescue_error!(Agent.get({:via, Registry, {@registry_name, name}}, &get_in(&1, key)))
      else
        result = UniError.rescue_error!(Agent.get({:via, Registry, {@registry_name, name}}, &Map.get(&1, key)))
      end

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

    {:ok, result}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def set_state(name, state)
      when is_nil(name) or not is_map(state),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["name, state cannot be nil; state must a map"])

  def set_state(name, state) do
    result = UniError.rescue_error!(Agent.cast({:via, Registry, {@registry_name, name}}, fn _state -> state end))

    result =
      case result do
        :ok ->
          :ok

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
  def set_state(name, key, _value)
      when is_nil(name) or (not is_atom(key) and not is_bitstring(key) and not is_list(key)),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["name, key, state cannot be nil; key must an atom or a string or a list"])

  def set_state(name, key, value) do
    result =
      if is_list(key) do
        UniError.rescue_error!(Agent.cast({:via, Registry, {@registry_name, name}}, &put_in(&1, key, value)))
      else
        UniError.rescue_error!(Agent.cast({:via, Registry, {@registry_name, name}}, &Map.put(&1, key, value)))
      end

    result =
      case result do
        :ok ->
          :ok

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
  def delete_state(name)
      when is_nil(name),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["name, cannot be nil"])

  def delete_state(name) do
    [{pid, _}] = Registry.lookup(@registry_name, name)

    result = UniError.rescue_error!(Agent.stop(pid, :normal, :infinity), {:CODE_STATE_AGENT_DELETE_ERROR, ["Cannot delete state on Agent"], name: name, registry_name: @registry_name})

    result =
      case result do
        :ok ->
          {:ok, :STOPPED}

        {:error, {:already_started, pid}} ->
          {:ok, pid}

        {:error, reason} ->
          UniError.raise_error!(
            :CODE_CAN_NOT_STOP_AGENT_ERROR,
            ["Error occurred while starting agent"],
            previous: reason,
            name: name
          )

        unexpected ->
          UniError.raise_error!(
            :CODE_CAN_NOT_STOP_AGENT_UNEXPECTED_ERROR,
            ["Unexpected error while starting agent"],
            previous: unexpected,
            name: name
          )
      end

    result
  end

  ##############################################################################
  ##############################################################################
end
