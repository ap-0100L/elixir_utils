defmodule Macros do
  ##############################################################################
  ##############################################################################
  @moduledoc """

  # Macros

  """

  require UniError

  alias Utils, as: Utils
  alias UniError, as: UniError

  def expand_macro() do
    Macro.expand(
      (
        clause =
          quote do
            "claues"
          end

        do_rescue =
          quote do
            "do_rescue"
          end

        log_error =
          quote do
            "log_error"
          end

        reraise =
          quote do
            "reraise"
          end

        do_rescue =
          if not is_nil(do_rescue) do
            quote do
              unquote(do_rescue)
            end
          else
            quote do
              nil
            end
          end

        quote do
        end
      ),
      __ENV__
    )
    |> Macro.to_string()
  end

  ##############################################################################
  @doc """
  ## Function
  """
  defmacro count_time(clause) do
    quote do
      start_time = System.monotonic_time(:nanosecond)

      result = unquote(clause)

      end_time = System.monotonic_time(:nanosecond)

      {:ok, {result, end_time - start_time}}
    end
  end

  ##############################################################################
  @doc """
  ## Function
  """
  defmacro is_datetime(o) do
    quote do
      not is_nil(unquote(o)) and is_struct(unquote(o)) and unquote(o).__struct__ === DateTime
    end
  end

  ##############################################################################
  @doc """
  ## Function
  """
  defmacro is_struct_of_type(o, type) do
    quote do
      not is_nil(unquote(o)) and is_struct(unquote(o)) and unquote(o).__struct__ === unquote(type)
    end
  end

  ##############################################################################
  @doc """
  ## Function
  """
  defmacro is_enumerable(o) do
    quote do
      not is_nil(unquote(o)) and (is_list(unquote(o)) or is_map(unquote(o)))
    end
  end

  ##############################################################################
  @doc """
  ## Function
  """
  defmacro raise_if_empty!(o, type, message) do
    quote do
      result = Utils.is_not_empty(unquote(o), unquote(type))

      if result !== :ok do
        UniError.raise_error!(UniError.build_uni_error_(:CODE_EMPTY_VALUE_ERROR, unquote(message), previous: result))
      end

      :ok
    end
  end

  ##############################################################################
  @doc """
  ## Function
  """
  defmacro raise_if_empty!(map, key, key_value_type, message) do
    quote do
      result = Utils.is_not_empty(unquote(map), unquote(key), unquote(key_value_type))

      if result !== :ok do
        UniError.raise_error!(UniError.build_uni_error_(:CODE_EMPTY_VALUE_ERROR, unquote(message), previous: result))
      end

      {:ok, Map.get(unquote(map), unquote(key))}
    end
  end

  ##############################################################################
  @doc """
  ## Function
  """
  defmacro get_app_env!(key) do
    quote do
      application_name_atom = Application.get_application(__MODULE__)
      Macros.raise_if_empty!(application_name_atom, :atom, "Wrong application_name_atom value")
      Utils.get_app_env!(application_name_atom, unquote(key))
    end
  end

  ##############################################################################
  @doc """
  ## Function
  """
  defmacro get_app_env_(key) do
    quote do
      application_name_atom = Application.get_application(__MODULE__)
      Macros.raise_if_empty!(application_name_atom, :atom, "Wrong application_name_atom value")
      {:ok, value} = Utils.get_app_env!(application_name_atom, unquote(key))

      value
    end
  end

  ##############################################################################
  @doc """
  ## Function
  """
  defmacro string_to_struct!(
             data,
             type,
             json_converter \\ Jason,
             underscore_keys \\ false,
             camelize_keys \\ false
           )

  defmacro string_to_struct!(data, type, json_converter, underscore_keys, camelize_keys) do
    quote do
      data_map = unquote(json_converter).decode!(unquote(data))
      {:ok, data_map} = Utils.convert_to_atoms_keys_in_map(data_map, unquote(underscore_keys), unquote(camelize_keys))
      data_struct = struct(unquote(type), data_map)

      {:ok, data_struct}
    end
  end

  ##############################################################################
  @doc """
  ## Function
  """
  defmacro string_clause_to_code!(clause) do
    result = [Code.string_to_quoted!(clause)]

    result =
      quote do
        (unquote_splicing(result))
      end

    {:ok, result}
  end

  ##############################################################################
  ##############################################################################
end
