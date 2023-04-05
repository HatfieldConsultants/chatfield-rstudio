#' ChatGPT Addin
#'
#' This function launches an interactive Shiny gadget that serves as an RStudio addin
#' for interacting with OpenAI's GPT model. The addin
#' provides various functionality, such as asking ChatGPT, commenting or explaining
#' selected code, creating unit tests, optimizing or refactoring selected code, and more.
#'
#'
#' @return The function does not return a value. It runs the Shiny gadget within the RStudio
#'   environment, allowing the user to interact with the ChatGPT model.
#' @export
#' @import shiny miniUI rstudioapi stringr rmarkdown
chatgpt_addin <- function() {
  ui <- miniPage(
    shinyWidgets::setBackgroundColor("#131516"),
    gadgetTitleBar("CHatField for RStudio", right = miniTitleBarButton("save_conversation", "Save Conversation"),
                   left = miniTitleBarButton("done", "Done", primary = TRUE)),
    miniContentPanel(
      wellPanel(
        h4("Conversation Log:"),
        uiOutput("output_log", placeholder = TRUE)
      ),
      wellPanel(
        fluidRow(
          column(width = 9, h4("Select an option below")),
          ),
        selectInput(
          "action",
          "Action",
          choices = c(
            "Ask ChatGPT",
            "Comment selected code",
            "Complete selected code",
            "Create unit tests",
            "Create variable name",
            "Document code (in roxygen2 format)",
            "Explain selected code",
            "Find issues in the selected code",
            "Optimize selected code",
            "Refactor selected code"
          ),
          selected = "Ask ChatGPT"
        ),
        textInput("context", "Additional context (optional):"),
        actionButton("execute", "Execute"),
        actionButton("continue", "Continue"),
        checkboxInput("replace_code", label = "Replace code on-the-fly", value = FALSE),
        uiOutput("character_count")
      )
    ),
    tags$style(HTML(custom_css))
  )

  server <- function(input, output, session) {


    if(api_key == ""){
      query_modal <- modalDialog(
      title = "Please enter your OpenAI API Key",
      textInput('secret_key','API Key:'),
      easyClose = F,
      footer = tagList(
        actionButton("submit_key", "Submit")
        )
      )
      showModal(query_modal)

      observeEvent(input$submit_key, {
        user_input <- "Testing 123.."
        user_message <- list(role = "user", content = user_input)
        Sys.setenv("OPENAI_API_KEY" = input$secret_key)
        response_message <- execute_action("Test key", user_message)


        if (grepl("Unauthorized", response_message, ignore.case = T)){
          showNotification("Invalid input. Please enter a valid API Key.", type = "error")
        } else {
          # Save the secret key to the .Renviron file
          renviron_path <- file.path(Sys.getenv("HOME"), ".Renviron")
          cat(paste("OPENAI_API_KEY=", input$secret_key, "\n", sep=""), file = renviron_path, append = TRUE)
          # Reload the .Renviron file to update the current session
          readRenviron(renviron_path)

          showNotification("API Key saved successfully. You can now use the package.", type = "message")
          removeModal()
        }
      })
    }


    result <- reactiveVal()
    conversation_log <- reactiveVal(NULL)
    observeEvent(input$save_conversation, {
      date <- format(Sys.Date(), "%Y-%m-%d")
      filename <- paste0("convo_log_", date, ".Rmd")
      html_output_file <- paste0("convo_log_", date, ".html")

      text <- unlist(lapply(conversation_log(), function(message) {unlist(message)}))

      bold_content <- function(text){
        # Identify lines with only "user" or "assistant" and wrap them with bold tags
        bold_text <- gsub("(^|\\n)(user|assistant)(\\n|$)", "\\1<strong>\\2</strong>\\3", text, ignore.case = TRUE)
        # Return modified text
        return(bold_text)
      }

      # Create RMarkdown content
      rmd_content <- c(
        "---",
        "title: 'Conversation Log'",
        "output: html_document",
        "---",
        "\n",
        paste0("## Conversation Log - ", date),
        "\n",
        paste(bold_content(text), collapse = "\n\n")
      )

      # Write the RMarkdown content to file
      writeLines(rmd_content, filename, sep = "\n")

      # Render the RMarkdown file to HTML
      rmarkdown::render(input = filename, output_file = html_output_file)
    })

    observeEvent(input$continue, {
      user_input <- "Please continue from the end of your previous response."
      user_message <- list(role = "user", content = user_input)
      conversation_log(append(conversation_log(), list(user_message)))

      messages <- isolate(conversation_log())
      response_message <- ""
      response_message <- execute_action(input$action, messages)
      result(response_message)

      assistant_message <- list(role = "assistant", content = response_message)

      conversation_log(append(conversation_log(), list(assistant_message)))
    })

    observeEvent(input$execute, {
      selected_text <- ""
      if (rstudioapi::hasFun("getActiveDocumentContext")) {
        editor_context <- rstudioapi::getActiveDocumentContext()
        selected_text <- paste0(editor_context$selection[[1]]$text)
      }

      # Append additional context if provided
      if (input$context != "") {
        if(selected_text==""){
          selected_text <- input$context
        }else{
          selected_text <- paste("```", selected_text, "```", input$context, sep = "\n")
        }
      }


      user_input <- selected_text
      user_message <- list(role = "user", content = user_input)
      conversation_log(append(conversation_log(), list(user_message)))


      messages <- isolate(conversation_log())
      response_message <- ""
      response_message <- execute_action(input$action, messages)
      result(response_message)

      assistant_message <- list(role = "assistant", content = response_message)


# Append the latest message from the assistant to the conversation log
conversation_log(append(conversation_log(), list(assistant_message)))


      if (input$replace_code && !is.null(selected_text)) {
        editor_context <- rstudioapi::getActiveDocumentContext()
        if(grepl('```', assistant_message$content)){
          # browser()
          replacement_code <- stringr::str_extract(assistant_message$content, "(?s)```(?i:(R))?.*```")
          replacement_code <- stringr::str_replace_all(replacement_code, "(?i)```(R)?", "")


        }else{
          replacement_code <- assistant_message$content
        }

        if (replacement_code != "") {
          # modifyRange(editor_context$selection[[1]]$range, replacement_code)
          # Get the indentation of the first line of the selected text
          first_line <- strsplit(selected_text, "\n")[[1]][1]
          indentation <- stringr::str_extract(first_line, "^[ \t]*")

          indented_replacement_code_lines <- strsplit(replacement_code, "\n")[[1]]
          indented_replacement_code_lines <- paste0(indentation, indented_replacement_code_lines)
          indented_replacement_code <- paste(indented_replacement_code_lines, collapse = "\n")

          # Replace the selected text with the indented_replacement_code
          modifyRange(editor_context$selection[[1]]$range, indented_replacement_code)
        }


      }


    })

# Wait for 'done' event to stop app using event listener.
    observeEvent(input$done, {
      stopApp()
    })


    output$output_log <- renderUI({
      req(conversation_log())
      log <- isolate(conversation_log())
      do.call(tags$div, lapply(log, function(message) {
        if (message$role == "user") {
          tagList(
            tags$span(
              style = "color: white; font-weight: bold;",
              "User (", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "):"
            ),
            tags$br(),
            tags$div(style = "color: white; background-color: #333333;", shiny::markdown(message$content)),
            tags$br(),
            tags$hr()
          )
        } else {
          tagList(
            tags$span(style = "color: white; font-weight: bold;", "ChatGPT (", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "):"),
            tags$br(),
            tags$div(style = "color: white; background-color: #333333;", shiny::markdown(message$content)),
            tags$br(),
            tags$hr()
          )
        }
      }))
    })


    character_count <- reactive({
      log <- conversation_log()
      if (!is.null(log)) {
        nchar(paste(sapply(log, function(x) x$content), collapse = ""))
      } else {
        0
      }
    })

    # Render the character count in the UI
    output$character_count <- renderText({
      paste0(character_count(), "/12000")
    })
  }

  viewer <- paneViewer(minHeight = 600)
  runGadget(ui, server, viewer = viewer)
}

