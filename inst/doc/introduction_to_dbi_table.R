## ----set_options, include = FALSE-------------------------------------------------------
old_opts <- options(width = 90)

## ----install, eval = FALSE--------------------------------------------------------------
# install.packages("dbi.table")

## ----library, message = FALSE-----------------------------------------------------------
library(data.table) #needed for as.data.table
library(dbi.table)
chinook <- chinook.duckdb()

## ----single_table-----------------------------------------------------------------------
my_album <- dbi.table(chinook, DBI::Id("Album"))

## ----my_album_print---------------------------------------------------------------------
#print(my_album)
my_album

## ----fetch_data_table-------------------------------------------------------------------
#as.data.table(my_album)
my_album[]

## ----my_album_csql----------------------------------------------------------------------
csql(my_album)

## ----xref, eval = FALSE-----------------------------------------------------------------
# DT[i, j, by]
# 
# ##   R:                 i                 j        by
# ## SQL:  where | order by   select | update  group by

## ----i_where_query----------------------------------------------------------------------
csql(my_album[AlbumId == ArtistId + 1])

## ----i_where----------------------------------------------------------------------------
my_album[AlbumId == ArtistId + 1]

## ----i_order_query----------------------------------------------------------------------
csql(my_album[order(nchar(Title), -AlbumId)])

## ----i_order----------------------------------------------------------------------------
my_album[order(nchar(Title), -AlbumId)]

## ----j_list-----------------------------------------------------------------------------
my_album[, .(AlbumId, Title)]

## ----by_list_query----------------------------------------------------------------------
csql(my_album[, .("# of Albums" = .N), .(ArtistId)])

## ----by_list----------------------------------------------------------------------------
my_album[, .("# of Albums" = .N), .(ArtistId)]

## ----dbi.attach-------------------------------------------------------------------------
dbi.attach(chinook)

## ----search_path------------------------------------------------------------------------
head(search(), 3)

## ----ls_chinook-------------------------------------------------------------------------
ls("duckdb:chinook_duckdb")

## ----merge_dts, eval = FALSE------------------------------------------------------------
# merge(as.data.table(Album), as.data.table(Artist), by = "ArtistId")

## ----merge_dbit, eval = FALSE-----------------------------------------------------------
# as.data.table(merge(Album, Artist, by = "ArtistId"))

## ----merge_dt_like----------------------------------------------------------------------
csql(merge(Album, Artist, by = "ArtistId"))

## ----merge_no_by------------------------------------------------------------------------
csql(merge(Customer, Employee))

## ----merge_no_y-------------------------------------------------------------------------
csql(merge(Track))

## ----merge_no_y_rec---------------------------------------------------------------------
csql(merge(Track, recursive = TRUE))

## ----dbi_catalog------------------------------------------------------------------------
catalog <- dbi.catalog(chinook)

## ----print_dbi_catalog------------------------------------------------------------------
catalog

## ----dbi_catalog_table------------------------------------------------------------------
catalog$main$Album

## ----scope_example----------------------------------------------------------------------
x <- dbi.table(chinook, DBI::Id("Album"))
e <- quote(x[, .("# of Albums" = .N), .(ArtistId)])

## ----reference_check--------------------------------------------------------------------
result_set <- as.data.table(eval(e))
x <- as.data.table(x)
reference_result_set <- eval(e)
all.equal(reference_result_set, result_set, ignore.row.order = TRUE)

## ----reference.test---------------------------------------------------------------------
x <- dbi.table(chinook, DBI::Id("Album"))
reference.test({
  x[, .("# of Albums" = .N), .(ArtistId)]
})

## ----disconnect-------------------------------------------------------------------------
DBI::dbDisconnect(chinook)

## ----bork, error = TRUE-----------------------------------------------------------------
try({
#A dbi.table in the duckdb:chinook_duckdb environment
Genre
})

## ----clean_up_manually------------------------------------------------------------------
detach("duckdb:chinook_duckdb")
rm(catalog, my_album, x)

## ----attach_function--------------------------------------------------------------------
dbi.attach(chinook.duckdb)

## ----clean_up---------------------------------------------------------------------------
detach("duckdb:chinook_duckdb")

## ----restore_options, include = FALSE-----------------------------------------
options(old_opts)

