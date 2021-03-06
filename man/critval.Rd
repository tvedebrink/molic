% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/helper_outlier.R
\name{critval}
\alias{critval}
\alias{critval.outlier_model}
\title{Critical value}
\usage{
critval(m, alpha = 0.05)

\method{critval}{outlier_model}(m, alpha = 0.05)
}
\arguments{
\item{m}{A \code{outlier_model} object}

\item{alpha}{Significance level (between \code{0} and \code{1})}
}
\description{
Calculate the critical value for test statistic under \code{H_0}
}
\details{
The value \code{dz} can be obtained used the \code{deviance} function.
}
\seealso{
\code{\link{deviance}}
}
