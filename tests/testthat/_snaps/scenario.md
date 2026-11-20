# run_scenario rejects combine_fn naming an unknown collection

    Code
      run_scenario(cjt, cs, combine_fn = list(Colour = pmax))
    Condition
      Error in `run_scenario()`:
      x `combine_fn` names collection not found in `x`.
      ! Unknown: Colour.

# run_scenario warns when a product name is defined differently across sets

    Code
      . <- run_scenario(cjt, list(launch, refresh))
    Condition <rlang_warning>
      Warning:
      ! Product "Value" is defined differently across different competitive sets
      i In competitive set Launch Value is defined as: Northwind, $199, 20 hours, 256 GB, Black
      i In competitive set Refresh Value is defined as: Cascade, $399, 30 hours, 512 GB, Blue

