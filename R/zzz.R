.onLoad <- function(libname, pkgname) {
  # Load the API key from the environment variable
  api_key <<- Sys.getenv("OPENAI_API_KEY")

  # Check if the API key is set
  if (api_key == "") {
    input_secret_key_if_required()
    api_key <<- Sys.getenv("OPENAI_API_KEY")

  }
}
