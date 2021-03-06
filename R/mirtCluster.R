#' Define a parallel cluster object to be used in internal functions
#'
#' This function defines a object that is placed in a relevant internal environment defined in mirt.
#' Internal functions such as \code{calcLogLik}, \code{fscores}, etc, will utilize this object
#' automatically to capitalize on parallel
#' processing architecture. The object defined is a call from \code{parallel::makeCluster()}.
#' Note that if you are defining other parallel objects (for simulation designs, for example)
#' it is not recommended to define a mirtCluster.
#'
#' @aliases mirtCluster
#' @param spec input that is passed to \code{parallel::makeCluster()}. If no input is given the
#'   maximum number of available local cores will be used
#' @param omp_threads number of OpenMP threads to use (currently applies to E-step computations only).
#'   Not used when argument input is missing
#' @param ... additional arguments to pass to \code{parallel::makeCluster}
#' @param remove logical; remove previously defined \code{mirtCluster()}?
#'
#' @author Phil Chalmers \email{rphilip.chalmers@@gmail.com}
#' @references
#' Chalmers, R., P. (2012). mirt: A Multidimensional Item Response Theory
#' Package for the R Environment. \emph{Journal of Statistical Software, 48}(6), 1-29.
#' \doi{10.18637/jss.v048.i06}
#' @keywords parallel
#' @export mirtCluster
#' @examples
#'
#' \dontrun{
#'
#' #make 4 cores available for parallel computing
#' mirtCluster(4)
#'
#' #stop and remove cores
#' mirtCluster(remove = TRUE)
#'
#' # create 3 core achitecture in R, and 4 thread architecture with OpenMP
#' mirtCluster(spec = 3, omp_threads = 4)
#'
#' }
mirtCluster <- function(spec, omp_threads, remove = FALSE, ...){
    if(requireNamespace("parallel", quietly = TRUE)){
        if(!exists(".mirtClusterEnv")){
            .mirtClusterEnv <- new.env(parent=emptyenv())
            .mirtClusterEnv$ncores <- 1L
            .mirtClusterEnv$omp_threads <- 1L
        }
        if(missing(spec))
            spec <- parallel::detectCores()
            #spec <- 1L
        if(missing(omp_threads))
           # .mirtClusterEnv$omp_threads <- 1L
           .mirtClusterEnv$omp_threads <- parallel::detectCores()
        else 
           .mirtClusterEnv$omp_threads <- omp_threads
        if(remove){
            if(is.null(.mirtClusterEnv$MIRTCLUSTER)){
                message('There is no visible mirtCluster() definition')
                return(invisible())
            }
            parallel::setDefaultCluster(.mirtClusterEnv$OLD_DEFAULT)
            parallel::stopCluster(.mirtClusterEnv$MIRTCLUSTER)
            .mirtClusterEnv$MIRTCLUSTER <- NULL
            .mirtClusterEnv$ncores <- 1L
            # .mirtClusterEnv$omp_threads <- 1L
            return(invisible())
        }
        if(!is.null(.mirtClusterEnv$MIRTCLUSTER)){
            message('mirtCluster() has already been defined')
            return(invisible())
        }
       if (spec > 1L) {
           message('mirtCluster() initialization')
          .mirtClusterEnv$MIRTCLUSTER <- parallel::makeCluster(spec, ...)
          .mirtClusterEnv$ncores <- length(.mirtClusterEnv$MIRTCLUSTER)
          .mirtClusterEnv$OLD_DEFAULT <- parallel::getDefaultCluster()
          parallel::setDefaultCluster(.mirtClusterEnv$MIRTCLUSTER)
           mySapply(1L:.mirtClusterEnv$ncores*2L, function(x) invisible())
       } else {
           message('mirtCluster(1) NO NEED to initialize')
       }
    }
    return(invisible())
}
