
# preview just one chpater
file <- "inventory.Rmd"
bookdown::render_book(file, "bookdown::gitbook", 
                      preview = TRUE)

# render the whole book
bookdown::render_book("index.Rmd", "bookdown::gitbook")

#serve the whole book to see modification on the fly
dir <- getwd()
bookdown::serve_book(dir = dir, output_dir = "_book", 
                     preview = FALSE)