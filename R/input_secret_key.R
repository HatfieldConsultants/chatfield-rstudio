library(shiny)

# Function to display the secret key input UI
display_secret_key_ui <- function() {
  fluidPage(
    titlePanel("Enter your Secret Key"),
    mainPanel(
      textInput("secret_key", "Please enter your secret key:", ""),
      actionButton("submit_key", "Submit")
    )
  )
}

# Function to handle user input and set the environment variable
handle_secret_key_input <- function(input, output, session) {
  observeEvent(input$submit_key, {
    if (input$secret_key != "") {
      Sys.setenv(MY_SECRET_KEY = input$secret_key)
      showNotification("Secret key saved successfully. You can now use the package.", type = "message")
    } else {
      showNotification("Invalid input. Please enter a valid secret key.", type = "error")
    }
  })
}

# Function to check for the secret key and display UI if needed
input_secret_key_if_required <- function() {
  secret_key <- Sys.getenv("MY_SECRET_KEY", unset = NA)

  if (is.na(secret_key)) {
    # Display the UI component to request the secret key
    ui <- display_secret_key_ui()
    server <- handle_secret_key_input
    shinyApp(ui, server)
  } else {
    # Continue using the package as the secret key is already set
    message("Secret key is set. You can use the package.")
  }
}
