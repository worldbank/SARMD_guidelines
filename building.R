
# preview just one chapter
file <- "Note3.Rmd"
bookdown::render_book(file, "bookdown::gitbook",
                      preview = TRUE)

# render the whole book
bookdown::render_book("index.Rmd", "bookdown::gitbook")

#serve the whole book to see modification on trshe fly
dir <- getwd()
bookdown::serve_book(dir = dir, output_dir = "_book",
                     preview = TRUE)
