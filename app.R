
library(shiny)
library(ggvis)
data(mtcars)

## Load Motor Trend dataset
dataset <- mtcars
## Convert columns to factors
dataset$cyl <- as.factor(dataset$cyl)
dataset$vs <- as.factor(dataset$vs)
dataset$am <- as.factor(dataset$am)
dataset$gear <- as.factor(dataset$gear)
dataset$carb <- as.factor(dataset$carb)

carVars <- c("Miles/(US) gallon" = "mpg",
             "Number of cylinders" = "cyl",
             "Displacement (cu.in.)" = "disp",
             "Gross horsepower" = "hp",
             "Rear axle ratio" = "drat",
             "Weight (1000 lbs)" = "wt",
             "1/4 mile time" = "qsec",
             "V/S" = "vs",
             "Transmission (0 = automatic, 1 = manual)" = "am",
             "Number of forward gears" = "gear",
             "Number of carburetors" = "carb")

ui <- fluidPage(theme = "paper_min.css",
    tags$head(
        # Material design buttons and well panel
        tags$style(type = "text/css", ".selectize-input {
                border-width: 0;
                outline: none;
                border-radius: 2px;
                box-shadow: 0 1px 4px rgba(0, 0, 0, .6);
        }
        .selectize-dropdown {
                border-width: 0;
                outline: none;
                border-radius: 2px;
                box-shadow: 0 1px 4px rgba(0, 0, 0, .6);
        }
        .well {
                box-shadow: 0 1px 4px rgba(0, 0, 0, .6);
        }
        .control-label {
            font-weight: bold;
        }
                   ")
        ),
    titlePanel("Motor Trend Vehicle Analysis"),
    fluidRow(
        column(3,
               wellPanel(
                   # X-Axis
                   selectInput(inputId = "xInp", "Select X-Axis", carVars, selected = "wt"),
                   # Y-Axis
                   selectInput(inputId = "yInp", "Select Y-Axis", carVars),
                   # Select Color
                   selectInput(inputId = "colorInp", "Select Color", c("None", carVars)),
                   # Chose Smoothing
                   radioButtons("smoothInp", label = "Choose Smoothing",
                                choices = list("None" = "none",
                                               "Linear Regression" = "lm", 
                                               "Smooth Curve (LOESS)" = "loess"),
                                selected = "none"),
                   # 95% Confidence interval
                   p("Confidence Interval", style = "font-weight: bold;"),
                   checkboxInput("ciInp", label = "Include Confindence Interval", value = TRUE),
                   #sliderInput("ciSlider", label = NA, min = 0.5, max = 0.95, step = 0.05, value = 0.95)
                   tags$html(
                       tags$body(
                           br(),
                           p("Documentation", a("link", href="https://craigcovey.github.io/Motor_Trend_Analysis_Chart/index.html"))
                       )
                   )
               )
        ),
        column(9,
               ggvisOutput("cars_plot"),
               uiOutput("cars_ui")
        )
    ),
    hr()
)

server <- function(input, output) {
    
    car_tooltip <- function(z) {
        if (is.null(z)) return(NULL)
        paste0("<b>", names(z), "</b>: ", format(z), collapse = " ")
    }
    
    vis <- reactive({
        
        # Axis Labels
        x_name <- names(carVars)[carVars == input$xInp]
        y_name <- names(carVars)[carVars == input$yInp]
        color_name <- names(carVars)[carVars == input$colorInp]
        
        x_var <- prop("x", as.symbol(input$xInp))
        y_var <- prop("y", as.symbol(input$yInp))
        c_var <- prop("fill", as.symbol(input$colorInp))
        
        # ggvis scatterplot
        d <- dataset %>%
            ggvis(x = x_var, y = y_var) %>%
            layer_points(size := 50, size.hover := 200,
                         fillOpacity := 0.8, fillOpacity.hover := 1.0) %>%
            add_axis("x", title = x_name) %>%
            add_axis("y", title = y_name) %>%
            add_tooltip(car_tooltip, "hover") %>%
            set_options(width = "auto", height = "auto", resizable = FALSE)

        # Add by color to the plot
        if (input$colorInp != "None") {
            d <- d %>% layer_points(fill = c_var, size := 50, size.hover := 200,
                                    fillOpacity := 0.8, fillOpacity.hover := 1.0) %>%
                add_legend("fill", title = color_name)
        }
        # LOESS
        if (input$smoothInp == "loess") {
            d <- d %>% layer_smooths(se = input$ciInp)
        } 
        # Linear Regression
        if (input$smoothInp == "lm") {
            d <- d %>% layer_model_predictions(model = "lm", se = input$ciInp)
        }
        
        d
    })
    
    # Render plot
    vis %>% bind_shiny("cars_plot", controls_id = "cars_ui")
    
}

shinyApp(ui = ui, server = server)