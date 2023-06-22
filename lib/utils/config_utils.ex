defmodule ConfigUtils do
  use Utils

  ##############################################################################
  @doc """
  ## Function
  """
  def get_env(var, type, default \\ :no_default)

  def get_env(var, type, default) do
    result =
      with {:ok, val} <- System.fetch_env(var) do
        {:ok, result} =
          UniError.rescue_error!(
            (
              result =
                if val == "all" do
                  {:ok, val} = Utils.string_to_atom(val)

                  val
                else
                  {:ok, result} = Utils.string_to_type!(val, type)

                  result
                end

              {:ok, result}
            )
          )

        result
      else
        :error ->
          case default do
            :no_default ->
              UniError.raise_error!(:SYSTEM_ENVIRONMENT_VARIABLE_NOT_FOUND_ERROR, ["Variable with name #{var} of type #{type} in system environment not found"], variable: var, type: type)

            _ ->
              default
          end
      end

    result
  end
end
