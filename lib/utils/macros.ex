defmodule Macros do
  ##############################################################################
  ##############################################################################
  @moduledoc """

  # Macros

  """

  alias Utils, as: Utils

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
          try do
            result = unquote(clause)

            {:ok, result}
          rescue
            e ->
              if unquote(log_error) do
                Logger.error("[#{inspect(__MODULE__)}][#{inspect(__ENV__.function)}] RAISED EXCEPTION: #{inspect(e)}; STACKTRACE: #{inspect(__STACKTRACE__)}")
              end

              result = unquote(do_rescue)

              if unquote(reraise) do
                raise(e)
              end

              {e, result}
          catch
            e ->
              unquote(do_rescue)

              if unquote(log_error) do
                Logger.error("[#{inspect(__MODULE__)}][#{inspect(__ENV__.function)}] THREW EXCEPTION: #{inspect(e)}; STACKTRACE: #{inspect(__STACKTRACE__)}")
              end

              result = unquote(do_rescue)

              if unquote(reraise) do
                throw(e)
              end

              {e, result}

            :exit, reason ->
              unquote(do_rescue)

              if unquote(log_error) do
                Logger.error("[#{inspect(__MODULE__)}][#{inspect(__ENV__.function)}] EXIT REASON: #{inspect(reason)}; STACKTRACE: #{inspect(__STACKTRACE__)}")
              end

              result = unquote(do_rescue)

              if unquote(reraise) do
                exit(reason)
              end

              e =
                Macros.build_error_(:CODE_EXIT_CAUGHT_ERROR, ["EXIT caught error"],
                  reason: reason,
                  stacktrace: __STACKTRACE__
                )

              {e, result}
          end
        end
      ),
      __ENV__
    )
    |> Macro.to_string()
  end

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
  {:ok, result}
  {:error, code, %{reason: e_origin, stacktrace: __STACKTRACE__, rescue_func_result: rescue_func_result} = data, messages}
  {:error, code, data, messages}
  """
  defmacro catch_error!(clause, reraise \\ true, log_error \\ true, rescue_func \\ nil, rescue_func_args \\ [], module \\ nil)

  defmacro catch_error!(clause, reraise, log_error, rescue_func, rescue_func_args, module) do
    quote do
      try do
        unquote(clause)
      rescue
        e ->
          if unquote(log_error) do
            Logger.error("[#{inspect(__MODULE__)}][#{inspect(__ENV__.function)}] RAISED EXCEPTION: #{inspect(e)}; STACKTRACE: #{inspect(__STACKTRACE__)}")
          end

          e_origin = e

          e =
            Macros.build_error_(:CODE_RESCUED_ERROR, ["Error rescued"],
              previous: e_origin,
              stacktrace: __STACKTRACE__
            )

          module = unquote(module)
          rescue_func = unquote(rescue_func)

          result =
            if not is_nil(rescue_func) do
              if not is_nil(module) do
                apply(module, rescue_func, [e, __STACKTRACE__] ++ [unquote(rescue_func_args)])
              else
                rescue_func.(e, __STACKTRACE__, unquote(rescue_func_args))
              end
            else
              nil
            end

          e =
            Macros.build_error_(:CODE_RESCUED_ERROR, ["Error rescued"],
              previous: e_origin,
              stacktrace: __STACKTRACE__,
              rescue_func_result: result
            )

          if unquote(reraise) do
            # reraise(e_origin, __STACKTRACE__)
            throw(e)
          end

          e
      catch
        e ->
          if unquote(log_error) do
            Logger.error("[#{inspect(__MODULE__)}][#{inspect(__ENV__.function)}] THREW EXCEPTION: #{inspect(e)}; STACKTRACE: #{inspect(__STACKTRACE__)}")
          end

          e_origin = e

          e =
            case e_origin do
              {:error, _code, _data, _messages} ->
                e

              _ ->
                Macros.build_error_(:CODE_CAUGHT_ERROR, ["Error caught"], previous: e_origin)
            end

          module = unquote(module)
          rescue_func = unquote(rescue_func)

          result =
            if not is_nil(rescue_func) do
              if not is_nil(module) do
                apply(module, rescue_func, [e, __STACKTRACE__] ++ [unquote(rescue_func_args)])
              else
                rescue_func.(e, __STACKTRACE__, unquote(rescue_func_args))
              end
            else
              nil
            end

          e =
            case e_origin do
              {:error, code, data, messages} ->
                data = Map.put(data, :rescue_func_result, result)
                {:error, code, data, messages}

              _ ->
                Macros.build_error_(:CODE_CAUGHT_ERROR, ["Error caught"],
                  previous: e_origin,
                  stacktrace: __STACKTRACE__,
                  rescue_func_result: result
                )
            end

          if unquote(reraise) do
            throw(e)
          end

          e

        :exit, reason ->
          if unquote(log_error) do
            Logger.error("[#{inspect(__MODULE__)}][#{inspect(__ENV__.function)}] EXIT REASON: #{inspect(reason)}; STACKTRACE: #{inspect(__STACKTRACE__)}")
          end

          e =
            Macros.build_error_(:CODE_EXIT_CAUGHT_ERROR, ["EXIT caught error"],
              reason: reason,
              stacktrace: __STACKTRACE__
            )

          module = unquote(module)
          rescue_func = unquote(rescue_func)

          result =
            if not is_nil(rescue_func) do
              if not is_nil(module) do
                apply(module, rescue_func, [e, __STACKTRACE__] ++ [unquote(rescue_func_args)])
              else
                rescue_func.(e, __STACKTRACE__, unquote(rescue_func_args))
              end
            else
              nil
            end

          e =
            Macros.build_error_(:CODE_EXIT_CAUGHT_ERROR, ["EXIT caught error"],
              reason: reason,
              stacktrace: __STACKTRACE__,
              rescue_func_result: result
            )

          if unquote(reraise) do
            # exit(reason)
            throw(e)
          end

          e
      end
    end
  end

  ##############################################################################
  @doc """

  """
  defmacro is_datetime(o) do
    quote do
      not is_nil(unquote(o)) and is_struct(unquote(o)) and unquote(o).__struct__ === DateTime
    end
  end

  ##############################################################################
  @doc """

  """
  defmacro is_struct_of_type(o, type) do
    quote do
      not is_nil(unquote(o)) and is_struct(unquote(o)) and unquote(o).__struct__ === unquote(type)
    end
  end

  ##############################################################################
  @doc """

  """
  defmacro is_enumerable(o) do
    quote do
      not is_nil(unquote(o)) and (is_list(unquote(o)) or is_map(unquote(o)))
    end
  end

  ##############################################################################
  @doc """

  """
  defmacro build_error_(code, messages, data \\ nil)

  defmacro build_error_(code, messages, data) do
    quote do
      {previous_messages, data} =
        if is_nil(unquote(data)) or (not is_list(unquote(data)) and not is_map(unquote(data))) do
          data =
            if not is_list(unquote(data)) and not is_map(unquote(data)) and not is_nil(unquote(data)) do
              %{
                eid: UUID.uuid1(),
                unsupported_data: unquote(data)
              }
            else
              %{eid: UUID.uuid1()}
            end

          {[], data}
        else
          data =
            if is_list(unquote(data)) do
              Enum.into(unquote(data), %{})
            else
              unquote(data)
            end

          # TODO: previous {:error, code, data, messages} to %{code: code, data: data, messages: messages}
          previous = Map.get(data, :previous, nil)

          {messages, data} =
            if is_nil(previous) do
              data = Map.delete(data, :previous)
              {[], data}
            else
              case previous do
                {:error, _code, _data, messages} ->
                  {messages, data}

                _ ->
                  {[], data}
              end
            end

          data = Map.put(data, :eid, UUID.uuid1())

          {messages, data}
        end

      timestamp = now = System.system_time(:nanosecond)
      data = Map.put(data, :timestamp, timestamp)

      messages =
        if not is_list(unquote(messages)) do
          [unquote(messages)]
        else
          unquote(messages)
        end

      previous_messages =
        if not is_list(previous_messages) do
          [previous_messages]
        else
          previous_messages
        end

      result = {
        :error,
        unquote(code),
        data,
        previous_messages ++ messages
      }
    end
  end

  ##############################################################################
  @doc """

  """
  defmacro build_uni_error_(code, messages, data \\ nil)

  defmacro build_uni_error_(code, messages, data) do
    quote do
      {previous_messages, data} =
        if is_nil(unquote(data)) or (not is_list(unquote(data)) and not is_map(unquote(data))) do
          data =
            if not is_list(unquote(data)) and not is_map(unquote(data)) and not is_nil(unquote(data)) do
              %{
                eid: UUID.uuid1(),
                unsupported_data: unquote(data)
              }
            else
              %{eid: UUID.uuid1()}
            end

          {[], data}
        else
          data =
            if is_list(unquote(data)) do
              Enum.into(unquote(data), %{})
            else
              unquote(data)
            end

          previous = Map.get(data, :previous, nil)

          {messages, data} =
            if is_nil(previous) do
              data = Map.delete(data, :previous)
              {[], data}
            else
              case previous do
                {:error, _code, _data, messages} ->
                  {messages, data}

                _ ->
                  {[], data}
              end
            end

          data = Map.put(data, :eid, UUID.uuid1())

          {messages, data}
        end

      timestamp = now = System.system_time(:nanosecond)
      data = Map.put(data, :timestamp, timestamp)

      messages =
        if not is_list(unquote(messages)) do
          [unquote(messages)]
        else
          unquote(messages)
        end

      previous_messages =
        if not is_list(previous_messages) do
          [previous_messages]
        else
          previous_messages
        end

      result = %UniError{
        code: unquote(code),
        data: data,
        messages: previous_messages ++ messages
      }
    end
  end

  ##############################################################################
  @doc """

  """
  defmacro build_uni_error_(error) do
    quote do
      origin_error = unquote(error)



    end
  end

  ##############################################################################
  @doc """

  """
  defmacro throw_error!(code, messages, data \\ nil)

  defmacro throw_error!(code, messages, data) do
    quote do
      throw(Macros.build_error_(unquote(code), unquote(messages), unquote(data)))
    end
  end

  ##############################################################################
  @doc """

  """
  defmacro throw_error!(e) do
    quote do
      case unquote(e) do
        {:error, _code, _data, _messages} ->
          throw(unquote(e))

        _ ->
          throw(Macros.build_error_(:CODE_UNEXPECTED_ERROR, ["Unexpected error"], error: unquote(e)))
      end
    end
  end

  ##############################################################################
  @doc """

  """
  defmacro throw_if_empty!(o, type, message) do
    quote do
      result = Utils.is_not_empty(unquote(o), unquote(type))

      if result !== :ok do
        {:error, code, _data, messages} = result

        Macros.throw_error!(code, messages ++ [unquote(message)])
      end

      :ok
    end
  end

  ##############################################################################
  @doc """

  """
  defmacro throw_if_empty!(map, key, key_value_type, message) do
    quote do
      result = Utils.is_not_empty(unquote(map), unquote(key), unquote(key_value_type))

      if result !== :ok do
        {:error, code, data, messages} = result
        messages = messages || []
        Macros.throw_error!({:error, code, data, messages ++ [unquote(message)]})
      end

      {:ok, Map.get(unquote(map), unquote(key))}
    end
  end

  ##############################################################################
  @doc """

  """
  defmacro get_app_env!(key) do
    quote do
      application_name_atom = Application.get_application(__MODULE__)
      throw_if_empty!(application_name_atom, :atom, "Wrong application_name_atom value")
      Utils.get_app_env!(application_name_atom, unquote(key))
    end
  end

  ##############################################################################
  @doc """

  """
  defmacro get_app_env_(key) do
    quote do
      application_name_atom = Application.get_application(__MODULE__)
      throw_if_empty!(application_name_atom, :atom, "Wrong application_name_atom value")
      {:ok, value} = Utils.get_app_env!(application_name_atom, unquote(key))

      value
    end
  end

  ##############################################################################
  @doc """

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
