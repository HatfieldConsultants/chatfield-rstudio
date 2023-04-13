#' Get Completions
#'
#' @param prompt The prompt to generate completions for.
#' @param openai_api_key OpenAI's API key.
#'
#' @importFrom httr add_headers content content_type_json POST
#' @importFrom jsonlite toJSON
#'
gpt_get_completions <- function(prompt, openai_api_key = Sys.getenv("OPENAI_API_KEY")) {
  # if (nchar(openai_api_key) == 0) {
  #   stop("`OPENAI_API_KEY` not provided.")
  # }
  result <- tryCatch({
    if (as.logical(Sys.getenv("OPENAI_VERBOSE", TRUE))) {
      cat(paste0("\n*** ChatGPT input:\n\n", prompt, "\n"))
    }


    messages <- list(
      list(
        role = "system",
        content = paste(
          "You are an R coding assistant designed to help users with their R programming tasks. You have extensive knowledge of R programming. Your purpose is to provide accurate and concise solutions, explanations, and suggestions related to R code, best practices, and troubleshooting. You should also be able to understand and interpret code snippets provided by the user, and give relevant context and advice based on the specific code. Your responses should be friendly and professional, and you should always prioritize user comprehension and learning. Avoid providing unrelated or overly complicated information. Please format your responses in a clear and structured manner, using proper code formatting and markdown when necessary.
          Highlight any changes you make to existing code in red."
        )
      )
    )
    for(i in 1:length(prompt)){
      messages <- append(messages, prompt[i])
    }


      params <- list(
        messages = messages,
        max_tokens = as.numeric(Sys.getenv("OPENAI_MAX_TOKENS", 800)),
        temperature = as.numeric(Sys.getenv("OPENAI_TEMPERATURE", 1)),
        top_p = as.numeric(Sys.getenv("OPENAI_TOP_P", 1)),
        frequency_penalty = as.numeric(Sys.getenv("OPENAI_FREQUENCY_PENALTY", 0)),
        presence_penalty = as.numeric(Sys.getenv("OPENAI_PRESENCE_PENALTY", 0))
      )

      post_res <- POST(
        paste0("https://hatconopenaitesting.openai.azure.com/openai/deployments/", Sys.getenv("OPENAI_GPT_MODEL"), "/chat/completions?api-version=2023-03-15-preview"),
        add_headers("Authorization" = paste("Bearer", openai_api_key),
                    "api-key" = openai_api_key),
        content_type_json(),
        body = toJSON(c(params), auto_unbox = TRUE)
      )

    if (!post_res$status_code %in% 200:299) {
      print("error")
      stop(content(post_res))
    }

    result <- content(post_res)
    }, error = function(e) {
      # Handle the error and return the error message
      return(paste("Error:", e$message))
    })
  # Return the result
  return(result)
}
