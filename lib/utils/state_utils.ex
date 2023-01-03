defmodule StateUtils do
  ##############################################################################
  ##############################################################################
  @moduledoc """
  ## Module
  """

  use Utils

  ##############################################################################
  @doc """
  ## Function
  """
  def init_state!(name, state \\ %{})

  def init_state!(name, state)
      when not is_atom(name) or not is_map(state),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["name, state cannot be nil; name must be an atom; state must a map"])

  def init_state!(name, state) do
    result = UniError.rescue_error!(Agent.start_link(fn -> state end, name: name))

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
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["name cannot be nil; name must be an atom"])

  def get_state!(name) do
    result = UniError.rescue_error!(Agent.get(name, fn state -> state end))

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
  def get_state!(name, key)
      when not is_atom(name) or (not is_atom(key) and not is_bitstring(key)),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["name, key cannot be nil; name must be an atom; key must a string or an atom"])

  def get_state!(name, key) do
    result = UniError.rescue_error!(Agent.get(name, &Map.get(&1, key)))

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
  def set_state!(name, state)
      when not is_atom(name) or not is_map(state),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["name, state cannot be nil; name must be an atom; state must a map"])

  def set_state!(name, state) do
    result = UniError.rescue_error!(Agent.cast(name, fn _state -> state end))

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
  def set_state!(name, key, _value)
      when not is_atom(name) or (not is_atom(key) and not is_bitstring(key)),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["name, key, state cannot be nil; name must be an atom; key must an atom or a string"])

  def set_state!(name, key, value) do
    result = UniError.rescue_error!(Agent.cast(name, &Map.put(&1, key, value)))

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
  def is_exists?(name)
      when not is_atom(name),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["name cannot be nil; name must be an atom"])

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
  ##############################################################################
end
