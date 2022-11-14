defmodule RPCUtils do
  ##############################################################################
  ##############################################################################
  @moduledoc """

  RPC Utils.

  """

  use Utils

  ##############################################################################
  @doc """

  """
  def call_rpc!(node, module, function, args)
      when is_nil(node) or is_nil(module) or is_nil(function) or is_nil(args) or
             (not is_atom(node) and not is_list(node)) or not is_atom(module) or
             not is_atom(function) or
             not is_list(args),
      do: throw_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["node, module, function, args cannot be nil; module, function must be an atom; node must be an atom or a list; args must be list"])

  def call_rpc!(node, module, function, args) when is_atom(node) do
    result = :rpc.call(node, module, function, args)

    result =
      case result do
        {:badrpc, reason} ->
          throw_error!(
            :CODE_RPC_CALL_FAIL_ERROR,
            ["Call rpc fail"],
            node: node,
            module: module,
            function: function,
            args: args,
            reason: reason
          )

        {:error, _code, _data, _messages} = e ->
          throw_error!(e)

        {:ok, _result} ->
          result

        unexpected ->
          throw_error!(
            :CODE_RPC_CALL_RESULT_UNEXPECTED_ERROR,
            ["Send channel result unexpected error"],
            node: node,
            module: module,
            function: function,
            args: args,
            reason: unexpected
          )
      end

    result
  end

  def call_rpc!(remote_node_name_prefixes, module, function, args) when is_list(remote_node_name_prefixes) do
    {:ok, nodes} = Utils.get_nodes_list_by_prefixes!(remote_node_name_prefixes, Node.list())
    throw_if_empty!(nodes, :list, "Wrong nodes value")

    node = Enum.random(nodes)

    call_rpc!(node, module, function, args)
  end

  ##############################################################################
  @doc """

  """
  def call_local_or_rpc!(remote_node_name_prefixes, module, function, args) when is_list(remote_node_name_prefixes) do
    throw_if_empty!(remote_node_name_prefixes, :list, "Wrong remote_node_name_prefixes value")

    node = Node.self()
    {:ok, nodes} = Utils.get_nodes_list_by_prefixes!(remote_node_name_prefixes, [node])

    if nodes == [] do
      {:ok, nodes} = Utils.get_nodes_list_by_prefixes!(remote_node_name_prefixes, Node.list())
      throw_if_empty!(nodes, :list, "Wrong nodes value")

      node = Enum.random(nodes)

      call_rpc!(node, module, function, args)
    else
      apply(module, function, args)
    end
  end

  ##############################################################################
  ##############################################################################
end
