# Load required libraries
library(RPostgres)
library(leaflet)
library(htmlwidgets)
library(sf)
library(magrittr)

# Connect to the PostgreSQL database
con <- dbConnect(RPostgres::Postgres(),
                 dbname = "WEBMAPPING2",
                 host = "localhost",
                 port = 5432,
                 user = "postgres",
                 password = "0000")

# Retrieve schemas and tables information
schemas <- dbGetQuery(con, "SELECT schema_name FROM information_schema.schemata")
print(schemas)
tables_in_nairobi <- dbGetQuery(con, "SELECT table_name FROM information_schema.tables WHERE table_schema = 'Nairobi'")
print(tables_in_nairobi)

# Retrieve data from the "towns" table
towns_query <- 'SELECT *, ST_AsText(geom) as wkt_geom FROM "Nairobi"."towns"'
towns_result <- dbGetQuery(con, towns_query)

# Retrieve data from the "nairobi" table
constituency_query <- 'SELECT *, ST_AsText(geom) AS wkt FROM "Nairobi"."nairobi"'
constituency_result <- dbGetQuery(con, constituency_query)

# Retrieve data from the "health facilities" table
health_query <- 'SELECT *, ST_AsText(geom) AS wkt_geom FROM "Nairobi"."health facilities"'
health_result <- dbGetQuery(con, health_query)

# Close the database connection
dbDisconnect(con)

# Convert the geometry to an sf object for towns
towns_sf <- st_as_sf(towns_result, wkt = "wkt_geom", crs = 4326)

# Convert the geometry to an sf object for constituency
constituency_sf <- st_as_sf(constituency_result, wkt = "wkt", crs = 4326)

# Convert the geometry to an sf object for health facilities (assuming POINT geometry)
health_sf <- st_as_sf(health_result, wkt = "wkt_geom", crs = 4326)
str(health_result)

# Create a leaflet map
m <- leaflet() %>%
  addProviderTiles("OpenStreetMap.Mapnik", group = "OpenStreetMap") %>%
  addProviderTiles("Esri", options = providerTileOptions(id = "ESRI.WorldImagery"), group = "Esri World Imagery") %>%
  addTiles(group = "Base Maps")

# Add markers for towns
m <- m %>% addMarkers(data = towns_sf,
                      lng = ~st_coordinates(towns_sf)[, "X"],
                      lat = ~st_coordinates(towns_sf)[, "Y"],
                      popup = ~paste("ID:", town_id, "<br>Name:", town_name, "<br>Type:", town_type),
                      group = "Towns")

# Add polygons for constituency
m <- m %>% addPolygons(data = constituency_sf,
                       fillColor = "blue",
                       weight = 2,
                       opacity = 1,
                       color = "white",
                       fillOpacity = 0.5,
                       popup = ~const_nam,
                       group = "Constituency")

# Add markers for health facilities
m <- m %>% addMarkers(data = health_sf,
                      lng = ~st_coordinates(health_sf)[, "X"],  # Replace with actual longitude column if not 'X'
                      lat = ~st_coordinates(health_sf)[, "Y"],  # Replace with actual latitude column if not 'Y'
                      popup = ~prov ,
                      group = "Health Facilities")

# Add layer control to toggle groups
m <- m %>% addLayersControl(
  baseGroups = c("OpenStreetMap", "Esri World Imagery"),
  overlayGroups = c("Towns", "Constituency", "Health Facilities"),
  options = layersControlOptions(collapsed = FALSE)
)

# Save the map as an HTML file
htmlwidgets::saveWidget(m, "map_with_data.html", selfcontained = TRUE)

