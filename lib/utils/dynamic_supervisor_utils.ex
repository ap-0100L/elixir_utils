defmodule DynamicSupervisorUtils do
  ##################################################################################################################
  ##################################################################################################################
  @moduledoc """
  ## Module
  """

  use Utils

  ##################################################################################################################
  @doc """
  ## Function
  """
  def start_child(dynamic_supervisor_name, child_spec)
      when not is_atom(dynamic_supervisor_name),
      do:
        UniError.raise_error!(
          :WRONG_FUNCTION_ARGUMENT_ERROR,
          ["dynamic_supervisor_name cannot be nil; dynamic_supervisor_name must be an atom"]
        )

  def start_child(dynamic_supervisor_name, child_spec) do
    result = UniError.rescue_error!(DynamicSupervisor.start_child(dynamic_supervisor_name, child_spec))

    result =
      case result do
        {:ok, pid} ->
          {:ok, pid}

        {:error, {:already_started, pid}} ->
          {:ok, pid}

        {:error, reason} ->
          UniError.raise_error!(
            :CAN_NOT_START_DYNAMIC_SUPERVISOR_CHILD_ERROR,
            ["Error occurred while starting"],
            previous: reason,
            dynamic_supervisor_name: dynamic_supervisor_name,
            child_spec: child_spec
          )

        unexpected ->
          UniError.raise_error!(
            :CAN_NOT_START_DYNAMIC_SUPERVISOR_CHILD_UNEXPECTED_ERROR,
            ["Unexpected error while starting"],
            previous: unexpected,
            dynamic_supervisor_name: dynamic_supervisor_name,
            child_spec: child_spec
          )
      end

    result
  end


  ##################################################################################################################
  ##################################################################################################################
end
