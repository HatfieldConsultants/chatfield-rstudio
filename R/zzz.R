.onLoad <- function(libname, pkgname) {
  # Load the API key from the environment variable
  api_key <<- Sys.getenv("OPENAI_API_KEY")

  # Check if the API key is set
  if (api_key == "") {
    input_secret_key_if_required()
    api_key <<- Sys.getenv("OPENAI_API_KEY")
  }
  cat(sprintf(
    'Model Version: %s\nMax Tokens: %s\nTemperature: %s\nTop p: %s\nFrequency Penalty: %s\nPresence Penalty: %s',

      Sys.getenv('OPENAI_GPT_MODEL', 'gpt-35-turbo'),
      as.character(Sys.getenv('OPENAI_MAX_TOKENS', 1)),
      as.character(Sys.getenv('OPENAI_TEMPERATURE', 1)),
      as.character(Sys.getenv('OPENAI_TOP_P', 1)),
      as.character(Sys.getenv('OPENAI_FREQUENCY_PENALTY', 0)),
      as.character(Sys.getenv('OPENAI_PRESENCE_PENALTY', 0))

  ))
}
