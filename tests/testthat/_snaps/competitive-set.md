# competitive_set rejects non-product elements

    Code
      competitive_set(1, 2)
    Condition
      Error:
      ! <y2conjoint::competitive_set> object is invalid:
      - @products must contain only product objects

# competitive_set prints named and unnamed products

    Code
      print(cs)
    Output
      <competitive_set> Launch: 4 products: NONE, A, B, and 1 unnamed product
      
        NONE
      
        <product> A
        * Brand: Northwind
        * Price: $199
        * Battery: 20 hours
        * Storage: 256 GB
        * Color: Black
      
        <product> B
        * Brand: Cascade
        * Price: $299
        * Battery: 10 hours
        * Storage: 128 GB
        * Color: Blue
      
        <product> (unnamed)
        * Brand: Meridian
        * Price: $399
        * Battery: 30 hours
        * Storage: 512 GB
        * Color: Silver

# competitive_set rejects a non-scalar or missing none

    Code
      competitive_set(p, none = c(TRUE, FALSE))
    Condition
      Error:
      ! <y2conjoint::competitive_set> object is invalid:
      - @none must be a single TRUE or FALSE

---

    Code
      competitive_set(p, none = NA)
    Condition
      Error:
      ! <y2conjoint::competitive_set> object is invalid:
      - @none must be a single TRUE or FALSE

# competitive_set printing reports whether NONE is included

    Code
      print(included)
    Output
      <competitive_set> (unnamed): 2 products: NONE and A
      
        NONE
      
        <product> A
        * Brand: Northwind
        * Price: $199
        * Battery: 20 hours
        * Storage: 256 GB
        * Color: Black

---

    Code
      print(excluded)
    Output
      <competitive_set> (unnamed): 1 product: A
      
        <product> A
        * Brand: Northwind
        * Price: $199
        * Battery: 20 hours
        * Storage: 256 GB
        * Color: Black

# competitive_set rejects products over different collections

    Code
      competitive_set(product(brand_only, "Northwind"), product(price_only, "$249"))
    Condition
      Error:
      ! <y2conjoint::competitive_set> object is invalid:
      - all products must reference the same collections

