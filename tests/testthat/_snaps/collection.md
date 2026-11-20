# ordered_collection rejects an order that mismatches levels

    Code
      ordered_collection(name = "Price", levels = c("$249", "$299"), order = c("$249",
        "$399"))
    Condition
      Error in `ordered_collection()`:
      ! <y2conjoint::ordered_collection> object is invalid:
      - @order must contain exactly the same levels as @levels

# collection rejects empty levels

    Code
      collection(name = "Brand", levels = character())
    Condition
      Error in `collection()`:
      ! <y2conjoint::collection> object is invalid:
      - @levels must contain at least one level

# collection rejects duplicate levels

    Code
      collection(name = "Brand", levels = c("A", "A"))
    Condition
      Error in `collection()`:
      ! <y2conjoint::collection> object is invalid:
      - @levels must be unique

# collection rejects an empty name

    Code
      collection(name = "", levels = "A")
    Condition
      Error in `collection()`:
      ! <y2conjoint::collection> object is invalid:
      - @name must be a single non-empty string

# collection stores an absence level and validates it

    Code
      collection("Camera", c("8 MP", "12 MP"), absence = "No camera")
    Condition
      Error in `collection()`:
      ! <y2conjoint::collection> object is invalid:
      - @absence must be one of @levels

---

    Code
      collection("Camera", c("No camera", "None"), absence = c("No camera", "None"))
    Condition
      Error in `collection()`:
      ! <y2conjoint::collection> object is invalid:
      - @absence must be a single level or empty

