defimpl Jason.Encoder,
  for: [
    Mint.TransportError,
    ArgumentError,
    ArithmeticError,
    BadArityError,
    BadBooleanError,
    BadFunctionError,
    BadMapError,
    BadStructError,
    CaseClauseError,
    Code.LoadError,
    CompileError,
    CondClauseError,
    Enum.EmptyError,
    Enum.OutOfBoundsError,
    ErlangError,
    File.CopyError,
    File.Error,
    File.LinkError,
    File.RenameError,
    FunctionClauseError,
    IO.StreamError,
    Inspect.Error,
    Kernel.ErrorHandler,
    KeyError,
    MatchError,
    Module.Types.Error,
    OptionParser.ParseError,
    Protocol.UndefinedError,
    Regex.CompileError,
    RuntimeError,
    SyntaxError,
    SystemLimitError,
    TokenMissingError,
    TryClauseError,
    URI.Error,
    UndefinedFunctionError,
    UnicodeConversionError,
    Version.InvalidRequirementError,
    Version.InvalidVersionError,
    WithClauseError,
    Jason.Encoder.IO.StreamError,
    Jason.Encoder.URI.Error,
    Jason.Encoder.KeyError,
    Jason.Encoder.File.Error,
    Jason.Encoder.SystemLimitError,
    Jason.Encoder.BadMapError,
    Jason.Encoder.File.LinkError,
    Jason.Encoder.Version.InvalidVersionError,
    Jason.Encoder.OptionParser.ParseError,
    Jason.Encoder.Version.InvalidRequirementError,
    Jason.Encoder.TryClauseError,
    Jason.Encoder.BadFunctionError,
    Jason.Encoder.BadStructError,
    Jason.Encoder.Enum.OutOfBoundsError,
    Jason.Encoder.BadBooleanError,
    Jason.Encoder.File.CopyError,
    Jason.Encoder.UndefinedFunctionError,
    Jason.Encoder.Kernel.ErrorHandler,
    Jason.Encoder.Module.Types.Error,
    Jason.Encoder.CaseClauseError,
    Jason.Encoder.Enum.EmptyError,
    Jason.Encoder.WithClauseError,
    Jason.Encoder.Mint.TransportError,
    Jason.Encoder.SyntaxError,
    Jason.Encoder.CondClauseError,
    Jason.Encoder.ArgumentError,
    Jason.Encoder.MatchError,
    Jason.Encoder.CompileError,
    Jason.Encoder.BadArityError,
    Jason.Encoder.TokenMissingError,
    Jason.Encoder.ArithmeticError,
    Jason.Encoder.Regex.CompileError,
    Jason.Encoder.RuntimeError,
    Jason.Encoder.UnicodeConversionError,
    Jason.Encoder.FunctionClauseError,
    Jason.Encoder.Code.LoadError,
    Jason.Encoder.Inspect.Error,
    Jason.Encoder.Protocol.UndefinedError,
    Jason.Encoder.File.RenameError,
    Jason.Encoder.ErlangError,
    Jason.EncodeError,
    Jason.DecodeError,
    Phoenix.LiveView.HTMLTokenizer.ParseError,
    Plug.Conn.NotSentError,
    Plug.CSRFProtection.InvalidCSRFTokenError,
    Plug.Parsers.ParseError,
    Plug.Conn.AlreadySentError,
    Plug.Conn.WrapperError,
    Plug.BadRequestError,
    Plug.Parsers.UnsupportedMediaTypeError,
    Plug.Router.MalformedURIError,
    Plug.Static.InvalidPathError,
    Plug.Conn.InvalidHeaderError,
    Plug.Conn.CookieOverflowError,
    Plug.CSRFProtection.InvalidCrossOriginRequestError,
    Plug.UploadError,
    Plug.Router.InvalidSpecError,
    Plug.Parsers.RequestTooLargeError,
    Plug.ErrorHandler,
    Plug.TimeoutError,
    Plug.Parsers.BadEncodingError,
    Plug.Conn.InvalidQueryError,
    Phoenix.Router.MalformedURIError,
    Phoenix.Router.NoRouteError,
    Plug.Exception.Phoenix.ActionClauseError,
    Phoenix.MissingParamError,
    Phoenix.NotAcceptableError,
    Phoenix.ActionClauseError,
    Phoenix.Endpoint.RenderErrors,
    Phoenix.Socket.InvalidMessageError,
    Finch.Error,
    NimbleOptions.ValidationError,
    Gettext.MissingBindingsError,
    Gettext.Error,
    Gettext.PO.SyntaxError,
    Gettext.Plural.UnknownLocaleError,
    Gettext.PluralFormError,
    DBConnection.TransactionError,
    DBConnection.OwnershipError,
    DBConnection.ConnectionError,
    DBConnection.EncodeError,
    Mint.HTTPError,
    Mint.TransportError,
    Decimal.Error,
    RestApi.ErrorHelpers,
    RestApi.ErrorView,
    Ecto.ConstraintError,
    Ecto.InvalidChangesetError,
    Ecto.MigrationError,
    Ecto.NoPrimaryKeyValueError,
    Ecto.ChangeError,
    Ecto.InvalidURLError,
    Ecto.StaleEntryError,
    Ecto.Query.CompileError,
    Ecto.NoResultsError,
    Ecto.QueryError,
    Ecto.CastError,
    Ecto.SubQueryError,
    Ecto.NoPrimaryKeyFieldError,
    Ecto.Query.CastError,
    Ecto.MultiplePrimaryKeyError,
    Ecto.MultipleResultsError,
    #
    Ecto.Changeset,
    Ecto.Schema.Metadata,
    #
    Error,
    Phoenix.PubSub.BroadcastError,
    Phoenix.Template.UndefinedError,
    Plug.Exception.Ecto.Query.CastError,
    Phoenix.Ecto.PendingMigrationError,
    Plug.Exception.Ecto.SubQueryError,
    Plug.Exception.Ecto.NoResultsError,
    Plug.Exception.Phoenix.Ecto.StorageNotCreatedError,
    Plug.Exception.Phoenix.Ecto.PendingMigrationError,
    Plug.Exception.Ecto.CastError,
    Phoenix.Ecto.StorageNotCreatedError,
    Plug.Exception.Ecto.StaleEntryError,
    Swoosh.AttachmentContentError,
    Swoosh.DeliveryError,
    Postgrex.QueryError,
    Postgrex.Error
  ] do
  ##############################################################################
  ##############################################################################
  @moduledoc """

  """

  ##############################################################################
  @doc """

  """
  @impl Jason.Encoder
  def encode(%struct{} = value, options) do
    value
    |> Map.from_struct()
    |> Map.put(:__struct__, struct)
    |> Jason.Encode.map(options)
  end

  ##############################################################################
  ##############################################################################
end
