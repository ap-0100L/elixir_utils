defmodule Utils do
  ##############################################################################
  ##############################################################################
  @moduledoc """
  Useful utils
  """

  require Kernel
  require Macros
  require Logger
  require Integer
  require UniError

  @application_name :api_core
  @valid_id_start_at -1
  @string_separator ";"
  @json_converter Jason

  @format_string_wildcard_pattern "{#}"

  @primitive_types [:string, :binary, :integer, :integer_id, :map, :atom, :boolean, :list, :uuid_string]

  @boolean_true ["true", "yes", "in", "on", "1"]

  @crypto_alg [:sha256]

  @types [
    :string,
    :integer,
    :boolean,
    :json,
    :map_with_atom_keys,
    :atom,
    :list,
    :list_of_tuples,
    :keyword_list,
    :list_of_atoms,
    :keyword_list_of_atoms,
    :list_of_tuples_with_atoms,
    :regex,
    :list_of_regex,
    :uuid_string
  ]

  ##############################################################################
  @doc """
  ## Function
  """
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      import Macros

      require Kernel
      require Macros
      require Logger
      require UniError
      require CodeUtils

      alias Utils, as: Utils
      alias EtsUtils, as: EtsUtils
      alias UniError, as: UniError
      alias CodeUtils, as: CodeUtils
    end
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def get_if_addrs!() do
    result = :inet.getifaddrs()

    ifaddr =
      case result do
        {:ok, ifaddr} ->
          ifaddr

        {:error, reason} ->
          UniError.raise_error!(:CODE_CAN_NOT_GET_IF_ADDRS_ERROR, ["Cannot get If address"], previous: reason)

        unexpected ->
          UniError.raise_error!(:CODE_CAN_NOT_GET_IF_ADDRS_UNEXPECTED_ERROR, ["Cannot get If address"], previous: unexpected)
      end

    result =
      Enum.reduce(
        ifaddr,
        [],
        fn item, accum ->
          if_name = elem(item, 0)
          opts = elem(item, 1)

          obj = %{
            if_name: "#{if_name}",
            flags: opts[:flags],
            addr: inspect(opts[:addr]),
            netmask: inspect(opts[:netmask]),
            broadaddr: inspect(opts[:broadaddr]),
            hwaddr: inspect(opts[:hwaddr])
          }

          # FIXME: It revers list
          [obj | accum]
        end
      )

    {:ok, result}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def get_now_datetime_with_TZ!(timezone \\ nil)

  def get_now_datetime_with_TZ!(timezone) do
    result = is_not_empty(timezone, :string)

    timezone =
      if result == :ok do
        timezone
      else
        {:ok, timezone} = get_app_env(:time_zone)

        timezone
      end

    #    result = Timex.now(timezone)
    #    {:ok, result}

    result = DateTime.now(timezone)

    result =
      case result do
        {:ok, datetime} ->
          {:ok, datetime}

        {:error, reason} ->
          UniError.raise_error!(:CODE_GET_DATE_WITH_TZ_ERROR, ["Can not get datetime with TZ"], previous: reason, timezone: timezone)

        unexpected ->
          UniError.raise_error!(:CODE_GET_DATE_WITH_TZ_UNEXPECTED_ERROR, ["Can not get datetime with TZ"], previous: unexpected, timezone: timezone)
      end

    result
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def get_now_datetime_with_TZ_to_iso8601!(timezone \\ nil)

  def get_now_datetime_with_TZ_to_iso8601!(timezone) do
    {:ok, date_time} = get_now_datetime_with_TZ!(timezone)

    {:ok, DateTime.to_iso8601(date_time)}
  end

  ##############################################################################
  @doc """
   as string
  """
  def get_now_datetime_with_TZ_as_string!(format \\ nil) do
    format =
      if is_nil(format) do
        {:ok, date_time_with_tz_format} = get_app_env(:date_time_with_tz_format)

        date_time_with_tz_format
      else
        format
      end

    {:ok, datetime} = get_now_datetime_with_TZ!()
    ret = Calendar.strftime(datetime, format)
    #    ret = DateTime.to_string(datetime)
    {:ok, ret}
  end

  ##############################################################################
  @doc """
  Is valid key value for different types in map
  """
  def is_not_empty(_map, key, keyValueType)
      when is_nil(key) or is_nil(keyValueType),
      do: UniError.build_uni_error(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["key, keyValueType cannot be nil"])

  def is_not_empty(nil, _key, _keyValueType),
    do: UniError.build_error(:CODE_MAP_IS_NIL_ERROR, ["map cannot be nil"])

  def is_not_empty(map, key, keyValueType) do
    result =
      if Map.has_key?(map, key) do
        result = is_not_empty(Map.get(map, key), keyValueType)

        result =
          case result do
            :ok ->
              :ok

            {:error, _code, _data, _messages} = e ->
              UniError.build_error(:CODE_WRONG_VALUE_IN_MAP_ERROR, ["Required key: '#{key}'"], previous: e, key: key, type: keyValueType)
          end

        result
      else
        UniError.build_error(:CODE_NO_KEY_IN_MAP_ERROR, ["No key '#{key}' in map"], key: key, type: keyValueType)
      end

    result
  end

  ##############################################################################
  @doc """
  Is empty value for different types
  """
  def is_not_empty(_, type) when is_nil(type) or not is_atom(type) or type not in @primitive_types,
    do: UniError.build_error(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["type cannot be nil; type must be an atom; type must be one of #{@primitive_types}"])

  def is_not_empty(o, _) when is_nil(o),
    do: UniError.build_error(:CODE_VALUE_IS_NIL_ERROR, ["is nil"])

  def is_not_empty(o, :string) do
    result =
      if is_bitstring(o) do
        if String.length(o) == 0 do
          UniError.build_error(:CODE_EMPTY_VALUE_ERROR, ["string is empty"])
        else
          :ok
        end
      else
        UniError.build_error(:CODE_WRONG_VALUE_TYPE_ERROR, ["is not string"])
      end

    result
  end

  def is_not_empty(o, :uuid_string) do
    result =
      if is_bitstring(o) do
        if String.length(o) == 0 do
          UniError.build_error(:CODE_EMPTY_VALUE_ERROR, ["uuid_string is empty"])
        else
          if String.match?(o, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/) do
            :ok
          else
            UniError.build_error(:CODE_WRONG_VALUE_FORMAT_ERROR, ["is not uuid_string format"])
          end
        end
      else
        UniError.build_error(:CODE_WRONG_VALUE_TYPE_ERROR, ["is not uuid_string"])
      end

    result
  end

  def is_not_empty(o, :binary) do
    result =
      if is_binary(o) do
        if byte_size(o) == 0 do
          UniError.build_error(:CODE_EMPTY_VALUE_ERROR, ["bytes is empty"])
        else
          :ok
        end
      else
        UniError.build_error(:CODE_WRONG_VALUE_TYPE_ERROR, ["is not binary"])
      end

    result
  end

  def is_not_empty(o, :integer) do
    result =
      if is_integer(o) do
        :ok
      else
        UniError.build_error(:CODE_WRONG_VALUE_TYPE_ERROR, ["is not integer"])
      end

    result
  end

  def is_not_empty(o, :atom) when not is_nil(o) do
    result =
      if is_atom(o) do
        :ok
      else
        UniError.build_error(:CODE_WRONG_VALUE_TYPE_ERROR, ["is not atom"])
      end

    result
  end

  def is_not_empty(o, :boolean) do
    result =
      if is_boolean(o) do
        :ok
      else
        UniError.build_error(:CODE_WRONG_VALUE_TYPE_ERROR, ["is not boolean"])
      end

    result
  end

  def is_not_empty(o, :integer_id) do
    result =
      if is_integer(o) do
        if o >= @valid_id_start_at do
          :ok
        else
          UniError.build_error(:CODE_WRONG_INTEGER_ID_VALUE_ERROR, ["value with type integer_id must be >= #{@valid_id_start_at}"])
        end
      else
        UniError.build_error(:CODE_WRONG_VALUE_TYPE_ERROR, ["is not integer_id"])
      end

    result
  end

  def is_not_empty(o, :map) do
    result =
      if is_map(o) do
        if map_size(o) > 0 do
          :ok
        else
          UniError.build_error(:CODE_EMPTY_VALUE_ERROR, ["map is empty"])
        end
      else
        UniError.build_error(:CODE_WRONG_VALUE_TYPE_ERROR, ["is not map"])
      end

    result
  end

  def is_not_empty(o, :list) do
    result =
      if is_list(o) do
        if length(o) > 0 do
          :ok
        else
          UniError.build_error(:CODE_EMPTY_VALUE_ERROR, ["list is empty"])
        end
      else
        UniError.build_error(:CODE_WRONG_VALUE_TYPE_ERROR, ["is not list"])
      end

    result
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def get_app_all_env!() do
    get_app_all_env!(@application_name)
  end

  def get_app_all_env!(application_name) do
    Macros.raise_if_empty!(application_name, :atom, "Wrong application_name value")

    result = Application.get_all_env(application_name)

    result =
      case result do
        nil ->
          UniError.raise_error!(:CODE_CONFIG_KEY_IS_NIL_ERROR, ["Module is not listed in any application spec"], application_name: application_name)

        :undefined ->
          UniError.raise_error!(:CODE_CONFIG_KEY_UNDEFINED_ERROR, ["Key is undefined"], application_name: application_name, reason: :undefined)

        result ->
          result
      end

    {:ok, result}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def get_app_env(key) do
    get_app_env(@application_name, key)
  end

  def get_app_env(application_name, key) do
    Macros.raise_if_empty!(application_name, :atom, "Wrong application_name value")
    Macros.raise_if_empty!(key, :atom, "Wrong key value")

    result = Application.get_env(application_name, key)

    result =
      case result do
        nil ->
          UniError.raise_error!(:CODE_CONFIG_KEY_IS_NIL_ERROR, ["Module is not listed in any application spec"], application_name: application_name, key: key)

        :undefined ->
          UniError.raise_error!(:CODE_CONFIG_KEY_UNDEFINED_ERROR, ["Key is undefined"], application_name: application_name, reason: :undefined)

        result ->
          result
      end

    {:ok, result}
  end

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
            {:ok, result} = underscore(key)

            result
          else
            if camelize_keys do
              {:ok, result} = camelize(key)

              result
            else
              key
            end
          end

        {:ok, key} = string_to_atom(key)
        result = {key, val}

        result
      end

    {:ok, result}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def list_of_strings_to_list_of!(list, type \\ :atom)

  def list_of_strings_to_list_of!(list, type) when is_nil(list) or is_nil(type) or not is_list(list) or not is_atom(type) or type not in @types,
    do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["list, type cannot be nil; list must be a list; type must be an atom; type must be one of #{inspect(@types)}"], type: type, types: @types)

  def list_of_strings_to_list_of!(list, type) do
    result =
      if length(list) > 0 do
        result =
          Enum.reduce(
            list,
            [],
            fn item, accum ->
              {:ok, result} = string_to_type!(item, type)

              # FIXME: It probably slow action
              :lists.append(accum, [result])

              # FIXME: It revers list
              # [result | accum]
            end
          )

        result
      else
        []
      end

    {:ok, result}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def string_to_atom(val) when not is_bitstring(val) and not is_atom(val),
    do: UniError.build_error(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["val must be an atom or string"])

  def string_to_atom(val) when is_atom(val) do
    {:ok, val}
  end

  def string_to_atom(val) when is_nil(val) do
    {:ok, nil}
  end

  def string_to_atom(val) when is_bitstring(val) do
    result =
      try do
        String.to_existing_atom(val)
      rescue
        _ -> String.to_atom(val)
      end

    {:ok, result}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def atom_to_string(val) when not is_bitstring(val) and not is_atom(val),
    do: UniError.build_error(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["val must be an atom or string"])

  def atom_to_string(val) when is_bitstring(val) do
    {:ok, val}
  end

  def atom_to_string(val) when is_nil(val) do
    {:ok, nil}
  end

  def atom_to_string(val) when is_atom(val) do
    result = Atom.to_string(val)

    {:ok, result}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def underscore(val) when is_nil(val) or (not is_bitstring(val) and not is_atom(val)),
    do: UniError.build_error(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["val cannot be nil and must be an atom or string"])

  def underscore(val) when is_atom(val) do
    val = Atom.to_string(val)
    val = Macro.underscore(val)
    {:ok, result} = string_to_atom(val)
    {:ok, result}
  end

  def underscore(val) when is_bitstring(val) do
    result = Macro.underscore(val)

    {:ok, result}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def camelize(val) when is_nil(val) or (not is_bitstring(val) and not is_atom(val)),
    do: UniError.build_error(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["val cannot be nil and must be an atom or string"])

  def camelize(val) when is_atom(val) do
    #    val = Atom.to_string(val)
    #    val = Macro.camelize(val)
    val = Inflex.camelize(val, :lower)
    {:ok, result} = string_to_atom(val)
    {:ok, result}
  end

  def camelize(val) when is_bitstring(val) do
    #    result = Macro.camelize(val)
    result = Inflex.camelize(val, :lower)

    {:ok, result}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def ensure_all_started!(apps) when is_nil(apps) or not is_list(apps),
    do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["apps cannot be nil; apps must be a list"])

  def ensure_all_started!(apps) do
    Macros.raise_if_empty!(apps, :list, "Wrong apps value")

    Enum.each(
      apps,
      fn app ->
        result = Application.ensure_all_started(app)

        result =
          case result do
            {:ok, obj} ->
              {:ok, obj}

            {:error, reason} ->
              UniError.raise_error!(:CODE_ENSURE_APPLICATION_STARTED_ERROR, ["Not all necessary applications were started"],
                app: app,
                previous: reason
              )

            unexpected ->
              UniError.raise_error!(:CODE_ENSURE_APPLICATION_STARTED_ERROR, ["Not all necessary applications were started"],
                app: app,
                previous: unexpected
              )
          end

        result
      end
    )

    :ok
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def enum_each!(enum, function, args \\ nil)

  def enum_each!(enum, function, args)
      when is_nil(enum) or is_nil(function) or not Macros.is_enumerable(enum) or
             (not is_nil(args) and not is_list(args)),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["enum, function cannot be nil; enum must be an enumerable; args must be a list"])

  def enum_each!(enum, function, args) do
    Enum.each(
      enum,
      fn item ->
        if is_nil(args) do
          function.(item)
        else
          function.(item, args)
        end
      end
    )

    :ok
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def enum_reduce_to_list!(enum, function \\ nil, args \\ nil)

  def enum_reduce_to_list!(enum, function, args)
      when is_nil(enum) or not Macros.is_enumerable(enum) or
             (not is_nil(function) and (not is_nil(args) and not is_list(args))),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["enum, function cannot be nil; enum must be an enumerable; args must be a list"])

  def enum_reduce_to_list!(enum, function, args) do
    result =
      Enum.reduce(
        enum,
        [],
        fn item, accum ->
          {:ok, result} =
            if not is_nil(function) do
              if is_nil(args) do
                function.(item)
              else
                function.(item, args)
              end
            else
              {:ok, item}
            end

          if is_list(result) do
            # FIXME: It probably slow action
            :lists.append(accum, result)

            # FIXME: It revers enum
            # result ++ accum
          else
            # FIXME: It probably slow action
            :lists.append(accum, [result])

            # FIXME: It revers enum
            # [result] ++ accum
          end
        end
      )

    {:ok, result}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def encode64!(str) when not is_bitstring(str),
    do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["str must be a string"])

  def encode64!(str) do
    result = Base.url_encode64(str)

    {:ok, result}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def decode64!(str) when not is_bitstring(str),
    do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["str must be a string"])

  def decode64!(str) do
    result = Base.url_decode64!(str)

    {:ok, result}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def string_to_type!(var, type \\ :string)

  def string_to_type!(var, type)
      when is_nil(var) or is_nil(type) or not is_atom(type) or not is_bitstring(var),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["var and type cannot be nil; var must be a string; type must be an atom"])

  def string_to_type!(_var, type)
      when type not in @types,
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["type must be one of #{inspect(@types)}"], type: type, types: @types)

  def string_to_type!(var, :string), do: {:ok, var}

  def string_to_type!(var, :integer) do
    Macros.raise_if_empty!(var, :string, "Wrong var value")

    result = String.to_integer(var)
    {:ok, result}
  end

  def string_to_type!(var, :atom) do
    Macros.raise_if_empty!(var, :string, "Wrong var value")

    {:ok, result} = Utils.string_to_atom(var)

    {:ok, result}
  end

  def string_to_type!(var, :list) do
    Macros.raise_if_empty!(var, :string, "Wrong var value")

    result = String.split(var, @string_separator, trim: true)

    {:ok, result}
  end

  def string_to_type!(var, :list_of_tuples) do
    Macros.raise_if_empty!(var, :string, "Wrong var value")

    # {:ok, var} = @json_converter.decode!(var)
    var = @json_converter.decode!(var)
    Macros.raise_if_empty!(var, :map, "Wrong var value")

    {:ok, result} = Utils.map_to_list_of_tuples!(var, false)

    {:ok, result}
  end

  def string_to_type!(var, :list_of_tuples_with_atoms) do
    Macros.raise_if_empty!(var, :string, "Wrong var value")

    # {:ok, var} = @json_converter.decode!(var)
    var = @json_converter.decode!(var)
    Macros.raise_if_empty!(var, :map, "Wrong var value")

    {:ok, result} = Utils.map_to_list_of_tuples!(var, false, :atom)

    {:ok, result}
  end

  def string_to_type!(var, :keyword_list) do
    Macros.raise_if_empty!(var, :string, "Wrong var value")

    # {:ok, var} = @json_converter.decode!(var)
    var = @json_converter.decode!(var)
    Macros.raise_if_empty!(var, :map, "Wrong var value")

    {:ok, result} = Utils.map_to_list_of_tuples!(var, true)

    {:ok, result}
  end

  def string_to_type!(var, :keyword_list_of_atoms) do
    Macros.raise_if_empty!(var, :string, "Wrong var value")

    # {:ok, var} = @json_converter.decode!(var)
    var = @json_converter.decode!(var)
    Macros.raise_if_empty!(var, :map, "Wrong var value")

    {:ok, result} = Utils.map_to_list_of_tuples!(var, true, :atom)

    {:ok, result}
  end

  def string_to_type!(var, :list_of_atoms) do
    Macros.raise_if_empty!(var, :string, "Wrong var value")

    {:ok, list} = string_to_type!(var, :list)

    {:ok, result} = Utils.list_of_strings_to_list_of!(list)

    {:ok, result}
  end

  def string_to_type!(var, :boolean) when not is_nil(var) do
    var = String.downcase(var) in @boolean_true

    {:ok, var}
  end

  def string_to_type!(var, :json) do
    Macros.raise_if_empty!(var, :string, "Wrong var value")

    var = @json_converter.decode!(var)

    {:ok, var}
  end

  def string_to_type!(var, :regex) do
    Macros.raise_if_empty!(var, :string, "Wrong var value")

    CodeUtils.string_to_code!(var)
  end

  def string_to_type!(var, :list_of_regex) do
    Macros.raise_if_empty!(var, :string, "Wrong var value")

    {:ok, list} = string_to_type!(var, :list)

    list_of_strings_to_list_of!(list, :regex)
  end

  def string_to_type!(var, :map_with_atom_keys) do
    Macros.raise_if_empty!(var, :string, "Wrong var value")

    # {:ok, var} = @json_converter.decode!(var)
    var = @json_converter.decode!(var)
    Macros.raise_if_empty!(var, :map, "Wrong var value")

    {:ok, result} = convert_to_atoms_keys_in_map(var)

    {:ok, result}
  end

  def string_to_type!(_var, type),
    do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["Wrong type: #{inspect(type)}"], type: type, types: @types)

  ##############################################################################
  @doc """
  ## Function
  """
  def map_to_list_of_tuples!(map, to_keyword_list \\ false, type_of_second_elem \\ :not_change)

  def map_to_list_of_tuples!(map, to_keyword_list, type_of_second_elem)
      when is_nil(map) or is_nil(type_of_second_elem) or is_nil(to_keyword_list) or
             not is_map(map) or not is_boolean(to_keyword_list) or is_nil(type_of_second_elem) or
             type_of_second_elem not in [:not_change, :atom],
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["map, type_of_second_elem, to_keyword_list cannot be nil; map must be a map; to_keyword_list mast be a boolean; type_of_second_elem must be on of :not_change, :atom"])

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
            {:ok, val} = string_to_type!(val, type_of_second_elem)
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
  def get_nodes_list_by_prefixes(node_name_prefixes, nodes)
      when is_nil(node_name_prefixes) or is_nil(nodes) or
             not is_list(node_name_prefixes) or not is_list(nodes),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["node_name_prefixes, nodes cannot be nil; node_name_prefixes must be a string; nodes must be a list"])

  def get_nodes_list_by_prefixes(node_name_prefixes, nodes) do
    result =
      Utils.enum_reduce_to_list!(
        node_name_prefixes,
        fn prefix, nodes ->
          Utils.enum_reduce_to_list!(
            nodes,
            fn item, [prefix] ->
              item_str = "#{item}"

              result = String.match?(item_str, prefix)

              if result do
                {:ok, [item]}
              else
                {:ok, []}
              end
            end,
            [prefix]
          )
        end,
        nodes
      )

    result
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def uppercase_first(<<first::utf8, rest::binary>>) do
    result = String.upcase(<<first::utf8>>) <> rest
    {:ok, result}
  end

  ##############################################################################
  @doc """
  Generate random string
  """
  def random_string!(length)
      when not is_number(length) or length <= 0,
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["length cannot be nil; length must be a number; length must be > 0"])

  def random_string!(length) do
    result =
      :crypto.strong_rand_bytes(length)
      |> Base.url_encode64()
      |> binary_part(0, length)

    {:ok, result}
  end

  ##############################################################################
  @doc """
  ### Function
  Hash string
  """
  def hash!(text, salt \\ nil, alg \\ :sha256)

  def hash!(text, salt, alg)
      when not is_bitstring(text) or (not is_nil(salt) and not is_bitstring(salt)) or alg not in @crypto_alg,
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["text, alg cannot be nil; text must be a string; salt if not nil must be a string; alg must be on of #{inspect(alg)}"])

  def hash!(text, salt, alg) do
    Macros.raise_if_empty!(text, :string, "")

    result = is_not_empty(salt, :string)

    text =
      if :ok !== result do
        text
      else
        salt <> text
      end

    result =
      :crypto.hash(alg, text)
      |> Base.encode64()

    {:ok, result}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def format_string(string, list)
      when not is_bitstring(string) or not is_list(list),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["string, list cannot be nil; string must be a string; list must be a list"])

  def format_string(string, [head | tail]) do

    head = if is_bitstring(head), do: head, else: inspect(head)

    string = String.replace(string, @format_string_wildcard_pattern, head, global: false)
    format_string(string, tail)
  end

  def format_string(string, []) do
    string
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def map_to_struct!(module, map)
      when is_nil(map) or is_nil(module) or not is_map(map) or not is_atom(module),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["map, module cannot be nil; map must be a map; module must be an atom"])

  def map_to_struct!(module, map) do
    struct = struct(module)
    list = Map.to_list(Map.from_struct(struct))

    struct =
      Enum.reduce(list, struct, fn {k, _}, acc ->
        {:ok, k_atom} = Utils.string_to_atom(k)

        value_from_atom_key =
          case Map.fetch(map, k_atom) do
            {:ok, value} -> value
            :error -> nil
          end

        {:ok, k_string} = Utils.atom_to_string(k)

        value_from_string_key =
          case Map.fetch(map, k_string) do
            {:ok, value} -> value
            :error -> nil
          end

        value =
          if not is_nil(value_from_atom_key) and not is_nil(value_from_string_key) do
            UniError.raise_error!(:CODE_MAP_HAS_ATOM_AND_STRING_KEYS_WITH_SAME_NAME_ERROR, ["Map has atom and string keys with same name"], struct: module, key: k)
          else
            value_from_atom_key || value_from_string_key
          end

        %{acc | k => value}
      end)

    {:ok, struct}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def error_to_map(error)
      when not is_tuple(error),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["error cannot be nil; error must be a tuple"])

  def error_to_map({:error, code, data, messages} = _error)
      when not is_atom(code) or not is_map(data) or not is_list(messages),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["code, messages, data cannot be nil; code must be an atom; data must be a map; messages must be a list"])

  def error_to_map({:error, code, data, messages} = _error) do
    result = %{
      code: code,
      data: data,
      messages: messages
    }

    result
  end

  def error_to_map(error),
    do:
      UniError.raise_error!(
        :CODE_WRONG_ARGUMENT_COMBINATION_ERROR,
        ["Wrong argument combination"],
        error: error
      )

  ##############################################################################
  ##############################################################################
end
