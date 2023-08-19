defimpl Jason.Encoder, for: [Plug.Conn, Plug.Conn.Unfetched] do
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
    value
    |> Map.from_struct()
    |> Jason.Encode.map(options)
  end

  ####################################################################################################################
  ####################################################################################################################
end
