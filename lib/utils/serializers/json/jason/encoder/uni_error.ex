defimpl Jason.Encoder,
  for: [UniError] do
  ##############################################################################
  ##############################################################################
  @moduledoc """
  ## Module
  """

  ##############################################################################
  @doc """
  # Function
  """
  @impl Jason.Encoder
  def encode(%struct{code: code, data: data, messages: messages} = value, options) do

    stacktrace = Map.get(data, :stacktrace, nil)
    stack_from_data = Map.get(data, :stack, nil)

    stacktrace = stacktrace || stack_from_data

    data =
      if is_nil(stacktrace) or is_bitstring(stacktrace) do
        data
      else
        %{data | stacktrace: inspect(stacktrace)}
      end


    %{code: code, data: data, messages: messages}
    |> Map.put(:__struct__, struct)
    |> Jason.Encode.map(options)
  end

  ##############################################################################
  ##############################################################################
end
