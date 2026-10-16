import gleam/list
import gleam/option.{type Option, None}
import offstage/dynamic/serialize
import offstage/dynamic/spec
import offstage/openapi/openapi_type.{type OpenAPIType}
import offstage_suweal/identifier.{type Identifier}
import suweal/record

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                   Export from surreal/record                                  //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

/// Redefined from surreal/record
pub type Record(a) =
  record.Record(a)

/// Redefined from surreal/record
pub const create_record = record.Record

/// Redefined from surreal/record
pub const create_id = record.Id

/// Redefined from surreal/record
pub const to_json = record.to_json

/// Redefined from surreal/record
pub const to_surql = record.to_surql

/// Redefined from surreal/record
pub const decoder = record.decoder

/// Redefined from surreal/record
pub const typed_decoder = record.typed_decoder

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                        Extra Functions                                        //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

/// The OpenAPI specification for the `Record` type.
fn openapi_spec(
  type_: Option(String),
  type_spec: fn() -> OpenAPIType,
) -> OpenAPIType {
  openapi_type.one_of([
    identifier.openapi_spec(type_)
      |> openapi_type.title("Identifier"),
    type_spec()
      |> openapi_type.title("Record"),
  ])
}

pub fn serializer(
  serializer: serialize.Serializer(a),
  id: fn(a) -> Identifier(a),
) -> serialize.Serializer(Record(a)) {
  serialize.Serializer(
    decoder: record.decoder(serializer.decoder, id),
    encoder: fn(record) {
      case record {
        record.Id(id) -> spec.string(identifier.to_string(id))
        record.Record(_, value) -> serializer.encoder(value)
      }
    },
    doc: fn() { openapi_spec(None, serializer.doc) },
  )
}

pub fn typed_serializer(
  serializer: serialize.Serializer(a),
  id: fn(a) -> Identifier(a),
  types: List(String),
) -> serialize.Serializer(Record(a)) {
  serialize.Serializer(
    decoder: record.typed_decoder(serializer.decoder, id, types),
    encoder: fn(record) {
      case record {
        record.Id(id) -> {
          case types {
            [first, ..] -> identifier.typed(id, first)
            _ -> id
          }
          |> identifier.to_string
          |> spec.string()
        }
        record.Record(_, value) -> serializer.encoder(value)
      }
    },
    doc: fn() {
      openapi_spec(option.from_result(list.first(types)), serializer.doc)
    },
  )
}
