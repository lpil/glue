import glance
import gleam/list
import gleam/string
import gleam/result

pub type Error {
  ParseError(glance.Error)
  TypeNotFound(type_name: String)
  TypeIsNotEnum(type_name: String, variant: String)
}

pub fn generate_list_variants(
  src: String,
  type_name: String,
) -> Result(String, Error) {
  use module <- result.try(parse(src))
  use custom_type <- result.try(find_custom_type(module, type_name))
  use names <- result.try(enum_variants(custom_type))
  let header =
    "pub fn " <> snake_case(type_name) <> "_list() -> List(" <> type_name <> ") {\n"
  let body = "  [" <> string.join(names, ", ") <> "]\n"
  let end = "}\n"
  Ok(header <> body <> end)
}

// Get the names of the variants of a custom type, returning an error if any of
// them have fields.
fn enum_variants(custom_type: glance.CustomType) -> Result(List(String), Error) {
  custom_type.variants
  |> list.try_map(fn(variant) {
    case variant.fields {
      [] -> Ok(variant.name)
      _ -> Error(TypeIsNotEnum(custom_type.name, variant.name))
    }
  })
}

fn parse(src: String) -> Result(glance.Module, Error) {
  glance.module(src)
  |> result.map_error(ParseError)
}

fn find_custom_type(
  module: glance.Module,
  type_name: String,
) -> Result(glance.CustomType, Error) {
  module.custom_types
  |> list.find(fn(t) { t.name == type_name })
  |> result.replace_error(TypeNotFound(type_name))
}

fn snake_case(name: String) -> String {
  let add = fn(acc, grapheme) {
    let lower = string.lowercase(grapheme)
    case grapheme == lower {
      False if acc != "" -> acc <> "_" <> lower
      False -> lower
      True -> acc <> lower
    }
  }
  name
  |> string.to_graphemes
  |> list.fold("", add)
}
