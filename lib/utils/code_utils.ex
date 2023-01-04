defmodule CodeUtils do
  ##############################################################################
  ##############################################################################
  @moduledoc """
  ## Module
  """

  require Logger
  require UniError

  alias UniError, as: UniError

  ##############################################################################
  @doc """
  ## Function
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
  @doc """
  ## Function
  """
  def string_to_code!(str) do
    if is_nil(str) do
      {:ok, nil}
    else
      code_str = "CodeUtils.string_clause_to_code!(#{inspect(str)})\n"

      {result, _bindings} = Code.eval_string(code_str, [], __ENV__)

      result
    end
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def create_module!(module, module_text, env \\ nil)

  def create_module!(module, module_text, _env)
      when not is_atom(module) or not is_bitstring(module_text),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["module, module_text cannot be nil; module must be an atom; module_text must be a string"])

  def create_module!(module, module_text, env) do
    UniError.rescue_error!(
      (
        module_contents = Code.string_to_quoted!(module_text)

        env = env || Macro.Env.location(__ENV__)
        Module.create(module, module_contents, env)

        {:ok, module}
      ),
      true
    )
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def ensure_compiled?(module)
      when not is_atom(module),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["module cannot be nil; module must be an atom"])

  def ensure_compiled?(module) do
    result = UniError.rescue_error!(Code.ensure_compiled(module))

    case result do
      {:error, _} ->
        false

      {:module, _} ->
        true

      unexpected ->
        UniError.raise_error!(:CODE_ENSURE_COMPILED_UNEXPECTED_ERROR, ["Cannot ensure module compiled"], previous: unexpected, module: module)
    end
  end

  ##############################################################################
  ##############################################################################
end
