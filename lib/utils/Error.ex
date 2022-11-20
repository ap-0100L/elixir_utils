defmodule Error do
  ##############################################################################
  ##############################################################################
  @moduledoc """

  """

  defexception [:code, :data, :messages]

  ##############################################################################
  @doc """

  """
  @impl true
  def exception([code: code, data: data, messages: messages]) do
    %__MODULE__{code: code, data: data, messages: messages}
  end

  @impl true
  def exception(value) do
    %__MODULE__{code: :CODE_UNKNOWN_ERROR, data: value, messages: ["Unrnown error"]}
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