execute_action <- function(action, selected_text) {
  switch(
    action,
    "Test key" = test_key,
    "Ask ChatGPT" = ask_chatgpt,
    "Comment selected code" = comment_code,
    "Complete selected code" = complete_code,
    "Create unit tests" = create_unit_tests,
    "Create variable name" = create_variable_name,
    "Document code (in roxygen2 format)" = document_code,
    "Explain selected code" = explain_code,
    "Find issues in the selected code" = find_issues_in_code,
    "Optimize selected code" = optimize_code,
    "Refactor selected code" = refactor_code
  )(selected_text)
}

custom_css <- '
  body modal-dialog {
    background-color: #1a1a1a;
    color: #FFFFFF;
    font-family: "Segoe UI", sans-serif;
  }
  .well, .gadget-title {
    background-color: #262626;
    border-color: #1a1a1a;
    color: #FFFFFF;
    font-family: "Segoe UI", sans-serif;
  }
  pre {
    background-color: #1a1a1a;
    color: #FFFFFF;
    font-family: "Lucida Console", monospace;
    padding: 10px;
    border-radius: 3px;
    overflow: auto;
  }
  code {
    font-family: "Lucida Console", monospace;
    color: #FFFFFF;
    background: #262626;
    padding: 2px;
    border-radius: 3px;
  }
'


