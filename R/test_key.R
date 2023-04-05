#' Test API Key
#'
#'
#'
#' @export
#'
test_key <- function(question) {
 return(gpt_get_completions(question))
}
