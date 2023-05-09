defmodule Kafka.ProducerService do
  ##############################################################################
  ##############################################################################
  @moduledoc """
  # KafkaProducerService

  """

  use Utils

  ##############################################################################
  @doc """
  ## Function
  """
  def send_message!(message)
      when not is_map(message) and not is_list(message),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["message cannot be nil; message must be a list or map"])

  def send_message!(%{channel_id: channel_id} = message) when not is_list(message) do
    {:ok, payload} = JsonConverter.encode!(message)

    :ok = send_to_topic!(channel_id, payload)

    {:ok, message}
  end

  def send_message!(messages) when is_list(messages) do
    messages =
      Enum.reduce(
        messages,
        [],
        fn message, accum ->
          {:ok, message} = send_message!(message)

          accum ++ [message]
        end
      )

    {:ok, messages}
  end

  ##############################################################################
  @doc """
  ## Function
  """
  def send_to_topic!(topic, payload) when not is_bitstring(topic) or not is_bitstring(payload),
    do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["topic, payload must be bitstring"])

  def send_to_topic!(topic, payload) do
    # FIXME: U should choose partition_id
    partition_id = :rand.uniform(5) - 1
    # TODO: Please do it with :brod.produce_sync_offset(Client, Topic, Partition, Key, Value) it will return offset
    Kaffe.Producer.produce_sync(topic, partition_id, topic, payload)
    |> case do
      :ok ->
        :ok

      {:error, reason} ->
        UniError.raise_error!(
          :CODE_KAFKA_PRODUCE_ERROR,
          ["Can not send to Kafka"],
          previous: reason,
          topic: topic,
          partition_id: partition_id
        )

      unexpected ->
        UniError.raise_error!(
          :CODE_KAFKA_PRODUCE_UNEXPECTED_ERROR,
          ["Can not send to Kafka"],
          previous: unexpected,
          topic: topic,
          partition_id: partition_id
        )
    end
  end

  ##############################################################################
  ##############################################################################
end
