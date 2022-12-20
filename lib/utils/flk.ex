defmodule Flk do
  ##############################################################################
  ##############################################################################
  @moduledoc """

  """

  use Utils

  @iin_n5_values [0, 1, 2, 3]
  # @bin_n5_values [4, 5, 6]

  ##############################################################################
  @doc """

  """
  def check_iin!(iin)
      when is_nil(iin) or
             not is_bitstring(iin),
      do: UniError.raise_error!(:CODE_WRONG_FUNCTION_ARGUMENT_ERROR, ["iin cannot be nil; iin must be a string"])

  def check_iin!(iin) do
    origin_iin = iin
    error_messages = []

    length = String.length(iin)

    error_messages =
      if length == 12 do
        graphemes = String.graphemes(iin)

        iin =
          Enum.reduce(
            graphemes,
            [],
            fn g, accum ->
              n = UniError.rescue_error!(String.to_integer(g))

              :lists.append(accum, [n])
            end
          )

        n5 = Enum.at(iin, 4)

        error_messages =
          if n5 in @iin_n5_values do
            error_messages
          else
            error_messages ++ ["Position 5 must be one of #{inspect(@iin_n5_values)}"]
          end

#        {_, check_sum1} =
#          Enum.reduce(
#            iin,
#            {1, 0},
#            fn i, {x, accum} ->
#              n = Enum.at(iin, x - 1)
#
#              if x == 12 do
#                {x + 1, accum}
#              else
#                {x + 1, accum + x * n}
#              end
#            end
#          )
#
#        check_sum1 = rem(check_sum1, 11)

#        check_sum =
#          cond do
#            check_sum1 == 10 ->
#              {_, check_sum2} =
#                Enum.reduce(
#                  iin,
#                  {1, 0},
#                  fn i, {x, accum} ->
#                    n = Enum.at(iin, x - 1)
#
#                    if x >= 10 do
#                      {x + 1, accum}
#                    else
#                      {x + 1, accum + x * n}
#                    end
#                  end
#                )
#
#              check_sum2 = check_sum2 + 1 * Enum.at(iin, 9) + 2 * Enum.at(iin, 10)
#              rem(check_sum2, 11)
#
#            check_sum1 >= 0 and check_sum1 <= 9 ->
#              check_sum1
#
#            true ->
#              UniError.raise_error!(:CODE_FLK_IIN_ARITHMETIC_1_ERROR, ["Arithmetical error in check IIN algorithm"], iin: origin_iin, check_sum: check_sum1)
#          end

#        check_passed =
#          cond do
#            check_sum == 10 ->
#              false
#
#            check_sum >= 0 and check_sum <= 9 ->
#              Enum.at(iin, 11) == check_sum
#
#            true ->
#              UniError.raise_error!(:CODE_FLK_IIN_ARITHMETIC_2_ERROR, ["Arithmetical error in check IIN algorithm"], iin: origin_iin, check_sum: check_sum)
#          end

#        error_messages =
#          if check_passed do
#            error_messages
#          else
#            error_messages ++ ["IIN did not pass check"]
#          end

        error_messages
      else
        error_messages ++ ["IIN must have exactly 12 symbols"]
      end

    only_digits = Regex.match?(~r{\A\d*\z}, iin)

    error_messages =
      if only_digits do
        error_messages
      else
        error_messages ++ ["IIN must include only digits"]
      end

    if error_messages == [] do
      {:ok, :CODE_FLK_IIN_CORRECT}
    else
      UniError.raise_error!(:CODE_FLK_IIN_NOT_CORRECT_ERROR, error_messages, iin: origin_iin)
    end
  end

  ##############################################################################
  ##############################################################################
end
