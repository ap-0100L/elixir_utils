defmodule SypervisorUtils do
  ####################################################################################################################
  ####################################################################################################################
  @moduledoc """
  ## Module
  """

  use Utils


  ####################################################################################################################
  @doc """
  ## Function
  """
  def start(child_spec, opts \\ [])

  def start(child_spec, opts) do
    result = UniError.rescue_error!(Supervisor.start_link(child_spec, opts))

    result =
      case result do
        {:ok, pid} ->
          {:ok, pid}

        {:error, {:already_started, pid}} ->
          {:ok, pid}

        {:error, reason} ->
          UniError.raise_error!(
            :CAN_NOT_START_SUPERVISOR_ERROR,
            ["Error occurred while starting"],
            previous: reason,
            child_spec: child_spec,
            opts: opts
          )

        unexpected ->
          UniError.raise_error!(
            :CAN_NOT_START_SUPERVISOR_UNEXPECTED_ERROR,
            ["Unexpected error while starting"],
            previous: unexpected,
            child_spec: child_spec,
            opts: opts
          )
      end

    result
  end

  ####################################################################################################################
  @doc """
  ## Function
  """
  def stop(name, reason \\ :normal, timeout \\ :infinity)

  def stop(name, reason, timeout)
      when not is_atom(name) or not is_atom(reason) or (not is_atom(timeout) and not is_number(timeout)),
      do:
        UniError.raise_error!(
          :WRONG_FUNCTION_ARGUMENT_ERROR,
          ["name, reason, timeout cannot be nil; name, reason must be an atom; timeout must be an atom or number"]
        )

  def stop(name, reason, timeout) do
    result = UniError.rescue_error!(Supervisor.stop(name, reason, timeout))

    result =
      case result do
        :ok ->
          {:ok, :STOPPED}

        unexpected ->
          UniError.raise_error!(
            :CAN_NOT_STOP_SUPERVISOR_UNEXPECTED_ERROR,
            ["Unexpected error while stopping"],
            previous: unexpected
          )
      end

    result
  end

  ####################################################################################################################
  ####################################################################################################################
end
