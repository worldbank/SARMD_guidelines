

set.seed(1234)
options(digits = 3)

# Stata Engine

if (Sys.info()[7] == "wb384996") {
  # Andres
  stata_eng <- "c:/Program Files (x86)/Stata15/StataMP-64.exe"
} else if (Sys.info()[7] == "wb459082") {
  # Javier
  stata_eng <- "c:/Program Files (x86)/Stata15/StataMP-64.exe"
} else if (Sys.info()[7] == "wb502818") {
  # Jayne
  stata_eng <- "c:/Program Files (x86)/Stata15/StataMP-64.exe"
} else {
  stata_eng <- "c:/Program Files (x86)/Stata15/StataMP-64.exe"
}


knitr::opts_chunk$set(
  # comment = "#>",
  # comment=NA,
  warning = FALSE,
  collapse = TRUE,
  cache = TRUE,
  out.width = "70%",
  fig.align = 'center',
  fig.width = 6,
  fig.asp = 0.618,
  # 1 / phi
  fig.show = "hold",
  engine.path = list(stata = stata_eng)
)

options(dplyr.print_min = 6, dplyr.print_max = 6)


# install and load packages that have not been installed before
pkg <-
  c(
    "sf",
    "sp",
    "raster",
    "spData",
    "ggplot2",
    "dplyr",
    "readr",
    "png",
    "grid",
    "DiagrammeR",
    "tidyr",
    "tibble",
    "kableExtra"
  )
new.pkg <-
  pkg[!(pkg %in% installed.packages()[, "Package"])] # check installed packages
load.pkg <-
  pkg[!(pkg %in% loadedNamespaces())]              # check loaded packages

if (length(new.pkg)) {
  install.packages(new.pkg)     # Install missing packages
}

if (length(load.pkg)) {
  inst = lapply(load.pkg, library, character.only = TRUE) # load all packages
}

knitr::write_bib(pkg, "packages.bib")


if (Sys.info()[7] == "wb384996") {
  if (("bib2df" %in% loadedNamespaces()) == FALSE) {
    library("bib2df")
  }
  load_bib = function() {
    df <- bib2df("SARMD_guidelines.bib")
    df %>% dplyr::select(BIBTEXKEY, AUTHOR, TITLE) %>% View()
  }
}
