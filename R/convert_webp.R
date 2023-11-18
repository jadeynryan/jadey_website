# Load packages
library(here)
library(fs)
library(magick)
library(purrr)

# Folder to convert all images from png to webp
folder <- here("blog/2023-11-17_publish-quarto-website/img/")

# List all PNG files in the folder
png_files <- fs::dir_ls(path = folder,
                        pattern = "\\.png$",
                        full.names = TRUE)

# Function to convert a PNG file to WebP
convert_to_webp <- function(png_file) {
  # Load the PNG image
  img <- image_read(png_file)

  # Construct the output WebP file name
  webp_file <- gsub("\\.png$", ".webp", png_file, ignore.case = TRUE)

  # Convert and save as WebP
  image_write(img, path = webp_file, format = "webp")

}

# Use purrr::map function to apply the conversion function to each PNG file
map(png_files, convert_to_webp)

# Remove .png files
map(png_files, file_delete)
