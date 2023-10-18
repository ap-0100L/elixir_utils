defmodule UniError do
  ####################################################################################################################
  ####################################################################################################################
  @moduledoc """
  ## Module
  """

  require Logger

  defexception [:code, :messages, :data]

  ####################################################################################################################
  @doc """
  ## Function
  """
  def expand_macro() do
    Macro.expand(
      nil,
      __ENV__
    )
    |> Macro.to_string()
  end

  ####################################################################################################################
  @doc """
  ## Function

  ### Call
  UniError.raise_error!(
    :SOME_NAME_ERROR,
    ["Message1", "Message2"],
    useful_data1: useful_data1,
    useful_data2: useful_data2,
    previous: %UniError{
      code: :PREVIOUS_ERROR,
      data: %{some_data: "some_data"},
      messages: ["Previous message"]
    }
  )

  ### Return
  %UniError{
    code: :SOME_NAME_ERROR,
    data: %{
      eid: "721c47de-8bf8-11ed-933d-02420a000104",
      useful_data1: useful_data1,
      useful_data2: useful_data2,
      previous: %UniError{
        eid: "5cd03bce-8bf8-11ed-933d-02420a000104",
        code: :PREVIOUS_ERROR,
        data: %{some_data: "some_data"},
        messages: ["Previous message"]
      }
    },
    messages: ["Message1", "Message2", "Previous message"],
  }

  """
  defmacro build_uni_error(code, messages, data \\ nil)

  defmacro build_uni_error(code, messages, data) do
    quote do
      code = unquote(code)
      messages = unquote(messages)
      data = unquote(data)

      # FIXME: U can add stacktrace on build UniError
      # {:current_stacktrace, stacktrace} = Process.info(self(), :current_stacktrace)
      # stacktrace = inspect(stacktrace)

      eid = UUID.uuid4()

      {previous_messages, data} =
        if is_nil(data) or (not is_list(data) and not is_map(data)) do
          data =
            if is_nil(data) do
              %{eid: eid, node: Node.self(), module: __MODULE__, function: __ENV__.function}
            else
              %{
                eid: eid,
                unsupported_data: data,
                node: Node.self(),
                module: __MODULE__,
                function: __ENV__.function
              }
            end

          {[], data}
        else
          data =
            if is_list(data) do
              Enum.into(data ++ [node: Node.self(), module: __MODULE__, function: __ENV__.function], %{})
            else
              data
              Map.put(data, :node, Node.self())
              Map.put(data, :function, __ENV__.function)
              Map.put(data, :module, __MODULE__)
            end

          previous = Map.get(data, :previous, nil)

          {messages, data} =
            if is_nil(previous) do
              data = Map.delete(data, :previous)
              {[], data}
            else
              case previous do
                {:error, _code, messages, _data} ->
                  {messages, data}

                %_{code: _code, messages: messages, data: _data} ->
                  {messages, data}

                %_{messages: messages} ->
                  {messages, data}

                %_{message: message} ->
                  {[message], data}

                _ ->
                  {[], data}
              end
            end

          # eid =
          #  inspect(System.os_time(:nanosecond))
          #  |> Stream.unfold(&String.split_at(&1, 3))
          #  |> Enum.take_while(&(&1 != ""))
          #  |> Enum.reduce("", fn item, accum -> accum <> item end)

          data = Map.put(data, :eid, eid)

          {messages, data}
        end

      timestamp = System.os_time(:nanosecond)
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

      %UniError{
        code: code,
        data: data,
        messages: messages ++ previous_messages ++ ["EID: [#{eid}]"] ++ ["NODE: [#{Node.self()}]"]
      }
    end
  end

  ####################################################################################################################
  @doc """
  ## Function
  """
  defmacro build_error(code, messages, data \\ nil)

  defmacro build_error(code, messages, data) do
    quote do
      code = unquote(code)
      messages = unquote(messages)
      data = unquote(data)
      e = UniError.build_uni_error(code, messages, data)

      %UniError{
        code: code,
        data: data,
        messages: messages
      } = e

      {:error, code, messages, data}
    end
  end

  ####################################################################################################################
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

      {reraise, wrap, re_error} =
        if is_tuple(reraise) do
          reraise
        else
          {if(reraise, do: true, else: false), false, nil}
        end

      {wrap_code, wrap_messages, wrap_data} =
        if is_tuple(re_error) do
          case tuple_size(re_error) do
            3 ->
              {code, messages, data} = re_error
              if is_list(data), do: {code, messages, data}, else: {code, messages, [data: data]}

            2 ->
              {code, messages} = re_error
              {code, messages, %{}}

            _ ->
              {:RAISED_UNSUPPORTED_ERROR, ["Raised unsupported error"], %{}}
          end
        else
          {:RAISED_UNSUPPORTED_ERROR, ["Raised unsupported error"], %{}}
        end

      try do
        unquote(clause)
      rescue
        e in UniError ->
          if log_error do
            Logger.error("[#{inspect(__MODULE__)}][#{inspect(__ENV__.function)}] RAISED UNI-EXCEPTION: #{inspect(e)}; STACKTRACE: #{inspect(__STACKTRACE__)}")
          end

          %UniError{messages: messages, data: data} = e
          last_message = List.last(messages)

          messages =
            if String.contains?(last_message, "STACKTRACE: [") do
              messages
            else
              messages ++ ["STACKTRACE: [#{inspect(__STACKTRACE__)}]"]
            end

          stacktrace = Map.get(data, :stacktrace, __STACKTRACE__)
          data = Map.put(data, :stacktrace, stacktrace)
          e = Map.put(e, :data, data)
          e = Map.put(e, :messages, messages)

          e =
            if wrap != false do
              UniError.build_uni_error(wrap_code, wrap_messages, wrap_data ++ [previous: e])
            else
              e
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
          e = Map.put(e, :data, data)

          if reraise != false do
            reraise(e, __STACKTRACE__)
          end

          {:error, e}

        unsupported ->
          if log_error do
            Logger.error("[#{inspect(__MODULE__)}][#{inspect(__ENV__.function)}] RAISED UNSUPPORTED ERROR: #{inspect(unsupported)}; STACKTRACE: #{inspect(__STACKTRACE__)}")
          end

          {code, messages, data} = {wrap_code, wrap_messages ++ ["STACKTRACE: [#{inspect(__STACKTRACE__)}]"], wrap_data ++ [previous: unsupported, stacktrace: __STACKTRACE__]}
          e = UniError.build_uni_error(code, messages, data)

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
          e = Map.put(e, :data, data)

          if reraise != false do
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

          e = reason

          %UniError{messages: messages, data: data} = e
          last_message = List.last(messages)

          messages =
            if String.contains?(last_message, "STACKTRACE: [") do
              messages
            else
              messages ++ ["STACKTRACE: [#{inspect(__STACKTRACE__)}]"]
            end

          stacktrace = Map.get(data, :stacktrace, __STACKTRACE__)
          data = Map.put(data, :stacktrace, stacktrace)
          e = Map.put(e, :data, data)
          e = Map.put(e, :messages, messages)

          e =
            if wrap != false do
              UniError.build_uni_error(wrap_code, wrap_messages, wrap_data ++ [previous: e])
            else
              e
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
          e = Map.put(e, :data, data)

          if reraise != false do
            exit(e)
          end

          {:error, e}

        exit, reason ->
          if log_error do
            Logger.error("[#{inspect(__MODULE__)}][#{inspect(__ENV__.function)}] EXIT UNSUPPORTED REASON: #{inspect(reason)}; STACKTRACE: #{inspect(__STACKTRACE__)}")
          end

          {code, messages, data} = {wrap_code, wrap_messages ++ ["STACKTRACE: [#{inspect(__STACKTRACE__)}]"], wrap_data ++ [previous: reason, stacktrace: __STACKTRACE__]}
          e = UniError.build_uni_error(code, messages, data)

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
          e = Map.put(e, :data, data)

          if reraise != false do
            exit(e)
          end

          {:error, e}
      end
    end
  end

  ####################################################################################################################
  @doc """
  ## Function
  """
  defmacro raise_error!(exception) do
    quote do
      # FIXME: U can add stacktrace on raise UniError
      # {:current_stacktrace, stacktrace} = Process.info(self(), :current_stacktrace)
      # stacktrace = inspect(stacktrace)

      exception = unquote(exception)

      if not is_nil(exception) and is_struct(exception) and exception.__struct__ === UniError do
        raise(exception)
      end

      exception = UniError.build_uni_error(:UNEXPECTED_NOT_STRUCTURED_ERROR, ["Unexpected not structured error"], previous: exception)
      raise(exception)
    end
  end

  ####################################################################################################################
  @doc """
  ## Function
  """
  defmacro raise_error!(code, messages, data \\ nil)

  defmacro raise_error!(code, messages, data) do
    quote do
      # FIXME: U can add stacktrace on raise UniError
      # {:current_stacktrace, stacktrace} = Process.info(self(), :current_stacktrace)
      # stacktrace = inspect(stacktrace)

      exception = UniError.build_uni_error(unquote(code), unquote(messages), data: unquote(data))
      raise(exception)
    end
  end

  ####################################################################################################################
  @doc """
  ## Function
  """
  @impl true
  def exception(%__MODULE__{code: _code, messages: _messages, data: _data} = exception) do
    exception
  end

  @impl true
  def exception(code: code, messages: messages, data: data) do
    build_uni_error(code, messages, data)
  end

  @impl true
  def exception({:error, code, messages, data} = _exception) do
    build_uni_error(code, messages, data)
  end

  @impl true
  def exception(exception) do
    build_uni_error(:UNEXPECTED_NOT_STRUCTURED_ERROR, ["Unexpected not structured error"], previous: exception)
  end

  ####################################################################################################################
  @doc """
  ## Function
  """
  @impl true
  def message(%__MODULE__{code: _code, messages: _messages, data: _data} = exception) do
    inspect(exception)
  end

  ####################################################################################################################
  ####################################################################################################################
end
