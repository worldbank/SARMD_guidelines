
# preview just one chapter
file <- "formularies.Rmd"
bookdown::render_book(file, "bookdown::gitbook",
                      preview = TRUE)
beep(5)

# render the whole book
bookdown::render_book("index.Rmd", "bookdown::gitbook")

#serve the whole book to see modification on trshe fly
dir <- getwd()
bookdown::serve_book(dir = dir, output_dir = "docs",
                     preview = TRUE)
