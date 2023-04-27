# defimpl Jason.Encoder, for: Any do
#  defmacro __deriving__(module, struct, opts) do
#    fields = fields_to_encode(struct, opts)
#    kv = Enum.map(fields, &{&1, generated_var(&1, __MODULE__)})
#    escape = quote(do: escape)
#    encode_map = quote(do: encode_map)
#    encode_args = [escape, encode_map]
#    kv_iodata = Jason.Codegen.build_kv_iodata(kv, encode_args)
#
#    quote do
#      defimpl Jason.Encoder, for: unquote(module) do
#        require Jason.Helpers
#
#        def encode(%{unquote_splicing(kv)}, {unquote(escape), unquote(encode_map)}) do
#          unquote(kv_iodata)
#        end
#      end
#    end
#  end
#
#  # The same as Macro.var/2 except it sets generated: true
#  defp generated_var(name, context) do
#    {name, [generated: true], context}
#  end
#
#  def encode(%_{} = struct, _opts) do
#    raise Protocol.UndefinedError,
#          protocol: @protocol,
#          value: struct,
#          description: """
#          Jason.Encoder protocol must always be explicitly implemented.
#
#          If you own the struct, you can derive the implementation specifying \
#          which fields should be encoded to JSON:
#
#              @derive {Jason.Encoder, only: [....]}
#              defstruct ...
#
#          It is also possible to encode all fields, although this should be \
#          used carefully to avoid accidentally leaking private information \
#          when new fields are added:
#
#              @derive Jason.Encoder
#              defstruct ...
#
#          Finally, if you don't own the struct you want to encode to JSON, \
#          you may use Protocol.derive/3 placed outside of any module:
#
#              Protocol.derive(Jason.Encoder, NameOfTheStruct, only: [...])
#              Protocol.derive(Jason.Encoder, NameOfTheStruct)
#          """
#  end
#
#  def encode(value, opts) do
#    #    raise Protocol.UndefinedError,
#    #      protocol: @protocol,
#    #      value: value,
#    #      description: "Jason.Encoder protocol must always be explicitly implemented"
#
#    value
#    |> inspect()
#    |> Jason.Encoder.encode(opts)
#  end
#
#  defp fields_to_encode(struct, opts) do
#    fields = Map.keys(struct)
#
#    cond do
#      only = Keyword.get(opts, :only) ->
#        case only -- fields do
#          [] ->
#            only
#
#          error_keys ->
#            raise ArgumentError,
#                  "`:only` specified keys (#{inspect(error_keys)}) that are not defined in defstruct: " <>
#                  "#{inspect(fields -- [:__struct__])}"
#
#        end
#
#      except = Keyword.get(opts, :except) ->
#        case except -- fields do
#          [] ->
#            fields -- [:__struct__ | except]
#
#          error_keys ->
#            raise ArgumentError,
#                  "`:except` specified keys (#{inspect(error_keys)}) that are not defined in defstruct: " <>
#                  "#{inspect(fields -- [:__struct__])}"
#
#        end
#
#      true ->
#        fields -- [:__struct__]
#    end
#  end
# end
