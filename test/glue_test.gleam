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
