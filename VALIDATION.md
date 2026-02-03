# Validation Guide: Hurdle Gamma Model Implementation

This document outlines the changes made to replace the zero-inflated Gamma specification with a hurdle Gamma model, and provides validation steps to ensure the implementation is correct.

## Changes Summary

### Model Family Changes

**Previous Implementation:**
- Used `family = Gamma(link = "log")` with `ziformula` for null model
- Used `family = ziGamma(link = "log")` for complex models
- Zero-inflated approach where Gamma component could theoretically generate zeros

**New Implementation:**
- Uses `family = truncated_gamma(link = "log")` for all models
- Maintains `ziformula` for the hurdle (occurrence) component
- Hurdle approach with strict truncation: Gamma component cannot generate zeros

### Key Conceptual Differences

1. **Zero-Inflated Model**: 
   - Allows the Gamma component to potentially generate zeros
   - Zero-inflation parameter adds extra zeros on top of Gamma zeros
   - Less clear separation between occurrence and intensity

2. **Hurdle Model**:
   - Gamma component is strictly truncated at zero (cannot generate zeros)
   - All zeros come from the binomial hurdle component
   - Clear separation: hurdle = occurrence, truncated Gamma = intensity
   - Better alignment with physical rainfall process

### Documentation Updates

All references to "Zero-Inflated" have been systematically updated to "Hurdle" throughout:
- Introduction and methodology explanation
- Model interpretation sections
- Coefficient explanations
- Figure captions
- Conclusion
- README

**Important R² Clarification Added:**
The Nakagawa R² values now explicitly state they measure the fit of the intensity model conditional on occurrence, not the full two-stage process. The hurdle component is evaluated separately through classification metrics (ROC, accuracy).

## Validation Steps

### 1. Model Fitting

To validate the changes work correctly, render the Quarto document:

```bash
quarto render index.qmd
```

**Expected Outcomes:**
- All models (m0_null through m6_mixed) should fit without convergence errors
- The `truncated_gamma()` family should be recognized by glmmTMB
- Model summaries should show both conditional (intensity) and hurdle (occurrence) components

**Potential Issues:**
- If glmmTMB version is too old, `truncated_gamma()` may not be available
  - Solution: Update glmmTMB to version >= 1.1.0
- If convergence issues occur, may need to adjust optimizer settings

### 2. Model Diagnostics

Verify that existing diagnostic code still works:

**DHARMa Residuals:**
- Quantile-quantile plots should still generate correctly
- Dispersion test should still pass (p > 0.05)
- Zero test should show perfect calibration (ratio ≈ 1.00)

**ROC Analysis:**
- Classification metrics for occurrence prediction should remain valid
- AUC should be unchanged (the hurdle component uses the same logistic specification)

### 3. Predictions

Check that prediction code functions correctly:

```r
# Should still work
predictions <- predict(m6_mixed, newdata = test_data, type = "response")
```

**Note:** Predictions combine both components (occurrence × intensity), so the overall prediction behavior should be very similar to the zero-inflated model.

### 4. Performance Metrics

**AIC/BIC Values:**
- May change slightly due to different parameterization
- Changes should be minimal (< 1% difference expected)
- Model ranking should remain the same

**R² Values (Nakagawa):**
- Should reflect intensity model fit (conditional on occurrence)
- Values may differ slightly from zero-inflated version
- Changes reflect different estimand, not model quality

### 5. Visual Checks

Verify all figures render correctly:
- Model selection plot (AIC progression)
- Residual diagnostic plots
- Posterior predictive check
- Distribution comparison plots
- Random effects caterpillar plots

## Scientific Justification

The hurdle Gamma specification is superior for rainfall modeling because:

1. **Physical Validity**: Rainfall is a two-stage process (occurrence then amount), not a single process with inflation
2. **Strict Separation**: Truncated Gamma cannot generate zeros, ensuring clear component interpretation
3. **Coefficient Clarity**: Hurdle coefficients clearly represent occurrence probability; Gamma coefficients clearly represent intensity conditional on occurrence
4. **No Negative Values**: Truncation ensures physically impossible negative predictions are avoided
5. **Better Alignment**: Matches the data-generating process of weather systems

## Testing Commands

```r
# Install/load required packages
library(glmmTMB)
library(DHARMa)
library(performance)

# Check glmmTMB version
packageVersion("glmmTMB")  # Should be >= 1.1.0

# Test family availability
test_model <- glmmTMB(
  formula = y ~ 1,
  ziformula = ~1,
  family = truncated_gamma(link = "log"),
  data = test_data
)

# Verify convergence
summary(test_model)

# Check diagnostics
simulateResiduals(test_model) %>% plot()
```

## Expected Results

After successful validation:
- ✅ Document renders without errors
- ✅ All models converge successfully  
- ✅ DHARMa diagnostics show good model fit
- ✅ ROC/accuracy metrics are valid
- ✅ Predictions are physically realistic (non-negative)
- ✅ R² values are properly interpreted as conditional on occurrence

## Troubleshooting

### Issue: `truncated_gamma` not recognized
**Solution:** Update glmmTMB: `install.packages("glmmTMB")`

### Issue: Convergence warnings
**Solution:** The glmmTMBControl settings in the code include optimizer specifications. May need to adjust `maxit` or try different optimizers.

### Issue: Different AIC values
**Expected:** Minor differences are normal due to parameterization. Check that the ranking and relative differences are preserved.

### Issue: Changed R² values  
**Expected:** This is normal and documented. R² now reflects intensity conditional on occurrence. Add note in interpretation if significantly different.

## References

- glmmTMB documentation: https://cran.r-project.org/package=glmmTMB
- Brooks et al. (2017). "glmmTMB Balances Speed and Flexibility Among Packages for Zero-inflated Generalized Linear Mixed Modeling"
- Zuur et al. (2009). "Mixed Effects Models and Extensions in Ecology with R"
