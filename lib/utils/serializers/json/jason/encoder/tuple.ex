defimpl Jason.Encoder, for: Tuple do
  ##############################################################################
  ##############################################################################
  @moduledoc """

  """

  ##############################################################################
  @doc """

  """
  @impl Jason.Encoder
  def encode(value, options) do
    case value do
      {:error, code, data, messages} ->
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
        |> Jason.Encode.map(options)

      {:EXIT, {reason, data}} ->
        %{code: :EXIT, data: %{stacktrace: inspect(data), previous: reason}, messages: "Exit"}
        |> Jason.Encode.map(options)

      _ ->
        value
        |> Tuple.to_list()
        |> Jason.Encode.list(options)
    end
  end

  ##############################################################################
  ##############################################################################
end
