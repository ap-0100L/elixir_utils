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
        result =
          catch_error!(
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
            ),
            false
          )

        result =
          case result do
            {:ok, result} ->
              result

            {:error, _code, _data, _messages} = e ->
              throw_error!(
                :CODE_OS_ENV_ERROR,
                "Error caught while read environment variable #{var} of type #{type}",
                previous: e,
                variable: var,
                type: type
              )
          end

        result
      else
        :error ->
          case default do
            :no_default ->
              throw_error!(:CODE_SYSTEM_ENVIRONMENT_VARIABLE_NOT_FOUND_ERROR, ["Variable with name #{var} of type #{type} in system environment not found"], variable: var, type: type)

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

  def in_container!() do
    env_value = System.get_env("PROJECT_IN_CONTAINER")
    throw_if_empty!(env_value, :string, "Wrong PROJECT_IN_CONTAINER value")
    Utils.string_to_type!(env_value, :boolean)
  end

  def get_env_name!(env) when is_nil(env) or not is_bitstring(env),
    do: throw_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["env can not be nil; env must be a string"])

  def get_env_name!(env) do
    in_container = in_container!()

    if in_container do
      env
    else
      project_name = System.get_env("PROJECT_NAME")
      throw_if_empty!(project_name, :string, "Wrong PROJECT_NAME value")

      project_name <> "_" <> env
    end
  end
end
