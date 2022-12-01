defmodule UniError do
  ##############################################################################
  ##############################################################################
  @moduledoc """

  """

  use Utils

  defexception [:code, :messages, :data]

  ##############################################################################
  @doc """

  """
  @impl true
  def exception(code: code, data: data, messages: messages) do
    build_uni_error_(code, messages, data)
  end

  @impl true
  def exception({:error, code, data, messages} = _exception) do
    build_uni_error_(code, messages, data)
  end

  @impl true
  def exception({%error_type{} = exception, messages, stacktrace}) do
    case error_type do
      UniError ->
        exception
        %{exception | stacktrace: stacktrace}

      error_code ->
        error_code = String.upcase("#{error_code}")
        error_code = ":CODE_#{error_code}"
        {:ok, error_code} = Utils.string_to_atom(error_code)
        build_uni_error_(error_code, [exception.message] ++ messages, previous: exception, stacktrace: stacktrace)

        #      _ ->
        #        build_uni_error_(:CODE_UNEXPECTED_ERROR, ["Unexpected error"] ++ messages, previous: exception, stacktrace: stacktrace)
    end
  end

  @impl true
  def exception(exception) do
    build_uni_error_(:CODE_UNEXPECTED_NOT_STRUCTURED_ERROR, ["Unexpected not structured error"], previous: exception)
  end

  ##############################################################################
  @doc """

  """
  @impl true
  def message(%__MODULE__{code: _code, data: _data, messages: messages}) do
    inspect(messages)
  end

  ##############################################################################
  ##############################################################################
end
