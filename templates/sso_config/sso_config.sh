#   Enable o OIDC

Vault auth enable oidc

#	Configure OIDC

vault write auth/oidc/config \
oidc_discovery_url="" \ # (string: <optional>) - The OIDC Discovery URL, without any .well-known component (base path). Cannot be used with "jwks_url" or "jwt_validation_pubkeys".
oidc_client_id="" \ # (string: <optional>) - The OAuth Client ID from the provider for OIDC roles.
oidc_client_secret="" \ # (string: <optional>) - The OAuth Client Secret from the provider for OIDC roles.
oidc_scopes="email" \ # (list: <optional>) - If set, a list of OIDC scopes to be used with an OIDC role. The standard scope "openid" is automatically included and need not be specified.
default_role="your_role" # (string: <optional>) - The default role to use if none is provided during login.

#	Create Policy Default

vault write auth/oidc/role/your_role \
user_claim="email" \  # (string: <required>) - The claim to use to uniquely identify the user; this will be used as the name for the Identity entity alias created due to a successful login. The claim value must be a string. is possible name, sub and e-mail
oidc_scopes="email" \ # list: <optional>) - If set, a list of OIDC scopes to be used with an OIDC role. The standard scope "openid" is automatically included and need not be specified.
bound_audiences="oidc_client_id" \ # (array: <optional>) - List of aud claims to match against. Any match is sufficient. Required for "jwt" roles, optional for "oidc" roles.
allowed_redirect_uris="$VAULT_ADDR/ui/vault/auth/oidc/oidc/callback" \ # (list: <required>) - The list of allowed values for redirect_uri during OIDC logins. Used for UI
allowed_redirect_uris="http://localhost:8250/oidc/callback" \ # (list: <required>) - The list of allowed values for redirect_uri during OIDC logins. User for CLI
policies=admin # This example attaches an existing policy called "admin" or (Your role)