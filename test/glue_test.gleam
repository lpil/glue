import glue
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn list_variants_test() {
  "
  pub type CardinalDirection {
    North
    East
    South
    West
  }
  "
  |> glue.generate_list_variants("CardinalDirection")
  |> should.equal(Ok(
    "pub fn cardinal_direction_list() -> List(CardinalDirection) {
  [North, East, South, West]
}
",
  ))
}

pub fn list_variants_invalid_test() {
  "
  pub type CardinalDirection {
    North
  "
  |> glue.generate_list_variants("CardinalDirection")
  |> should.be_error
}

pub fn list_variants_unknown_type_test() {
  "
  pub type CardinalDirection {
    North
    East
    South
    West
  }
  "
  |> glue.generate_list_variants("Wibble")
  |> should.be_error
}

pub fn list_variants_not_enum_test() {
  "
  pub type CardinalDirection {
    North
    East
    South
    West
    Other(String)
  }
  "
  |> glue.generate_list_variants("Wibble")
  |> should.be_error
}
