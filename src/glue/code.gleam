import gleam/int
import gleam/list
import gleam/string

pub type Function {
  Function(
    name: String,
    parameters: List(#(String, String)),
    return: String,
    body: List(Statement),
  )
}

pub type Statement {
  Expression(Expression)
  Let(String, Expression)
}

pub type Expression {
  Variable(String)
  Fn(parameters: List(String), body: List(Statement))
  Int(Int)
  Call(function: Expression, arguments: List(Expression))
  Case(Expression, List(Clause))
}

pub type Clause {
  Clause(pattern: Pattern, body: Expression)
}

pub type Pattern {
  Constructor(String, List(Pattern))
}

pub fn function_to_string(function: Function) -> String {
  Generator("", 0)
  |> write("pub fn ")
  |> write(function.name)
  |> write("(")
  |> write_parameters(function.parameters)
  |> write(") -> ")
  |> write(function.return)
  |> write(" {")
  |> newline
  |> indent_up
  |> write_statements(function.body)
  |> indent_down
  |> write("}")
  |> newline
  |> finish
}

fn write_statements(gen: Generator, statements: List(Statement)) -> Generator {
  list.fold(
    statements,
    gen,
    fn(gen, statement) {
      gen
      |> indent
      |> write_statement(statement)
      |> newline
    },
  )
}

fn write_statement(gen: Generator, statement: Statement) -> Generator {
  case statement {
    Let(name, expression) ->
      gen
      |> write("let ")
      |> write(name)
      |> write(" = ")
      |> write_expression(expression)
    Expression(expression) ->
      gen
      |> write_expression(expression)
  }
}

fn write_fn(
  gen: Generator,
  parameters: List(String),
  body: List(Statement),
) -> Generator {
  let write_parameter = fn(gen, parameter, i) {
    case i {
      0 -> gen
      _ -> write(gen, ", ")
    }
    |> write(parameter)
  }
  gen
  |> write("fn(")
  |> list.index_fold(parameters, _, write_parameter)
  |> write(") {")
  |> newline
  |> indent_up
  |> write_statements(body)
  |> indent_down
  |> indent
  |> write("}")
}

fn write_argument(gen: Generator, argument: Expression, i: Int) -> Generator {
  case i {
    0 -> gen
    _ -> write(gen, ", ")
  }
  |> write_expression(argument)
}

fn write_pattern_argument(
  gen: Generator,
  argument: Pattern,
  i: Int,
) -> Generator {
  case i {
    0 -> gen
    _ -> write(gen, ", ")
  }
  |> write_pattern(argument)
}

fn write_call(
  gen: Generator,
  function: Expression,
  arguments: List(Expression),
) -> Generator {
  gen
  |> write_expression(function)
  |> write("(")
  |> list.index_fold(arguments, _, write_argument)
  |> write(")")
}

fn write_case(
  gen: Generator,
  expression: Expression,
  clauses: List(Clause),
) -> Generator {
  gen
  |> write("case ")
  |> write_expression(expression)
  |> write(" {")
  |> newline
  |> indent_up
  |> list.fold(clauses, _, write_clause)
  |> indent_down
  |> indent
  |> write("}")
}

fn write_clause(gen: Generator, clause: Clause) -> Generator {
  gen
  |> indent
  |> write_pattern(clause.pattern)
  |> write(" -> ")
  |> indent_up
  |> write_expression(clause.body)
  |> indent_down
  |> newline
}

fn write_pattern(gen: Generator, pattern: Pattern) -> Generator {
  case pattern {
    Constructor(name, []) -> write(gen, name)
    Constructor(name, patterns) ->
      write_constructor_pattern(gen, name, patterns)
  }
}

fn write_constructor_pattern(
  gen: Generator,
  name: String,
  patterns: List(Pattern),
) -> Generator {
  let gen = write(gen, name)
  case patterns {
    [] -> gen
    _ ->
      gen
      |> write("(")
      |> list.index_fold(patterns, _, write_pattern_argument)
      |> write(")")
  }
}

fn write_expression(gen: Generator, expression: Expression) -> Generator {
  case expression {
    Variable(name) -> write(gen, name)
    Int(i) -> write(gen, int.to_string(i))
    Fn(parameters, body) -> write_fn(gen, parameters, body)
    Call(function, arguments) -> write_call(gen, function, arguments)
    Case(expression, clauses) -> write_case(gen, expression, clauses)
  }
}

fn write_parameters(
  gen: Generator,
  parameters: List(#(String, String)),
) -> Generator {
  parameters
  |> list.index_fold(
    gen,
    fn(gen, parameters, i) {
      case i {
        0 -> gen
        _ -> write(gen, ", ")
      }
      |> write(parameters.0)
      |> write(": ")
      |> write(parameters.1)
    },
  )
}

type Generator {
  Generator(buffer: String, indent: Int)
}

fn write(gen: Generator, code: String) -> Generator {
  Generator(..gen, buffer: gen.buffer <> code)
}

fn indent_up(gen: Generator) -> Generator {
  Generator(..gen, indent: gen.indent + 1)
}

fn indent_down(gen: Generator) -> Generator {
  Generator(..gen, indent: gen.indent - 1)
}

fn indent(gen: Generator) -> Generator {
  gen
  |> write(string.repeat("  ", gen.indent))
}

fn newline(gen: Generator) -> Generator {
  gen
  |> write("\n")
}

fn finish(gen: Generator) -> String {
  gen.buffer
}
