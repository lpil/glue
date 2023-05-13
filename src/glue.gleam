import glance
import gleam/int
import gleam/list
import gleam/string
import gleam/result

pub type Error {
  ParseError(glance.Error)
  TypeNotFound(type_name: String)
  TypeIsNotEnum(type_name: String, variant: String)
}

/// Generate a function that lists all the variants of a given custom type.
///
/// Errors if: 
/// - The source is invalid.
/// - If type cannot be found.
/// - If the type has variants that are records and as such cannot be listed
///   without being given arguments.
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

/// Generate a function that lists all the variants of a given custom type.
///
/// Errors if: 
/// - The source is invalid.
/// - If type cannot be found.
/// - If the type has variants that are records and as such cannot be listed
///   without being given arguments.
pub fn generate_compare(src: String, type_name: String) -> Result(String, Error) {
  use module <- result.try(parse(src))
  use custom_type <- result.try(find_custom_type(module, type_name))
  use names <- result.try(enum_variants(custom_type))

  let add = fn(gen, name, i) {
    gen <> "\n      " <> name <> " -> " <> int.to_string(i)
  }

  let gen = "pub fn compare_" <> snake_case(type_name)
  let gen = gen <> "(a: " <> type_name <> ", b: " <> type_name <> ")"
  let gen = gen <> " -> Order {\n"
  let gen = gen <> "  let to_int = fn(x) {\n"
  let gen = gen <> "    case x {"
  let gen = list.index_fold(names, gen, add) <> "\n"
  let gen = gen <> "    }\n"
  let gen = gen <> "  }\n"
  let gen = gen <> "  int.compare(to_int(a), to_int(b))\n"
  let gen = gen <> "}\n"

  Ok(gen)
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
