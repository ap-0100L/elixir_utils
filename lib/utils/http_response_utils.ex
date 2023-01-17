defmodule HttpResponseUtils do
  ##############################################################################
  ##############################################################################
  @moduledoc """
  Response
  """

  use Utils

  ##############################################################################
  @doc """
  ## Function
  """
  defp build_response(code, data, messages \\ nil, debug_data \\ nil) do
    {:ok, timestamptz} = Utils.get_now_datetime_with_TZ_to_iso8601!()

    response = %{
      timestamptz: timestamptz,
      code: code,
      data: data
    }

    response =
      if is_nil(messages) do
        response
      else
        Map.put(response, :messages, messages)
      end

    response =
      if is_nil(debug_data) do
        response
      else
        Map.put(response, :debug_data, debug_data)
      end

    {:ok, response}
  end

  ##############################################################################
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

  ##############################################################################
  @doc """
  ## Function
  """
  defp get_debug_data(data, messages, stack, inspect_debug_data) do
    {:ok, hostname} = :inet.gethostname()
    # {:ok, addrs} = Utils.get_if_addrs!()

    stacktrace = Map.get(data, :stacktrace, nil)
    stack_from_data = Map.get(data, :stack, nil)

    stacktrace = stacktrace || stack_from_data

    data =
      if is_nil(stacktrace) or is_bitstring(stacktrace) do
        data
      else
        %{data | stacktrace: inspect(stacktrace)}
      end

    data =
      if inspect_debug_data do
        inspect(data)
      else
        data
      end

    debug_data = %{
      hostname: "#{hostname}",
      node_name: Node.self(),
      nodes: Node.list(),
      # ifaddrs: addrs,
      error_data: data,
      stacktrace: inspect(stack),
      messages: messages
    }

    {:ok, debug_data}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  defp map_code(code, messages) do
    result =
      case code do
        :CODE_OK ->
          {200, code, messages}

        :CODE_UNEXPECTED_ERROR ->
          {500, code, messages}

        value when value in [:CODE_HANDLER_NOT_FOUND, :CODE_NOTHING_FOUND] ->
          {404, code, messages}

        value
        when value in [
               :CODE_NOT_AUTHENTICATED_ERROR,
               :CODE_ESSENCE_NOT_FOUND_ERROR,
               :CODE_WRONG_PASSWORD_ERROR,
               :CODE_USER_NOT_FOUND_ERROR,
               :CODE_SECURITY_TOKEN_NOT_FOUND_ERROR,
               :CODE_REFRESH_TOKEN_NOT_FOUND_ERROR
             ] ->
          {401, :CODE_NOT_AUTHENTICATED_ERROR, ["Not authenticated"]}

        value
        when value in [
               :CODE_SECURITY_TOKEN_EXPIRED_ERROR,
               :CODE_REFRESH_TOKEN_EXPIRED_ERROR
             ] ->
          {401, code, ["Not authenticated"]}

        value
        when value in [
               :CODE_BY_ROLE_ACCESS_DENIED_ERROR,
               :CODE_BY_CHANNEL_ACCESS_DENIED_ERROR,
               :CODE_REST_API_ACTION_NOT_ALLOWED_ERROR,
               :CODE_GROUP_IS_PROHIBITED_ERROR,
               :CODE_PERK_IS_PROHIBITED_ERROR,
               :CODE_BY_GROUP_ACCESS_DENIED_ERROR,
               :CODE_BY_PERK_ACCESS_DENIED_ERROR,
               :CODE_ALL_GROUPS_IS_PROHIBITED_ERROR,
               :CODE_ALL_PERKS_IS_PROHIBITED_ERROR
             ] ->
          {403, :CODE_ACCESS_DENIED_ERROR, ["Access denied"]}

        _ ->
          {400, code, messages}
      end

    {:ok, result}
  end

  ##############################################################################
  @doc """
  def get_response({:error, code, data, messages}, stack)

  {:error, code, data, messages}
  {:ok, data}
  """
  def get_response(result, stack \\ nil, add_debug_data \\ nil, inspect_debug_data \\ true)

  def get_response({:error, code, data, messages}, stack, add_debug_data, inspect_debug_data) do
    {:ok, {status, code, messages}} = map_code(code, messages)

    add_debug_data =
      if is_nil(add_debug_data) do
        {:ok, add_debug_data} = Utils.get_app_env!(:add_debug_data)

        add_debug_data
      else
        add_debug_data
      end

    debug_data =
      if add_debug_data do
        {:ok, debug_data} = get_debug_data(data, messages, stack, inspect_debug_data)

        debug_data
      else
        nil
      end

    data = nil
    {:ok, response} = build_response(code, data, messages, debug_data)

    {:ok, {status, response}}
  end

  def get_response(%UniError{code: code, data: data, messages: messages}, stack, add_debug_data, inspect_debug_data) do
    get_response({:error, code, data, messages}, stack, add_debug_data, inspect_debug_data)
  end

  def get_response({:ok, data}, _stack, _add_debug_data, _inspect_debug_data) do
    status = 200
    code = :CODE_OK

    {:ok, response} = build_response(code, data)

    {:ok, {status, response}}
  end

  ##############################################################################
  ##############################################################################
end
