# glue

[![Package Version](https://img.shields.io/hexpm/v/glue)](https://hex.pm/packages/glue)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glue/)

A package for generating functions from your Gleam code!

## Generators

- [compare](#compare)
- [list_variants](#list_variants)

### compare

Given a module containing this type:

```gleam
pub type LogLevel {
  Debug
  Info
  Warn
  Error
}
```

This generator will generate the following function:

```gleam
pub fn compare_log_level(a: LogLevel, b: LogLevel) -> Order {
  let to_int = fn(x) {
    case x {
      Debug -> 0
      Info -> 1
      Warn -> 2
      Error -> 3
    }
  }
  int.compare(to_int(a), to_int(b))
}
```

### list_variants

Given a module containing this type:

```gleam
pub type Direction {
  North
  East
  South
  West
}
```

This generator will generate the following function:

```gleam
pub fn direction_list() -> List(Direction) {
  [North, East, South, West]
}
```


## Installation

Add the package to your Gleam project

```sh
gleam add glue
```

API documentation can be found at <https://hexdocs.pm/glue>.
