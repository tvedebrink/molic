molic: Multivariate OutLIerdetection In Contingency Tables
================

<!-- README.md is generated from README.Rmd. Please edit that file -->
[![Travis Build Status](https://travis-ci.com/mlindsk/molic.svg?token=AuXvB5mAnHuxQxKszxph&branch=master)](https://travis-ci.com/mlindsk/molic) [![AppVeyor build status](https://ci.appveyor.com/api/projects/status/github/mlindsk/molic?branch=master&svg=true)](https://ci.appveyor.com/project/mlindsk/molic) [![status](https://joss.theoj.org/papers/9fa65ced7bf3db01343d68b4488196d8/status.svg)](https://joss.theoj.org/papers/9fa65ced7bf3db01343d68b4488196d8)

About molic
-----------

An **R** package to perform outlier detection in contingency tables using decomposable graphical models (DGMs); models for which the underlying association between all variables can be depicted by an undirected graph. **molic** also offers algorithms for fitting undirected decomposable graphs. Compute-intensive procedures are implementet using [Rcpp](http://www.rcpp.org/)/C++ for better run-time performance.

NOTE
---------------
Please note, that the **molic** is, at the moment, undergoing a major change in API. You can use the package as is for now for explorative purposes, but you should wait a couple of weeks for the final version. As an example, the `efs` procedure will be replaced with the more general function `fit_graph` with argument `type = "fwd"` (where `fwd` stands for forward). Backward selection and fitting a tree to data is similarily replace with `fit_graph` with type `bwd` and `tree` respectively.

Getting Started
---------------

If you want to learn the "behind the scenes" of the model it is recommended to go through [The Outlier Model](https://mlindsk.github.io/molic/articles/) and look at the [documentation](https://mlindsk.github.io/molic/reference/index.html) as you read along. See also the examples below and the paper \[TBA\].

You can install the development version of the package by using the `devtools` package:

``` r
devtools::install_github("mlindsk/molic", build_vignettes = FALSE)
```

How To Cite
-----------

-   If you want to cite the **outlier method** please use

``` latex
@article{key,
  title={Outlier Detection in Contingency Tables using Decomposable Graphical Models},
  author={Lindskou, Mads and Eriksen, Poul Svante and Tvedebrink, Torben},
  journal={Scandinavian Journal of Statistics},
  doi={10.1111/sjos.12407},
  year={2019}
}
```

-   If you want to cite the **molic** package please use

``` latex
TBA
```

Example - Outlier Detection
---------------------------

To demonstrate the outlier method we use the `car` data set from the [UCI Machine Learning Repository](https://archive.ics.uci.edu/ml/index.php). The data have 4 classes that labels the evaluation of a car; `unacceptable, acc, vgood` and `good`. These classes are determined by the other variables in the data - and theses are *not* necessarily independent of each other and we must therefore "fit their association".

### Reading Data

``` r
library(dplyr)
car <- read.table("https://archive.ics.uci.edu/ml/machine-learning-databases/car/car.data",
  header = FALSE, sep = ",", dec = ".") %>%
  as_tibble() %>%
  mutate_all(as.character)
colnames(car) <- c("buying", "maint", "doors", "persons", "lug", "safety", "class")
```

### Defining Sub-Classes

``` r
vgood_cars <- car %>%
  filter(class == "vgood") %>%
  select(-class) %>%
  mutate_all(.funs = function(x) substr(x, 1, 1)) # All values _must_ be a single character!

unacc_cars <- car %>%
  filter(class == "unacc") %>%
  select(-class) %>%
  mutate_all(.funs = function(x) substr(x, 1, 1))
```

### Fitting an Interaction Graph

The `efs` algorithm is a **forward** model selection algorithm. This means, that the algorithm starts from the **null-graph** with no edges and keep adding edges until a stopping criterion is met. We fit the interaction graph for the `vgood` cars and plot the result.

``` r
G_vgood  <- efs(vgood_cars, p = 0, trace = FALSE) # AIC (p = 0) and BIC (p = 1)
plot(G_vgood)
```

<img src="man/figures/README-acc-1.png" width="100%" style="display: block; margin: auto;" />

For comparison we also fit the interaction graph for the `unacc_cars`

``` r
G_unacc  <- efs(unacc_cars, p = 0, trace = FALSE)
plot(G_unacc)
```

<img src="man/figures/README-unacc-1.png" width="100%" style="display: block; margin: auto;" />

It is apparent that very good cars and unacceptable cars are determined by two different mechanisms.

### Outlier Test

We randomly select five cars from the `unacc_cars` data and test if they are outliers in `vgood_cars`.

``` r
set.seed(7)
# Five random observations from the unacc_cars data
zs    <- sample_n(unacc_cars, 5)

# A vector indicating whether not each of the 5 observations is an outlier in vgood_cars
outs  <- vector(length = 5)

# The result
sapply(seq_along(outs), function(i) {
  z   <- unlist(zs[i, ])
  # Include z in vgood_cars (the hypothesis is, that z belongs here)
  D_z <- as.matrix(vgood_cars %>% bind_rows(z))
  M   <- outlier_model(D_z, adj_list(G_vgood), nsim = 5000)
  p   <- p_val(M, deviance(M, z))
  ifelse(p <= 0.05, TRUE, FALSE)  # significance level = 0.05 used
})
#> [1] TRUE TRUE TRUE TRUE TRUE
```

All five randomly selected cars are thus declared outliers on a 0.05 significance level.

Example - Variable Selection
----------------------------

The `efs` procedure can be used as a variable selection tool. The idea is, to fit an interaction graph with the class variable of interest included. The most influential variables on the class variable is then given by the neighboring variables. Lets investigate which variables influences how the cars are labelled.

``` r
G_car <- efs(car, p = 0, trace = FALSE)
plot(G_car)
```

<img src="man/figures/README-var-select1-1.png" width="100%" style="display: block; margin: auto;" />

So the class of a car is actually determined by all variables except for `doors` (the number of doors in the car). The neighbors of `class` can be extracted as follows

``` r
adj_list(G_car)$class
#> [1] "safety"  "persons" "buying"  "maint"   "lug"
```

<!-- We can also state e.g. that the `safety` of a car is independent of the price (the `buying` varible) when the class of the car is known; this phenomena is also known as _conditional independence_.  -->
<!-- We could also use the **backward** selection algorithm and start from the **complete graph** where all edges are included and remove edges until a stopping criterion is met. -->
<!-- ```{r var-select2, fig.align = "center"} -->
<!-- G_complete <- make_complete_graph(colnames(car)) -->
<!-- G_car2 <- bws(car, G_complete, p = 0, trace = FALSE) -->
<!-- plot(G_car2) -->
<!-- ``` -->
