library(httr2)
library(tidyjson)
library(purrr)
library(dplyr)
library(tidyr)

# Set up request with authorization
req <- request("https://api.printful.com/") |>
  req_headers(Authorization = paste(
    "Bearer",
    Sys.getenv("PRINTFUL_API_KEY")
  ))

# Get products
products <- req |>
  req_url_path_append("sync/products") |>
  req_perform() |>
  resp_body_string() |>
  enter_object("result") |>
  gather_array() |>
  as_tbl_json() |>
  spread_all() |>
  select(-c(document.id, array.index))

# Function to get product variants
get_variants <- function(req, id) {
  req |>
    req_url_path_append(paste0("sync/products/", id)) |>
    req_perform() |>
    resp_body_string() |>
    enter_object("result", "sync_variants") |>
    gather_array() |>
    as_tbl_json() |>
    spread_all()
}

# Get variants
variants <- map(products$id, \(id) get_variants(req, id)) |>
  list_rbind() |>
  select(
    product_id = sync_product_id,
    variant_id = id,
    variant_external_id = external_id,
    name,
    retail_price,
    currency,
    sku,
    size,
    color,
    ..JSON
  )

# Get preview URL for mockups
variants <- variants |>
  unnest_longer(col = ..JSON) |>
  filter(..JSON_id == "files") |>
  unnest_longer(col = ..JSON, indices_to = "..JSON_id_2") |>
  filter(..JSON_id_2 == 2) |>
  mutate(
    short_name = sub(" - .*", "", name),
    preview_url = ..JSON[[1]][["preview_url"]],
    .after = name
  ) |>
  select(-matches("..JSON"))

# Write to csv
write.csv(variants, "./shop/variants.csv",
          row.names = FALSE)

