defmodule EtsUtils do
  ##############################################################################
  ##############################################################################
  @moduledoc """
  ## Module
  """

  use Utils

  alias :ets, as: Ets

  ##############################################################################
  @doc """
  ## Function
  """
  def new!(table_name, opt) do
    result = UniError.rescue_error!(Ets.new(table_name, opt))

    {:ok, result}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def insert(table_name, {key, _value} = record) do
    result = UniError.rescue_error!(Ets.insert(table_name, record))

    result =
      case result do
        true ->
          :ok

        unexpected ->
          UniError.raise_error!(
            :INSER_ETS_CAUGHT_UNEXPECTED_ERROR,
            ["Unexpected error caught while process operation on ETS"],
            previous: unexpected,
            table_name: table_name,
            key: key
          )
      end

    result
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def lookup!(table_name, key) do
    result = UniError.rescue_error!(Ets.lookup(table_name, key))

    result =
      case result do
        [] ->
          :NOT_FOUND

        result ->
          result
      end

    {:ok, result}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def tab2list!(table_name) do
    result = UniError.rescue_error!(Ets.tab2list(table_name))

    result =
      case result do
        [] ->
          :NOT_FOUND

        result ->
          result
      end

    {:ok, result}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def lookup_one!(table_name, key) do
    result = UniError.rescue_error!(Ets.lookup(table_name, key))

    result =
      case result do
        [] ->
          :NOT_FOUND

        [result | _] ->
          result
      end

    {:ok, result}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def delete!(table_name, key) do
    result = UniError.rescue_error!(Ets.delete(table_name, key))

    result =
      case result do
        true ->
          :ok

        unexpected ->
          UniError.raise_error!(
            :INSER_ETS_CAUGHT_UNEXPECTED_ERROR,
            ["Unexpected error caught while process operation on ETS"],
            previous: unexpected,
            table_name: table_name,
            key: key
          )
      end

    result
  end

  ##############################################################################
  ##############################################################################
end
