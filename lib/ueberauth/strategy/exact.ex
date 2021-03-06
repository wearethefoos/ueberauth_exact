defmodule Ueberauth.Strategy.Exact do
  @moduledoc """
  Provides an Ueberauth strategy for authenticating with Exact Online.

  ### Setup

  Create an application in Exact for you to use.
  Register a new application at: [Exact App Center](https://apps.exactonline.com)
  and get the `client_id` and `client_secret`.

  Include the provider in your configuration for Ueberauth:

      config :ueberauth, Ueberauth,
        providers: [
          exact: { Ueberauth.Strategy.Exact, [] }
        ]

  Then include the configuration for Exact Online:

      config :ueberauth, Ueberauth.Strategy.Exact.OAuth,
        client_id: System.get_env("EXACT_CLIENT_ID"),
        client_secret: System.get_env("EXACT_CLIENT_SECRET"),
        redirect_uri: "https://gqgh.localtunnel.me/auth/exact/callback" # <-- note that Exact needs HTTPS for a callback URL scheme, even in test apps.

  If you haven't already, create a pipeline and setup routes for your callback handler

      pipeline :auth do
        Ueberauth.plug "/auth"
      end
      scope "/auth" do
        pipe_through [:browser, :auth]
        get "/:provider/callback", AuthController, :callback
      end

  Create an endpoint for the callback where you will handle the
  `Ueberauth.Auth` struct:

      defmodule MyApp.AuthController do
        use MyApp.Web, :controller
        def callback_phase(%{ assigns: %{ ueberauth_failure: fails } } = conn, _params) do
          # do things with the failure
        end
        def callback_phase(%{ assigns: %{ ueberauth_auth: auth } } = conn, params) do
          # do things with the auth
        end
      end

  You can edit the behaviour of the Strategy by including some options when you
  register your provider.

  To set the `uid_field`:

      config :ueberauth, Ueberauth,
        providers: [
          exact: { Ueberauth.Strategy.Exact, [uid_field: :Email] } # Default is `:UserID`, a string UUID."
        ]

  ## Usage

  Once you obtained a token, you may use the OAuth client directly:

      Ueberauth.Strategy.Exact.OAuth.get("/current/Me")

  See the [Exact Online API Docs](https://start.exactonline.nl/docs/HlpRestAPIResources.aspx) for more information. Note that the provided client knows about the `/api/v1` prefix already.
  """
  use Ueberauth.Strategy,
    uid_field: :UserID,
    default_scope: "",
    oauth2_module: Ueberauth.Strategy.Exact.OAuth

  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra
  alias Ueberauth.Auth.Info

  alias Ueberauth.Strategy.Exact

  @doc """
  Handles the initial redirect to the exact authentication page.
  To customize the scope (permissions) that are requested by exact include
  them as part of your url:
      "/auth/exact"
  You can also include a `:state` param that exact will return to you.
  """
  def handle_request!(conn) do
    send_redirect_uri = Keyword.get(options(conn), :send_redirect_uri, true)

    opts =
      if send_redirect_uri do
        [redirect_uri: callback_url(conn)]
      else
        []
      end

    opts =
      if conn.params["state"], do: Keyword.put(opts, :state, conn.params["state"]), else: opts

    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  @doc """
  Handles the callback from Exact Online.
  When there is a failure from Exact the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from Exact is
  returned in the `Ueberauth.Auth` struct.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    module = option(conn, :oauth2_module)
    token = apply(module, :get_token!, [[code: code]])

    if token.access_token == nil do
      set_errors!(conn, [
        error(token.other_params["error"], token.other_params["error_description"])
      ])
    else
      fetch_user(conn, token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw Exact Online
  response around during the callback.
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:exact_user, nil)
    |> put_private(:exact_token, nil)
  end

  @doc """
  Fetches the `:uid` field from the Exact Online response.
  This defaults to the option `:uid_field` which in-turn defaults to `:id`
  """
  def uid(conn) do
    conn |> option(:uid_field) |> to_string() |> fetch_uid(conn)
  end

  @doc """
  Includes the credentials from the Exact Online response.
  """
  def credentials(conn) do
    token = conn.private.exact_token

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: true
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth`
  struct.
  """
  def info(conn) do
    user = conn.private.exact_user

    %Info{
      name: user["FullName"],
      nickname: user["UserName"] || user["FirstName"],
      email: user["Email"],
      image: user["PictureUrl"]
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the Exact Online
  callback.
  """
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.exact_token,
        user: conn.private.exact_user
      }
    }
  end

  defp fetch_uid(field, conn) do
    conn.private.exact_user[field]
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :exact_token, token)

    # Will be better with Elixir 1.3 with/else
    case Exact.OAuth.get(token, "/current/Me") do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])

      {:ok, %OAuth2.Response{status_code: status_code, body: user}}
      when status_code in 200..399 ->
        user_data = user["d"]["results"] |> List.first()
        put_private(conn, :exact_user, user_data)

      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])

      {:error, %OAuth2.Response{body: %{"message" => reason}}} ->
        set_errors!(conn, [error("OAuth2", reason)])

      {:error, _} ->
        set_errors!(conn, [error("OAuth2", "uknown error")])
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end
end
