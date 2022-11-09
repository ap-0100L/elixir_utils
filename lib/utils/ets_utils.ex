defmodule EtsUtils do
  ##############################################################################
  ##############################################################################
  @moduledoc """

  """

  use Utils

  alias :ets, as: Ets

  ##############################################################################
  @doc """

  """
  def new!(table_name, opt) do
    result = catch_error!(Ets.new(table_name, opt), false)

    result =
      case result do
        {:error, _code, %{reason: reason} = _data, _messages} ->
          throw_error!(
            :CODE_NEW_TABLE_ETS_CAUGHT_ERROR,
            ["Error caught while process operation on ETS"],
            reason: reason,
            table_name: table_name,
            opt: opt
          )

        result ->
          result
      end

    {:ok, result}
  end

  ##############################################################################
  @doc """

  """
  def insert!(table_name, {key, _value} = record) do
    result = catch_error!(Ets.insert(table_name, record), false)

    result =
      case result do
        true ->
          :ok
        
        {:error, _code, %{reason: reason} = _data, _messages} ->
          throw_error!(
            :CODE_INSER_ETS_CAUGHT_ERROR,
            ["Error caught while process operation on ETS"],
            reason: reason,
            table_name: table_name,
            key: key
          )

        unexpected ->
          throw_error!(
            :CODE_INSER_ETS_CAUGHT_UNEXPECTED_ERROR,
            ["Unexpected error caught while process operation on ETS"],
            reason: unexpected,
            table_name: table_name,
            key: key
          )
      end

    result
  end

  ##############################################################################
  @doc """

  """
  def lookup!(table_name, key) do
    result = catch_error!(Ets.lookup(table_name, key), false)

    result =
      case result do
        [] ->
          :CODE_NOTHING_FOUND

        {:error, _code, %{reason: reason} = _data, _messages} ->
          throw_error!(
            :CODE_LOOKUP_ETS_CAUGHT_ERROR,
            ["Error caught while process operation on ETS"],
            reason: reason,
            table_name: table_name,
            key: key
          )

        result ->
          result
      end

    {:ok, result}
  end

  ##############################################################################
  @doc """

  """
  def lookup_one!(table_name, key) do
    result = catch_error!(Ets.lookup(table_name, key), false)

    result =
      case result do
        [] ->
          :CODE_NOTHING_FOUND

        {:error, _code, %{reason: reason} = _data, _messages} ->
          throw_error!(
            :CODE_LOOKUP_ETS_CAUGHT_ERROR,
            ["Error caught while process operation on ETS"],
            reason: reason,
            table_name: table_name,
            key: key
          )

        [result | _] ->
          result
      end

    {:ok, result}
  end
  
  ##############################################################################
  ##############################################################################
end
