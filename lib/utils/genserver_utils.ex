defmodule GenServerUtils do
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
  def stop(pid, reason \\ :normal, timeout \\ :infinity)

  def stop(pid, reason, timeout)
      when is_nil(pid) or not is_atom(reason) or (not is_atom(timeout) and not is_number(timeout)),
      do:
        UniError.raise_error!(
          :WRONG_FUNCTION_ARGUMENT_ERROR,
          ["reason, timeout cannot be nil; reason must be an atom; timeout must be an atom or number"]
        )

  def stop(pid, reason, timeout) do
    result = UniError.rescue_error!(GenServer.stop(pid, reason, timeout))

    result =
      case result do
        :ok ->
          {:ok, :STOPPED}

        unexpected ->
          UniError.raise_error!(
            :CAN_NOT_STOP_GENSERVER_UNEXPECTED_ERROR,
            ["Unexpected error while stopping"],
            previous: unexpected,
            pid: pid,
            timeout: timeout,
            reason: reason
          )
      end

    result
  end

  ##############################################################################
  ##############################################################################
end
