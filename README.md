# Ueberauth Exact

> Ueberauth Strategy for Exact Online.

## Installation

The package can be installed by adding `ueberauth_exact` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ueberauth_exact, "~> 0.1.1"}
  ]
end
```

Add the Strategy to your Ueberauth strategies:

```elixir
# config/config.exs
config :ueberauth, Ueberauth,
  providers: [
    exact: {Ueberauth.Strategy.Exact, []},
    # github: {Ueberauth.Strategy.Github, []}
  ]
```

## Configuration

Start by registering your own Exact App in the [App Centre](https://support.exactonline.com/community/s/knowledge-base#All-All-DNO-Process-appcenter-eol-appcenter-dev-registerapp-p).

> Take note of the Client ID and Client Secret, as you will need them for the next steps.

### Development

Configure your dev env:

```elixir
# config/dev.exs
config :ueberauth, Ueberauth.Strategy.Exact.OAuth,
  client_id: "2309840238-324g-oehu-,leour-230984092380",
  client_secret: "HESNTusoer",
  redirect_uri: "https://gqgh.localtunnel.me/auth/exact/callback" # <-- note that Exact needs HTTPS for a callback URL scheme, even in test apps.
```

### Production

Configure your prod env:

```elixir
# config/prod.exs
config :ueberauth, Ueberauth.Strategy.Exact.OAuth,
  client_id: System.get_env("EXACT_CLIENT_ID"),
  client_secret: System.get_env("EXACT_CLIENT_SECRET"),
  redirect_uri: "https://example.com/auth/exact/callback" # <-- note that Exact needs HTTPS for a callback URL scheme, even in test apps.
```

## Usage

Once you obtained a token, you may use the OAuth client directly:

```elixir
Ueberauth.Strategy.Exact.OAuth.get("/current/Me")
```

See the [Exact Online API Docs](https://start.exactonline.nl/docs/HlpRestAPIResources.aspx) for more information. Note that the provided client knows about the `/api/v1` prefix already.

## Further Docs

Check out the [documentation](https://hexdocs.pm/ueberauth_exact).

## Disclaimer

This library is in no way related to or supported by the company or team behind Exact Online.
