# glue

[![Package Version](https://img.shields.io/hexpm/v/glue)](https://hex.pm/packages/glue)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glue/)

A package for generating functions from your Gleam code!

## Generators

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

### compare

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
pub fn compare_direction(a: Direction, b: Direction) -> Order {
  let to_int = fn(x) {
    case x {
      North -> 0
      East -> 1
      South -> 2
      West -> 3
    }
  }
  int.compare(to_int(a), to_int(b))
}
```

## Installation

Add the package to your Gleam project

```sh
gleam add glue
```

API documentation can be found at <https://hexdocs.pm/glue>.
