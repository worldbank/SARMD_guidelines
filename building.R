bookdown::render_book("index.Rmd", "bookdown::gitbook", 
                      preview = TRUE)

bookdown::render_book("index.Rmd", "bookdown::gitbook")

dir <- getwd()
bookdown::serve_book(dir = dir, output_dir = "_book", 
                     preview = FALSE)