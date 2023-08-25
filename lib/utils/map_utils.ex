defmodule MapUtils do
  ####################################################################################################################
  ####################################################################################################################
  @moduledoc """
  Useful utils
  """
  use Utils

  @if_key_not_exists_default_value :KEY_NOT_EXISTS_RND124477854144754
  @if_no_default_value :NO_DEFAULT_VALUE_RND355845215478965

  ####################################################################################################################
  @doc """
  ## Function
  """
  def convert_to_atoms_keys_in_map(val, underscore_keys \\ false, camelize_keys \\ false)

  def convert_to_atoms_keys_in_map(val, _underscore_keys, _camelize_keys)
      when not is_map(val) and not is_list(val) and not is_struct(val),
      do: {:ok, val}

  def convert_to_atoms_keys_in_map(list, underscore_keys, camelize_keys) when is_list(list) do
    result =
      if length(list) > 0 do
        result =
          Enum.reduce(
            list,
            [],
            fn item, accum ->
              {:ok, val} = convert_to_atoms_keys_in_map(item, underscore_keys, camelize_keys)

              accum ++ [val]
            end
          )

        result
      else
        []
      end

    {:ok, result}
  end

  def convert_to_atoms_keys_in_map(struct, underscore_keys, camelize_keys)
      when is_struct(struct) do
    struct_type = struct.__struct__

    struct = Map.from_struct(struct)
    {:ok, map} = convert_to_atoms_keys_in_map(struct, underscore_keys, camelize_keys)

    struct = struct(struct_type, map)

    {:ok, struct}
  end

  def convert_to_atoms_keys_in_map(map, underscore_keys, camelize_keys) when is_map(map) do
    result =
      for {key, val} <- map, into: %{} do
        result = convert_to_atoms_keys_in_map(val, underscore_keys, camelize_keys)
        {:ok, val} = result

        key =
          if underscore_keys do
            {:ok, result} = Utils.underscore(key)

            result
          else
            if camelize_keys do
              {:ok, result} = Utils.camelize(key)

              result
            else
              key
            end
          end

        {:ok, key} = Utils.string_to_atom(key)
        result = {key, val}

        result
      end

    {:ok, result}
  end

  ####################################################################################################################
  @doc """
  ## Function
  """
  def map_to_list_of_tuples!(map, to_keyword_list \\ false, type_of_second_elem \\ :not_change)

  def map_to_list_of_tuples!(map, to_keyword_list, type_of_second_elem)
      when is_nil(map) or is_nil(type_of_second_elem) or is_nil(to_keyword_list) or
             not is_map(map) or not is_boolean(to_keyword_list) or is_nil(type_of_second_elem) or
             type_of_second_elem not in [:not_change, :atom],
      do: UniError.raise_error!(:WRONG_FUNCTION_ARGUMENT_ERROR, ["map, type_of_second_elem, to_keyword_list cannot be nil; map must be a map; to_keyword_list mast be a boolean; type_of_second_elem must be on of :not_change, :atom"])

  def map_to_list_of_tuples!(map, to_keyword_list, type_of_second_elem) do
    map =
      if to_keyword_list do
        {:ok, key} = convert_to_atoms_keys_in_map(map)
        key
      else
        map
      end

    result =
      Enum.map(map, fn {key, val} ->
        val =
          if type_of_second_elem === :not_change do
            val
          else
            {:ok, val} = Utils.string_to_type!(val, type_of_second_elem)
            val
          end

        {key, val}
      end)

    {:ok, result}
  end

  ####################################################################################################################
  @doc """
  ## Function
  """
  def convert_to_strings_keys_in_map(val, opts \\ [underscore_keys: false, camelize_keys: false, struct_to_map: false])

  def convert_to_strings_keys_in_map(val, _opts)
      when not is_map(val) and not is_list(val) and not is_struct(val),
      do: {:ok, val}

  def convert_to_strings_keys_in_map(list, opts) when is_list(list) do
    result =
      if length(list) > 0 do
        result =
          Enum.reduce(
            list,
            [],
            fn item, accum ->
              {:ok, val} = convert_to_strings_keys_in_map(item, opts)

              accum ++ [val]
            end
          )

        result
      else
        []
      end

    {:ok, result}
  end

  def convert_to_strings_keys_in_map(struct, opts)
      when is_struct(struct) do
    struct_to_map = Keyword.get(opts, :struct_to_map)

    result =
      if struct_to_map do
        {:ok, map} = convert_to_strings_keys_in_map(struct, opts)
        map
      else
        struct
      end

    {:ok, result}
  end

  def convert_to_strings_keys_in_map(map, opts) when is_map(map) do
    result =
      for {key, val} <- map, into: %{} do
        result = convert_to_strings_keys_in_map(val, opts)
        {:ok, val} = result

        underscore_keys = Keyword.get(opts, :underscore_keys)
        camelize_keys = Keyword.get(opts, :camelize_keys)

        key =
          if underscore_keys do
            {:ok, result} = Utils.underscore(key)

            result
          else
            if camelize_keys do
              {:ok, result} = Utils.camelize(key)

              result
            else
              key
            end
          end

        {:ok, key} = Utils.atom_to_string(key)
        result = {key, val}

        result
      end

    {:ok, result}
  end

  ####################################################################################################################
  @doc """
  ## Function
  """
  # FIXME: Fix this shit please
  def put_nested(data, [_ | _] = keys, value) do
    elem(get_and_update_nested(data, keys, fn _ -> {nil, value} end), 1)
  end

  def get_and_update_nested(data, [head], fun) when :erlang.is_function(head, 3) do
    head.(:get_and_update, data, fun)
  end

  def get_and_update_nested(data, [head | tail], fun) when :erlang.is_function(head, 3) do
    head.(:get_and_update, data, fn x1 -> get_and_update_nested(x1, tail, fun) end)
  end

  def get_and_update_nested(data, [head], fun) when :erlang.is_function(fun, 1) do
    get_and_update(data, head, fun)
  end

  def get_and_update_nested(data, [head | tail], fun) when :erlang.is_function(fun, 1) do
    get_and_update(data, head, fn x1 -> get_and_update_nested(x1, tail, fun) end)
  end

  def get_and_update(map, key, fun) when is_map(map) and is_atom(key) do
    get_and_update_from_map(map, key, fun)
  end

  def get_and_update(map, key, fun) when is_map(map) and is_bitstring(key) do
    get_and_update_from_map(map, key, fun)
  end

  def get_and_update_from_map(map, key, fun) when is_map(map) and :erlang.is_function(fun, 1) do
    (
      current = Map.get(map, key, @if_key_not_exists_default_value)
      case(fun.(current)) do
        {get, update} ->
          {get, Map.put(map, key, update)}
        :pop ->
          {current, Map.delete(map, key)}
        other ->
          :erlang.error(RuntimeError.exception(<<"the given function must return a two-element tuple or :pop, got: "::binary(), Kernel.inspect(other)::binary()>>), :none, error_info: %{module: Exception})
      end
      )
  end

  def get_and_update(nil, key, _fun) do
    raise(ArgumentError, <<"could not put/update key "::binary(), inspect(key)::binary(), " on a nil value"::binary()>>)
  end

  ####################################################################################################################
  @doc """
  ## Function
  """
  def get_nested(map, list, default \\ @if_no_default_value)

  def get_nested(map, list, _default)
      when is_map(map) or not is_list(list),
      do: UniError.raise_error!(:WRONG_FUNCTION_ARGUMENT_ERROR, ["map, list cannot be nil; map must be a map; list mast be a list"])

  def get_nested(value, [_ | _], _default) when not is_map(value) do
    value
  end

  def get_nested(map, [h], _default) when is_map(map) and :erlang.is_function(h) do
    h.(:get, map, fn x1 -> x1 end)
  end

  def get_nested(map, [h | t], default) when is_map(map) and :erlang.is_function(h) do
    h.(:get, map, fn x1 -> get_nested(x1, t, default) end)
  end

  def get_nested(map, [h], default) when is_map(map) and is_atom(h) do
    value = Map.get(map, h, @if_key_not_exists_default_value)

    if value == @if_key_not_exists_default_value do
      {:ok, h} = Utils.atom_to_string(h)
      value = Map.get(map, h, @if_key_not_exists_default_value)

      if value == @if_key_not_exists_default_value do
        if default === @if_no_default_value do
          UniError.raise_error!(:KEY_NOT_EXISTS_ERROR, ["Key [#{h}] not exists error}"], key: h)
        else
          default
        end
      else
        value
      end
    else
      value
    end
  end

  def get_nested(map, [h], default) when is_map(map) and is_bitstring(h) do
    value = Map.get(map, h, @if_key_not_exists_default_value)

    if value == @if_key_not_exists_default_value do
      {:ok, h} = Utils.string_to_atom(h)
      value = Map.get(map, h, @if_key_not_exists_default_value)

      if value == @if_key_not_exists_default_value do
        if default === @if_no_default_value do
          UniError.raise_error!(:KEY_NOT_EXISTS_ERROR, ["Key [#{h}] not exists error}"], key: h)
        else
          default
        end
      else
        value
      end
    else
      value
    end
  end

  def get_nested(map, [h | t], default) when is_map(map) and is_atom(h) do
    value = Map.get(map, h, @if_key_not_exists_default_value)

    value =
      if value == @if_key_not_exists_default_value do
        {:ok, h} = Utils.atom_to_string(h)
        value = Map.get(map, h, @if_key_not_exists_default_value)

        if value == @if_key_not_exists_default_value do
          if default === @if_no_default_value do
            UniError.raise_error!(:KEY_NOT_EXISTS_ERROR, ["Key [#{h}] not exists error}"], key: h)
          else
            default
          end
        else
          value
        end
      else
        value
      end

    get_nested(value, t, default)
  end

  def get_nested(map, [h | t], default) when is_map(map) and is_bitstring(h) do
    value = Map.get(map, h, @if_key_not_exists_default_value)

    value =
      if value == @if_key_not_exists_default_value do
        {:ok, h} = Utils.string_to_atom(h)
        value = Map.get(map, h, @if_key_not_exists_default_value)

        if value == @if_key_not_exists_default_value do
          if default === @if_no_default_value do
            UniError.raise_error!(:KEY_NOT_EXISTS_ERROR, ["Key [#{h}] not exists error}"], key: h)
          else
            default
          end
        else
          value
        end
      else
        value
      end

    get_nested(value, t, default)
  end

  ####################################################################################################################
  ####################################################################################################################
end
