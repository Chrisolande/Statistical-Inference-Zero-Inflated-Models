# Australian Rainfall Dynamics

![R Version](https://img.shields.io/badge/R-4.5.x-blue?logo=R)
![Quarto](https://img.shields.io/badge/Quarto-1.5+-blue?logo=quarto)
![Methodology](https://img.shields.io/badge/Method-ZI--Gamma%20GLMM-red)
![License](https://img.shields.io/badge/License-MIT-green)

**[Read the full report](https://chrisolande.github.io/australian-rainfall-dynamics/)**

## Project Name and Description

**Australian Rainfall Dynamics** is a frequentist statistical analysis of daily rainfall across 49 Australian weather stations (142,199 observations), built to address three simultaneous violations of Ordinary Least Squares assumptions: 64.05% structural zeros, severe positive-value leptokurtosis (kurtosis = 181.146), and strong day-to-day Markovian dependence.

The project fits a **Zero-Inflated Gamma Generalised Linear Mixed Model (ZIG-GLMM)** that decomposes precipitation into two physically distinct regimes — occurrence and intensity — estimated under a joint likelihood, rather than forcing a single symmetric, unbounded distribution onto bounded, skewed, zero-heavy data.

## Technology Stack

| Component | Tool / Package | Purpose |
| :--- | :--- | :--- |
| Language | R 4.5.x | Core statistical computing |
| Reporting | Quarto 1.5+ | Multi-chapter reproducible report and site |
| Mixed-effects modelling | `glmmTMB` | Maximum-likelihood ZIG-GLMM fitting |
| Multiple imputation | `mice`, `missRanger`, `mitml` | Two-stage hybrid imputation for 42–48% missingness |
| Diagnostics | `DHARMa`, `performance`, `car` | Residual, dispersion, and collinearity checks |
| Evaluation | `pROC`, `yardstick`, `Metrics`, `caret` | Classification and predictive-accuracy metrics |
| Data wrangling | `tidyverse`, `janitor`, `zoo` | Cleaning, feature engineering, moving averages |
| Reporting/tables | `gt`, `gtsummary`, `sjPlot`, `kableExtra` | Formatted statistical output |
| Environment management | `renv` | Reproducible dependency lockfile |

Package versions are pinned in `renv.lock`.

## Project Architecture

The model treats zero rainfall and positive rainfall as outputs of two separate linear predictors under a shared likelihood:

$$P(Y_i = 0) = \pi_i + (1 - \pi_i) \cdot f_\Gamma(0 \mid \mu_i,\, \phi)$$

$$P(Y_i = y) = (1 - \pi_i) \cdot f_\Gamma(y \mid \mu_i,\, \phi), \quad y > 0$$

$$\text{logit}(\pi_i) = \mathbf{W}_i \boldsymbol{\gamma} \qquad \log(\mu_i) = \mathbf{X}_i \boldsymbol{\beta} + \mathbf{Z}_i \mathbf{b}$$

- $\pi_i$ — structural dry-day probability, estimated by the logistic hurdle component
- $\mu_i$ — conditional rainfall intensity, estimated by the Gamma component
- $\mathbf{Z}_i \mathbf{b}$ — location-specific random slopes capturing spatial heterogeneity

$\mathbf{W}_i$ and $\mathbf{X}_i$ are estimated independently, so the drivers of *whether* it rains can differ from the drivers of *how much*. This independent-predictor-matrix structure is what distinguishes the ZIG framework from a Tweedie model. All models are fitted via maximum likelihood with Rubin's Rules pooling across five multiply-imputed datasets.

**Model progression:**

| Model | Specification | AIC | Δ AIC |
| :--- | :--- | ---: | ---: |
| M0 | Null baseline | 461,669.7 | |
| M1 | Moisture and pressure dynamics | 425,731.4 | -35,938.3 |
| M2 | Seasonality and day-to-day persistence | 412,920.9 | -12,810.5 |
| M3 | Accumulated weather history | 408,915.1 | -4,005.8 |
| M4 | Thermodynamic energy and Rain Corner interaction | 407,848.8 | -1,066.3 |
| M5 | Circular wind vectors | 407,066.6 | -782.2 |
| M6 | Mixed effects with random slopes | 400,151.2 | -6,915.4 |

Every extension is confirmed by a pooled $D_1$ Wald test at $p < 0.001$.

## Getting Started

**Prerequisites:** R 4.5.x, Quarto CLI 1.5+

**1. Clone the repository:**

```bash
git clone https://github.com/Chrisolande/australian-rainfall-dynamics.git
cd australian-rainfall-dynamics
```

**2. Install dependencies** — either restore the exact locked environment:

```r
renv::restore()
```

or install packages directly:

```r
librarian::shelf(
  aod,         broom,        broom.mixed,  car,
  caret,       cocor,        corrplot,     DHARMa,
  DT,          forcats,      furrr,        GGally,
  ggpubr,      ggridges,     glmmTMB,      glue,
  gridExtra,   gt,           gtsummary,    here,
  janitor,     kableExtra,   lmtest,       Metrics,
  mgcv,        mice,         missRanger,   mitml,
  moments,     multcompView, naniar,       parallel,
  patchwork,   performance,  pROC,         ranger,
  RhpcBLASctl, rstatix,      scales,       sjPlot,
  skimr,       splines,      tidymodels,   tidyverse,
  viridis,     yardstick,    zoo
)
```

**3. Render the report:**

```bash
quarto render index.qmd
```

Pre-fitted model objects are stored individually under `models/`, so the report renders without re-running the `glmmTMB` optimisations — these involve high-dimensional mixed-effects likelihoods fitted across five imputed datasets and are computationally intensive.

## Project Structure

```
.
├── index.qmd                        # Landing page and executive overview
├── _quarto.yml                      # Site configuration
├── config.R                         # Shared project configuration
├── utils.R                          # Shared utility functions
├── renv.lock                        # Reproducible package lockfile
│
├── chapters/                        # Quarto source documents (01-intro → 09-conclusion)
├── chapter02-03/                    # Data cleaning and imputation scripts
├── chapter4/                        # EDA scripts
├── chapter5/                        # Feature engineering scripts
├── chapter6/                        # Modelling scripts
├── chapter7/                        # Model evaluation scripts
├── chapter8/                        # Model selection scripts
│
├── data/                            # Source, cleaned, and feature-engineered datasets
├── models/                          # Pre-fitted .rds model objects (M0–M6 and comparisons)
└── docs/                            # Rendered HTML report (GitHub Pages)
```

Each numbered `chapterN/` folder holds the R scripts backing the corresponding `chapters/0N-*.qmd` document, keeping analysis code and narrative report in a 1:1 mapping.

## Key Features

- **Zero-Inflated Gamma GLMM** jointly modelling rainfall occurrence and intensity via independent linear predictors
- **Thermodynamic interaction threshold** ("Rain Corner"): a centred humidity × sunshine interaction term (VIF = 1.174) isolating the joint condition under which rainfall concentrates, significant at $F(2,\ 24.1) = 49.375$, $p < 0.001$
- **Markovian persistence modelling**: previous-day rain state as the strongest hurdle-component predictor (85% dry→dry, 47% wet→wet transition probabilities), $F(4,\ 71.3) = 802.158$, $p < 0.001$
- **Circular wind vector decomposition** into orthogonal North–South and East–West components, isolating southerly/westerly morning flows as primary intensity drivers, $F(4,\ 272.8) = 133.422$, $p < 0.001$
- **Spatial random-effects structure** capturing ~10% of total rainfall variance across stations ($\Delta\text{AIC} = -6{,}915.32$ over the fixed-effects model), separating tropical Top End stations (+75–77% rainfall) from arid interior stations (~half)
- **Two-stage hybrid multiple imputation** for 42–48% missingness in key meteorological variables, validated with Rubin's Rules pooling

## Development Workflow

The analysis proceeds as a linear, chapter-by-chapter pipeline, each stage producing artefacts consumed by the next:

1. **Data preparation** (`chapter02-03/`) — cleaning and two-stage hybrid imputation → `df_clean.rds`, `imp_mids.rds`
2. **Imputation sensitivity** — convergence diagnostics and Rubin's Rules variance decomposition on the imputed datasets
3. **Exploratory analysis** (`chapter4/`) — zero-inflation, distributional, temporal, and interaction structure
4. **Feature engineering** (`chapter5/`) — wind vectors, cyclical encoding, lag features → `df_final.csv`
5. **Modelling** (`chapter6/`) — progressive ZIG-GLMM construction, M0 through M6, pooled across imputations
6. **Model evaluation** (`chapter7/`) — ROC analysis, random-effects inspection, DHARMa diagnostics, autocorrelation testing
7. **Model selection** (`chapter8/`) — distributional family comparison, pooled Wald tests, AIC sequencing
8. **Report rendering** — Quarto compiles all chapters into the published site under `docs/`

Each chapter's narrative (`chapters/0N-*.qmd`) sources directly from its corresponding script folder, so re-running a chapter's R scripts and re-rendering the `.qmd` keeps the report in sync with the underlying analysis.

## Coding Standards

- Analysis code is organised by report chapter, with one script folder per chapter and clear single-responsibility file names (e.g. `eval_autocorrelation.R`, `eval_diagnostics.R`)
- Shared logic (project configuration, utility functions) is centralised in `config.R` and `utils.R` rather than duplicated across chapter scripts
- Package dependencies are pinned via `renv.lock` for exact reproducibility
- Model objects are persisted individually as `.rds` files under `models/` rather than re-fitted on every render, separating expensive computation from report generation

## Testing

Model adequacy is validated through four independent procedures rather than a conventional unit-test suite, appropriate for a statistical-modelling project:

| Check | Result | What it validates |
| :--- | :--- | :--- |
| AUC (occurrence submodel) | 0.813 | Discrimination between dry and wet days |
| Brier Score / Skill Score | 0.1654 / 0.2819 | Calibrated probabilistic accuracy vs. climatological baseline |
| DHARMa dispersion test | $p = 0.152$ | No over- or under-dispersion |
| Zero-inflation calibration | Ratio = 1.00, $p = 0.512$ | Correct proportion of predicted dry days |
| Durbin-Watson statistic | ~2.0 across most locations | No residual temporal autocorrelation |
| MAE / RMSE (all vs. rain-days) | 2.760 mm / 7.567 mm (all); 5.607 mm / 12.263 mm (rain-days) | Predictive accuracy, overall and on the harder positive-value subset |

These diagnostics are implemented in `chapter7/` and reported in full in Chapter 7 of the rendered report.

## Contributing

This is primarily a personal research/portfolio project. If proposing changes:

- Follow the existing chapter/script structure — new analysis should map to a `chapterN/` folder and its corresponding `.qmd`
- Restore the environment with `renv::restore()` before making changes, and update `renv.lock` if adding dependencies
- Re-render affected chapters with `quarto render` and confirm diagnostics in Chapter 7 still hold before submitting changes

## Scope and Limitations

**Suitable applications:** Short-range probabilistic forecasting (1–7 days), regional climate characterisation, agricultural drought planning, historical gap-filling for non-extreme observations.

**Not suitable for:** Extreme value analysis. The Gamma distribution's exponentially declining tails systematically underestimate the probability and magnitude of rare events beyond roughly the 95th percentile. Flood risk and infrastructure design require Extreme Value Theory methods — specifically a Generalised Pareto Distribution fitted to threshold exceedances. A natural extension is a composite model grafting a GPD onto the ZIG body at the 95th percentile.

## Author

**Chris Olande** | Statistician and Programmer | Nairobi, Kenya

[LinkedIn](https://www.linkedin.com/in/chris-olande-6557a3238/)

## Citation

Olande, C. (2026). *Australian Rainfall Dynamics: A Zero-Inflated Gamma Mixed-Effects Model for Spatiotemporal Precipitation*. GitHub. https://github.com/Chrisolande/australian-rainfall-dynamics

## License

MIT
