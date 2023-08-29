defmodule HttpResponseUtils do
  ####################################################################################################################
  ####################################################################################################################
  @moduledoc """
  Response
  """

  use Utils

  ####################################################################################################################
  @doc """
  ## Function
  """
  defp build_response(code, data, messages \\ nil, debug_data \\ nil) do
    timestamp = System.os_time(:millisecond)

    response = %{
      timestamp: timestamp,
      code: code,
      data: data,
      messages: messages
    }

    response =
      if is_nil(debug_data) do
        response
      else
        Map.put(response, :debug_data, debug_data)
      end

    {:ok, response}
  end

  ####################################################################################################################
  @doc """
  ## Function
  """
  def get_debug_data() do
    {:ok, hostname} = :inet.gethostname()
    # {:ok, addrs} = Utils.get_if_addrs!()

    debug_data = %{
      hostname: "#{hostname}",
      node_name: Node.self(),
      nodes: Node.list()
      # ifaddrs: addrs
    }

    {:ok, debug_data}
  end

  ####################################################################################################################
  @doc """
  ## Function
  """
  defp get_debug_data(error_data, messages, stack, inspect_debug_data) do
    {:ok, hostname} = :inet.gethostname()
    # {:ok, addrs} = Utils.get_if_addrs!()

    stacktrace_from_error_data = Map.get(error_data, :stacktrace, nil)
    stack_from_error_data = Map.get(error_data, :stack, nil)

    error_data = Map.delete(error_data, :stacktrace)
    error_data = Map.delete(error_data, :stack)

    stacktrace = stack_from_error_data || stacktrace_from_error_data || stack

    error_data =
      if inspect_debug_data do
        Map.put(error_data, :stacktrace, stacktrace)
        inspect(error_data)
      else
        if is_nil(stacktrace) or is_bitstring(stacktrace) do
          Map.put(error_data, :stacktrace, stacktrace)
        else
          Map.put(error_data, :stacktrace, inspect(stacktrace))
        end
      end

    debug_data = %{
      hostname: "#{hostname}",
      node_name: Node.self(),
      nodes: Node.list(),
      # ifaddrs: addrs,
      error_data: error_data,
      messages: messages
    }

    {:ok, debug_data}
  end

  ####################################################################################################################
  @doc """
  ## Function
  """
  defp map_code(code, messages) do
    result =
      case code do
        :OK ->
          {200, code, messages}

        :UNHANDLED_ERROR ->
          {500, code, messages}

        :SYSTEM_IN_MAINTENANCE_MODE_ERROR ->
          {503, code, messages}

        value when value in [:HANDLER_NOT_FOUND_ERROR, :NOT_FOUND, :STATUS_NOT_FOUND_ERROR] ->
          {404, code, messages}

        value
        when value in [
               :NOT_AUTHENTICATED_ERROR,
               :ESSENCE_NOT_FOUND_ERROR,
               :WRONG_PASSWORD_ERROR,
               :USER_NOT_FOUND_ERROR,
               :SECURITY_TOKEN_NOT_FOUND_ERROR,
               :REFRESH_TOKEN_NOT_FOUND_ERROR
             ] ->
          {401, :NOT_AUTHENTICATED_ERROR, ["Not authenticated"]}

        value
        when value in [
               :SECURITY_TOKEN_EXPIRED_ERROR,
               :REFRESH_TOKEN_EXPIRED_ERROR
             ] ->
          {401, code, ["Not authenticated"]}

        value
        when value in [
               :BY_ROLE_ACCESS_DENIED_ERROR,
               :BY_CHANNEL_ACCESS_DENIED_ERROR,
               :REST_API_ACTION_NOT_ALLOWED_ERROR,
               :GROUP_IS_PROHIBITED_ERROR,
               :PERK_IS_PROHIBITED_ERROR,
               :BY_GROUP_ACCESS_DENIED_ERROR,
               :BY_PERK_ACCESS_DENIED_ERROR,
               :ALL_GROUPS_IS_PROHIBITED_ERROR,
               :ALL_PERKS_IS_PROHIBITED_ERROR
             ] ->
          {403, :ACCESS_DENIED_ERROR, ["Access denied"]}

        _ ->
          {400, code, messages}
      end

    {:ok, result}
  end

  ####################################################################################################################
  @doc """
  def get_response({:error, code, messages, data}, stack)

  {:error, code, messages, data}
  {:ok, data}
  """
  def get_response(result, stack \\ nil, add_debug_data \\ nil, inspect_debug_data \\ true)

  def get_response({:error, code, messages, data}, stack, add_debug_data, inspect_debug_data) do
    {:ok, {status, code, messages}} = map_code(code, messages)

    add_debug_data =
      if is_nil(add_debug_data) do
        {:ok, add_debug_data} = Utils.get_app_env(:add_debug_data)

        add_debug_data
      else
        add_debug_data
      end

    response_data = Map.get(data, :response_data, nil)
    debug_data =
      if add_debug_data do
        {:ok, debug_data} = get_debug_data(data, messages, stack, inspect_debug_data)

        debug_data
      else
        nil
      end

    {:ok, response} = build_response(code, response_data, messages, debug_data)

    {:ok, {status, response}}
  end

  def get_response(%UniError{code: code, messages: messages, data: data}, stack, add_debug_data, inspect_debug_data) do
    get_response({:error, code, messages, data}, stack, add_debug_data, inspect_debug_data)
  end

  def get_response({:ok, data}, _stack, _add_debug_data, _inspect_debug_data) do
    status = 200
    code = :OK

    {:ok, response} = build_response(code, data)

    {:ok, {status, response}}
  end

  ####################################################################################################################
  ####################################################################################################################
end
