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
              reason: e_origin,
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

          if unquote(reraise) do
            reraise(e_origin, __STACKTRACE__)
          end

          Macros.build_error_(:CODE_RESCUED_ERROR, ["Error rescued"],
            reason: e_origin,
            stacktrace: __STACKTRACE__,
            rescue_func_result: result
          )
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
                Macros.build_error_(:CODE_CAUGHT_ERROR, ["Error caught"], reason: e_origin)
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
              {:error, _code, _data, _messages} ->
                e

              _ ->
                Macros.build_error_(:CODE_CAUGHT_ERROR, ["Error caught"], reason: e_origin)
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

          if unquote(reraise) do
            exit(reason)
          end

          Macros.build_error_(:CODE_EXIT_CAUGHT_ERROR, ["EXIT caught error"],
            reason: reason,
            stacktrace: __STACKTRACE__,
            rescue_func_result: result
          )
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
  defmacro build_error_(code, messages, opt \\ nil)

  defmacro build_error_(code, messages, opt) do
    quote do
      data =
        if is_nil(unquote(opt)) or not is_list(unquote(opt)) do
          %{euid: UUID.uuid1()}
        else
          data = Keyword.get(unquote(opt), :data, %{})
          data = Map.put(data, :euid, UUID.uuid1())
          opt = Keyword.delete(unquote(opt), :data)

          Enum.reduce(
            opt,
            data,
            fn {key, value}, accum ->
              Map.put(accum, key, value)
            end
          )
        end

      {
        :error,
        unquote(code),
        data,
        unquote(messages)
      }
    end
  end

  ##############################################################################
  @doc """

  """
  defmacro throw_error!(code, messages, opt \\ nil)

  defmacro throw_error!(code, messages, opt) do
    quote do
      throw(Macros.build_error_(unquote(code), unquote(messages), unquote(opt)))
    end
  end

  ##############################################################################
  @doc """

  """
  defmacro throw_if_empty!(o, type, message) do
    quote do
      result = Utils.is_not_empty(unquote(o), unquote(type))

      if result !== :ok do
        {:error, code, data, messages} = result

        messages =
          if :ok == Utils.is_not_empty(unquote(message), :string) do
            messages ++ [unquote(message)]
          end

        Macros.throw_error!(code, messages, data: data)
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

        messages =
          if :ok == Utils.is_not_empty(unquote(message), :string) do
            messages ++ [unquote(message)]
          end

        Macros.throw_error!(code, messages, data: data)
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
