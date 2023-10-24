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
      #        clause =
      #          quote do
      #            "claues"
      #          end
      #
      #        do_rescue =
      #          quote do
      #            "do_rescue"
      #          end
      #
      #        log_error =
      #          quote do
      #            "log_error"
      #          end
      #
      #        reraise =
      #          quote do
      #            "reraise"
      #          end
      #
      #        do_rescue =
      #          if not is_nil(do_rescue) do
      #            quote do
      #              unquote(do_rescue)
      #            end
      #          else
      #            quote do
      #              nil
      #            end
      #          end

      quote do
      end,
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
      o = unquote(o)
      type = unquote(type)
      result = Utils.is_not_empty(o, type)

      if result !== :ok do
        UniError.raise_error!(:EMPTY_VALUE_ERROR, unquote(message), previous: result, o: o, type: type)
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
      map = unquote(map)
      key = unquote(key)
      key_value_type = unquote(key_value_type)
      result = Utils.is_not_empty(map, key, key_value_type)

      if result !== :ok do
        UniError.raise_error!(:EMPTY_VALUE_ERROR, unquote(message), previous: result, key: key, key_value_type: key_value_type)
      end

      {:ok, Map.get(unquote(map), unquote(key))}
    end
  end

  ##############################################################################
  @doc """
  ## Function
  """
  defmacro get_app_env(key) do
    quote do
      application_name_atom = Application.get_application(__MODULE__)
      Macros.raise_if_empty!(application_name_atom, :atom, "Wrong application_name_atom value")
      Utils.get_app_env(application_name_atom, unquote(key))
    end
  end

  ##############################################################################
  @doc """
  ## Function
  """
  defmacro string_to_struct(
             data,
             type,
             json_converter \\ Jason,
             underscore_keys \\ false,
             camelize_keys \\ false
           )

  defmacro string_to_struct(data, type, json_converter, underscore_keys, camelize_keys) do
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
  defmacro convert_fields_in_map(map, fields_list, func) do
    quote do
      map = unquote(map)
      fields_list = unquote(fields_list)
      func = unquote(func)

      Enum.reduce(
        fields_list,
        map,
        fn field, accum ->
          value = Map.get(accum, field)

          value = func.(value)

          Map.put(accum, field, value)
        end
      )
    end
  end

  ##############################################################################
  ##############################################################################
end
