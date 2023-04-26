defmodule ConfigUtils do
  use Utils

  @type config_type ::
          :string
          | :integer
          | :boolean
          | :json
          | :map_with_atom_keys
          | :atom
          | :list
          | :list_of_tuples
          | :keyword_list
          | :list_of_atoms
          | :keyword_list_of_atoms
          | :list_of_tuples_with_atoms
          | :regex
          | :list_of_regex

  @doc """
  Get value from environment variable, converting it to the given type if needed.

  If no default value is given, or `:no_default` is given as the default, an error is raised if the variable is not
  set.
  """
  @spec get_env!(String.t(), config_type(), :no_default | any()) :: any()
  def get_env!(var, type, default \\ :no_default)

  def get_env!(var, type, default) do
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
              UniError.raise_error!(:CODE_SYSTEM_ENVIRONMENT_VARIABLE_NOT_FOUND_ERROR, ["Variable with name #{var} of type #{type} in system environment not found"], variable: var, type: type)

            _ ->
              default
          end
      end

    log_config_env_name = get_env_name!("LOG_CONFIG")
    log_config = System.get_env(log_config_env_name, "false")

    if log_config === "true" do
      Logger.info("[#{inspect(__MODULE__)}][#{inspect(__ENV__.function)}] var: #{inspect(var)}, result: #{inspect(result)}, :no_default, type: #{inspect(type)}")
    end

    result
  end
end
