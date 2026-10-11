import gjwt/key
import gleam/option
import gleam/result
import offstage
import offstage/offstage_core
import offstage/openapi/openapi
import suweal/auth
import suweal/identifier.{type Identifier}

/// A type representing the authentication information of a user.
pub type UserAuth(a) {
  UserAuth(id: Identifier(a))
}

/// Verify the given JWT token using the given key and the type_ to remap it.
fn verify_user_token(
  jwt: String,
  key: key.Key,
  type_: String,
  unauthorized: offstage.UnauthorizedResponse,
) -> Result(Identifier(a), offstage.WispResponse) {
  auth.verify_jwt(jwt, key)
  |> result.try(fn(payload) {
    identifier.from_string(payload.id)
    |> result.map(identifier.typed(_, type_))
  })
  |> result.map_error(fn(_) { unauthorized.apply("Invalid token") })
}

/// Get the identifier of the user from the authorization header and return an error if no token is
/// provided or if the token is invalid. The `key` is used to verify the JWT.
pub fn get_user_token(
  request: offstage.Request,
  type_: String,
  key: key.Key,
  unauthorized: offstage.UnauthorizedResponse,
) -> Result(Identifier(a), offstage.WispResponse) {
  use jwt <- result.try(offstage.require_authorization(request, unauthorized))

  verify_user_token(jwt, key, type_, unauthorized)
}

/// Add user authentication to the route with the name for the security scheme, 
/// the type of the identifier and the JWT key to use.
pub fn user_auth(
  spec: offstage.RouteSpecBuilder,
  name: String,
  type_: String,
  key: key.Key,
  next: fn(
    offstage.RouteSpecBuilder,
    offstage.RouteCapability(UserAuth(a), next),
  ) -> offstage.RouteSpec,
) -> offstage.RouteSpec {
  use spec, unauthorized <- offstage.unauthorized(spec)
  next(
    offstage_core.modify_spec(spec, fn(doc) {
      doc
      |> offstage_core.modify_operation(openapi.operation.security(_, name, []))
      |> offstage_core.modify_doc(fn(doc) {
        use security <- openapi.components.security_scheme(doc, name, "http")

        security
        |> openapi.security_scheme.scheme("bearer")
        |> openapi.security_scheme.bearer_format("JWT")
      })
    }),
    offstage_core.capability(fn(request) {
      use unauthorized <- unauthorized.get(request)
      use id <- result.try(get_user_token(request, type_, key, unauthorized))

      Ok(UserAuth(id: id))
    }),
  )
}

/// Add user authentication to the route with the name for the security scheme, 
/// the type of the identifier and the JWT key to use.
pub fn optional_user_auth(
  spec: offstage.RouteSpecBuilder,
  name: String,
  type_: String,
  key: key.Key,
  next: fn(
    offstage.RouteSpecBuilder,
    offstage.RouteCapability(option.Option(UserAuth(a)), next),
  ) -> offstage.RouteSpec,
) -> offstage.RouteSpec {
  use spec, unauthorized <- offstage.unauthorized(spec)
  next(
    offstage_core.modify_spec(spec, fn(doc) {
      doc
      |> offstage_core.modify_operation(openapi.operation.no_security)
      |> offstage_core.modify_operation(openapi.operation.security(_, name, []))
      |> offstage_core.modify_doc(fn(doc) {
        use security <- openapi.components.security_scheme(doc, name, "http")

        security
        |> openapi.security_scheme.scheme("bearer")
        |> openapi.security_scheme.bearer_format("JWT")
      })
    }),
    offstage_core.capability(fn(request) {
      use unauthorized <- unauthorized.get(request)
      case offstage_core.get_authorization(request) {
        Ok(jwt) ->
          case
            result.try(auth.verify_jwt(jwt, key), fn(payload) {
              identifier.from_string(payload.id)
            })
          {
            Ok(id) -> Ok(option.Some(UserAuth(id: identifier.typed(id, type_))))
            Error(_) -> Error(unauthorized.apply("Invalid token"))
          }
        Error(_) -> Ok(option.None)
      }
    }),
  )
}
