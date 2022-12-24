defmodule UniError do
  ##############################################################################
  ##############################################################################
  @moduledoc """
  ## Module
  """

  require Logger

  defexception [:code, :messages, :data]

  def expand_macro() do
    Macro.expand(
      nil,
      __ENV__
    )
    |> Macro.to_string()
  end

  ##############################################################################
  @doc """
  ## Function
  """
  defmacro build_uni_error_(code, messages, data \\ nil)

  defmacro build_uni_error_(code, messages, data) do
    quote do
      code = unquote(code)
      messages = unquote(messages)
      data = unquote(data)

      {previous_messages, data} =
        if is_nil(data) or (not is_list(data) and not is_map(data)) do
          data =
            if is_nil(data) do
              %{eid: UUID.uuid1()}
            else
              %{
                eid: UUID.uuid1(),
                unsupported_data: data
              }
            end

          {[], data}
        else
          data =
            if is_list(data) do
              Enum.into(data, %{})
            else
              data
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

                %_{code: _code, data: _data, messages: messages} ->
                  {messages, data}

                %_{messages: messages} ->
                  {messages, data}

                %_{message: messages} ->
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

      messages = if is_nil(messages), do: [], else: messages

      messages =
        if not is_list(messages) do
          [messages]
        else
          messages
        end

      previous_messages = if is_nil(previous_messages), do: [], else: previous_messages

      previous_messages =
        if not is_list(previous_messages) do
          [previous_messages]
        else
          previous_messages
        end

      result = %UniError{
        code: code,
        data: data,
        messages: previous_messages ++ messages
      }
    end
  end

  ##############################################################################
  @doc """
  ## Function
  """
  defmacro build_error_(code, messages, data \\ nil)

  defmacro build_error_(code, messages, data) do
    quote do
      code = unquote(code)
      messages = unquote(messages)
      data = unquote(data)
      e = UniError.build_uni_error_(code, messages, data)

      %UniError{
        code: code,
        data: data,
        messages: messages
      } = e

      {:error, code, data, messages}
    end
  end

  ##############################################################################
  @doc """

  rescue_func.(%UniError{} = e, __STACKTRACE__, rescue_func_args)

  {:error, %UniError{} = e}
  """
  defmacro rescue_error!(clause, reraise \\ true, log_error \\ true, rescue_func \\ nil, rescue_func_args \\ [], module \\ nil)

  defmacro rescue_error!(clause, reraise, log_error, rescue_func, rescue_func_args, module) do
    quote do
      reraise = unquote(reraise)
      log_error = unquote(log_error)
      rescue_func = unquote(rescue_func)
      rescue_func_args = unquote(rescue_func_args)
      module = unquote(module)

      try do
        unquote(clause)
      rescue
        e in UniError ->
          if log_error do
            Logger.error("[#{inspect(__MODULE__)}][#{inspect(__ENV__.function)}] RAISED UNI-EXCEPTION: #{inspect(e)}; STACKTRACE: #{inspect(__STACKTRACE__)}")
          end

          result =
            if not is_nil(rescue_func) do
              if not is_nil(module) do
                apply(module, rescue_func, [e, __STACKTRACE__] ++ [rescue_func_args])
              else
                rescue_func.(e, __STACKTRACE__, rescue_func_args)
              end
            else
              nil
            end

          %UniError{data: data} = e
          data = Map.put(data, :rescue_func_result, result)
          stacktrace = Map.get(data, :stacktrace, __STACKTRACE__)
          data = Map.put(data, :stacktrace, stacktrace)
          e = Map.put(e, :data, data)

          if reraise do
            reraise(e, __STACKTRACE__)
          end

          {:error, e}

        unsupported ->
          if log_error do
            Logger.error("[#{inspect(__MODULE__)}][#{inspect(__ENV__.function)}] RAISED UNSUPPORTED ERROR: #{inspect(unsupported)}; STACKTRACE: #{inspect(__STACKTRACE__)}")
          end

          e = UniError.build_uni_error_(:CODE_RAISED_UNSUPPORTED_ERROR, ["Raised unsupported error"], previous: unsupported)

          result =
            if not is_nil(rescue_func) do
              if not is_nil(module) do
                apply(module, rescue_func, [e, __STACKTRACE__] ++ [rescue_func_args])
              else
                rescue_func.(e, __STACKTRACE__, rescue_func_args)
              end
            else
              nil
            end

          %UniError{data: data} = e
          data = Map.put(data, :rescue_func_result, result)
          stacktrace = Map.get(data, :stacktrace, __STACKTRACE__)
          data = Map.put(data, :stacktrace, stacktrace)
          e = Map.put(e, :data, data)

          if reraise do
            reraise(e, __STACKTRACE__)
          end

          {:error, e}
      catch
        returned ->
          returned

        exit, %UniError{} = reason ->
          if log_error do
            Logger.error("[#{inspect(__MODULE__)}][#{inspect(__ENV__.function)}] EXIT REASON: #{inspect(reason)}; STACKTRACE: #{inspect(__STACKTRACE__)}")
          end

          # e = UniError.build_uni_error_(:CODE_EXIT_CAUGHT_ERROR, ["Caught EXIT Uni-reason"], previous: reason)
          e = reason

          result =
            if not is_nil(rescue_func) do
              if not is_nil(module) do
                apply(module, rescue_func, [e, __STACKTRACE__] ++ [rescue_func_args])
              else
                rescue_func.(e, __STACKTRACE__, rescue_func_args)
              end
            else
              nil
            end

          %UniError{data: data} = e
          data = Map.put(data, :rescue_func_result, result)
          stacktrace = Map.get(data, :stacktrace, [])
          stacktrace = stacktrace ++ [__STACKTRACE__]
          data = Map.put(data, :stacktrace, stacktrace)
          e = Map.put(e, :data, data)

          if reraise do
            exit(e)
          end

          {:error, e}

        exit, reason ->
          if log_error do
            Logger.error("[#{inspect(__MODULE__)}][#{inspect(__ENV__.function)}] EXIT UNSUPPORTED REASON: #{inspect(reason)}; STACKTRACE: #{inspect(__STACKTRACE__)}")
          end

          e = UniError.build_uni_error_(:CODE_EXIT_CAUGHT_ERROR, ["Caught unsupported EXIT reason"], previous: reason)

          result =
            if not is_nil(rescue_func) do
              if not is_nil(module) do
                apply(module, rescue_func, [e, __STACKTRACE__] ++ [rescue_func_args])
              else
                rescue_func.(e, __STACKTRACE__, rescue_func_args)
              end
            else
              nil
            end

          %UniError{data: data} = e
          data = Map.put(data, :rescue_func_result, result)
          stacktrace = Map.get(data, :stacktrace, [])
          stacktrace = stacktrace ++ [__STACKTRACE__]
          data = Map.put(data, :stacktrace, stacktrace)
          e = Map.put(e, :data, data)

          if reraise do
            exit(e)
          end

          {:error, e}
      end
    end
  end

  ##############################################################################
  @doc """
  ## Function
  """
  defmacro raise_error!(e) do
    quote do
      raise(UniError, unquote(e))
    end
  end

  ##############################################################################
  @doc """
  ## Function
  """
  defmacro raise_error!(code, messages, data \\ nil)

  defmacro raise_error!(code, messages, data) do
    quote do
      raise(UniError, code: unquote(code), data: unquote(data), messages: unquote(messages))
    end
  end

  ##############################################################################
  @doc """
  ## Function
  """
  @impl true
  def exception(code: code, data: data, messages: messages) do
    build_uni_error_(code, messages, data)
  end

  @impl true
  def exception({:error, code, data, messages} = _exception) do
    build_uni_error_(code, messages, data)
  end

  @impl true
  def exception(exception) do
    build_uni_error_(:CODE_UNEXPECTED_NOT_STRUCTURED_ERROR, ["Unexpected not structured error"], previous: exception)
  end

  ##############################################################################
  @doc """
  ## Function
  """
  @impl true
  def message(%__MODULE__{code: _code, data: _data, messages: _messages} = e) do
    inspect(e)
  end

  ##############################################################################
  ##############################################################################
end
