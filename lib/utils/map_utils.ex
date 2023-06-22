defmodule MapUtils do
  ##############################################################################
  ##############################################################################
  @moduledoc """
  Useful utils
  """
  use Utils

  ##############################################################################
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

              # FIXME: It probably slow action
              :lists.append(accum, [val])

              # FIXME: It revers list
              # [val | accum]

              # accum ++ [val]
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

  ##############################################################################
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

  ##############################################################################
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

  ##############################################################################
  ##############################################################################
end
