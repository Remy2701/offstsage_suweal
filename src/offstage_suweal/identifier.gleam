import gleam/list
import gleam/option.{type Option, None, Some}
import offstage/dynamic/serialize
import offstage/dynamic/spec
import offstage/openapi/openapi_type.{type OpenAPIType}
import suweal/identifier

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                Export from surreal/identifier                                 //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

/// Redefined from surreal/identifier
pub type Identifier(a) =
  identifier.Identifier(a)

/// Redefined from surreal/identifier
pub const create = identifier.Identifier

/// Redefined from surreal/identifier
pub const from_string = identifier.from_string

/// Redefined from surreal/identifier
pub const to_string = identifier.to_string

/// Redefined from surreal/identifier
pub const typed = identifier.typed

/// Redefined from surreal/identifier
pub const untyped = identifier.untyped

/// Redefined from surreal/identifier
pub const decoder = identifier.decoder

/// Redefined from surreal/identifier
pub const typed_decoder = identifier.typed_decoder

/// Redefined from surreal/identifier
pub const compare = identifier.compare

/// Redefined from surreal/identifier
pub const generate = identifier.generate

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                        Extra Functions                                        //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

/// The OpenAPI specification for the `Identifier` type.
pub fn openapi_spec(type_: Option(String)) -> OpenAPIType {
  openapi_type.string()
  |> openapi_type.format("identifier")
  |> openapi_type.pattern("^(?:[A-Za-z0-9_]{1,20}:)?[A-Za-z0-9]{1,20}$")
  |> openapi_type.example(
    type_
    |> option.or(Some("example"))
    |> identifier.generate
    |> identifier.to_string
    |> spec.string,
  )
}

pub fn serializer() -> serialize.Serializer(Identifier(a)) {
  serialize.Serializer(
    decoder: identifier.decoder(),
    encoder: fn(id) { spec.string(identifier.to_string(id)) },
    doc: fn() { openapi_spec(None) },
  )
}

pub fn typed_serializer(
  types: List(String),
) -> serialize.Serializer(Identifier(a)) {
  serialize.Serializer(
    decoder: identifier.typed_decoder(types),
    encoder: fn(id) {
      case types {
        [first, ..] -> identifier.typed(id, first)
        _ -> id
      }
      |> identifier.to_string()
      |> spec.string()
    },
    doc: fn() { list.first(types) |> option.from_result |> openapi_spec() },
  )
}
