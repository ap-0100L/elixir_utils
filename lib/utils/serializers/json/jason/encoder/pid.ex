defimpl Jason.Encoder, for: PID do
  ##############################################################################
  ##############################################################################
  @moduledoc """

  """

  ##############################################################################
  @doc """

  """
  @impl Jason.Encoder
  def encode(value, options) do
    value
    |> inspect()
    |> Jason.Encoder.encode(options)
  end

  ##############################################################################
  ##############################################################################
end
