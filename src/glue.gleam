import glance
import gleam/list
import gleam/result
import gleam/string
import glue/internal/code

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
  use names <- result.map(enum_variants(custom_type))

  code.Function(
    name: snake_case(type_name) <> "_list",
    parameters: [],
    return: "List(" <> type_name <> ")",
    body: [code.Expression(code.List(list.map(names, code.Variable)))],
  )
  |> code.function_to_string
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
  use names <- result.map(enum_variants(custom_type))

  let clause = fn(name, i) {
    code.Clause(code.Constructor(name, []), code.Int(i))
  }

  code.Function(
    name: "compare_" <> snake_case(type_name),
    parameters: [#("a", type_name), #("b", type_name)],
    return: "Order",
    body: [
      code.Let(
        "to_int",
        code.Fn(["x"], [
          code.Expression(code.Case(
            code.Variable("x"),
            list.index_map(names, clause),
          )),
        ]),
      ),
      code.Expression(
        code.Call(code.Variable("int.compare"), [
          code.Call(code.Variable("to_int"), [code.Variable("a")]),
          code.Call(code.Variable("to_int"), [code.Variable("b")]),
        ]),
      ),
    ],
  )
  |> code.function_to_string
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
  |> list.find(fn(t) { t.definition.name == type_name })
  |> result.map(fn(t) { t.definition })
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
