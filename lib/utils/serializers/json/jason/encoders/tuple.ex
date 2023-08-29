defimpl Jason.Encoder, for: Tuple do
  ####################################################################################################################
  ####################################################################################################################
  @moduledoc """
  ## Module
  """

  ####################################################################################################################
  @doc """
  ## Function
  """
  @impl Jason.Encoder
  def encode(value, options) do
    case value do
      {:error, code, messages, data} ->
        stacktrace = Map.get(data, :stacktrace, nil)
        stack_from_data = Map.get(data, :stack, nil)

        stacktrace = stacktrace || stack_from_data

        data =
          if is_nil(stacktrace) or is_bitstring(stacktrace) do
            data
          else
            %{data | stacktrace: inspect(stacktrace)}
          end

        %{code: code, messages: messages, data: data}
        |> Jason.Encode.map(options)

      {:EXIT, {reason, stacktrace}} ->
        stacktrace = inspect(stacktrace)
        %{code: :EXIT, messages: ["Exit", "STACKTRACE: [#{stacktrace}]"], data: %{stacktrace: stacktrace, previous: reason}}
        |> Jason.Encode.map(options)

      _ ->
        value
        |> Tuple.to_list()
        |> Jason.Encode.list(options)
    end
  end

  ####################################################################################################################
  ####################################################################################################################
end
