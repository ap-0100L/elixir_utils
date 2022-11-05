defmodule StateUtils do
  ##############################################################################
  ##############################################################################
  @moduledoc """

  """

  use Utils

  ##############################################################################
  @doc """

  """
  def init_state!(name, state)
      when not is_atom(name) or not is_map(state),
      do: Macros.throw_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["name, state cannot be nil; name must be an atom; state must a map"])

  def init_state!(name, state) do
    result =
      catch_error!(
        Agent.start_link(fn -> state end, name: name),
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
      do: Macros.throw_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["name cannot be nil; name must be an atom"])

  def get_state!(name) do
    result =
      catch_error!(
        Agent.get(name, fn state -> state end),
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

    {:ok, result}
  end

  ##############################################################################
  @doc """

  """
  def get_state!(name, key)
      when not is_atom(name) or (not is_atom(key) and not is_bitstring(key)),
      do: Macros.throw_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["name, key cannot be nil; name must be an atom; key must a string or an atom"])

  def get_state!(name, key) do
    result =
      catch_error!(
        Agent.get(name, &Map.get(&1, key)),
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

    {:ok, result}
  end

  ##############################################################################
  @doc """

  """
  def set_state!(name, state)
      when not is_atom(name) or not is_map(state),
      do: Macros.throw_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["name, state cannot be nil; name must be an atom; state must a map"])

  def set_state!(name, state) do
    result =
      catch_error!(
        Agent.cast(name, fn _state -> state end),
        false
      )

    result =
      case result do
        :ok ->
          :ok

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
      do: Macros.throw_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["name, key, state cannot be nil; name must be an atom; key must an atom or a string"])

  def set_state!(name, key, value) do
    result =
      catch_error!(
        Agent.cast(name, &Map.put(&1, key, value)),
        false
      )

    result =
      case result do
        :ok ->
          :ok

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
      do: throw_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["name cannot be nil; name must be an atom"])

  def is_exists?(name) do
    result =
      catch_error!(
        Agent.get(name, fn state -> state end),
        false
      )

    result =
      case result do
        {:error, _data, _messages} ->
          false

        {:error, _reason} ->
          false

        result ->
          true
      end

    {:ok, result}
  end

  ##############################################################################
  ##############################################################################
end
