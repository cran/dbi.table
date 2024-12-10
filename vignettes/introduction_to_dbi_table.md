Introduction to dbi.table
================

Query database tables and views over a DBI connection using
`data.table`’s `[i, j, by]` syntax, attach database schemas to the
search path, and programmatically load database catalogs.

This vignette assumes that you are already fluent with `data.table`’s
syntax and that you know how to open a database connection using the
`DBI` package.

# 1 Installation

The `dbi.table` package is hosted on GitHub. Use the following command
to install the package.

``` r
#install.packages("devtools")
devtools::install_github("kjellpk/dbi.table")
```

Note: if the `install_github` function is not found, you will need to
first install the `devtools` package using `install.packages`.

# 2 Getting Started

This section uses the sample [Chinook
Database](https://github.com/lerocha/chinook-database) (included in the
package) to demonstrate how to

1.  create a single `dbi.table` using the `dbi.table` function,
2.  maniuplate a `dbi.table` using `data.table`’s `[i, j, by]` syntax,
3.  attach a schema to the search path using the `dbi.attach` function,
    and
4.  load a database catalog using the `dbi.catalog` function.

The function `chinook.duckdb` that returns an open `duckdb` (DBI)
connection to the sample Chinook Database. This connection is a typical
DBI connection as returned by `DBI::dbConnect` that can be used as the
`conn` argument in DBI package functions. Let’s get started by loading
the package and opening the connection.

``` r
library(dbi.table)
chinook <- chinook.duckdb()
```

## 2.1 Create a Single `dbi.table`

The `dbi.table` function takes 2 arguments: a DBI connection, and an Id
indentifying a database table or view.

``` r
my_album <- dbi.table(chinook, DBI::Id("Album"))
```

The object `my_album` is a `dbi.table`, a data structure that represents
a SQL query (which we refer to as the `dbi.table`’s *underlying SQL
query*). The `print` method displays a preview of the underlying SQL
query.

``` r
#print(my_album)
my_album
```

    ## <chinook_duckdb> Album 
    ##  AlbumId                                 Title ArtistId
    ##    <int>                                <char>    <int>
    ##        1 For Those About To Rock We Salute You        1
    ##        2                     Balls to the Wall        2
    ##        3                     Restless and Wild        2
    ##        4                     Let There Be Rock        1
    ##        5                              Big Ones        3
    ##  ---

The preview has a format similar to a `data.table` with two notable
exceptions.

1.  The row numbers are omitted. SQL queries do not necessarily return
    the result set in a reliable order (even on subsequent evaluations
    of the same query), and `dbi.table` does not make any extra effort
    to order the rows by default. Thus the row numbers are omitted.

2.  Only 5 rows of the `dbi.table` are displayed (`data.table` displays
    the first 5 and the last 5). Again, since the result set does not
    have a reliable order, it is not possible to say which rows are the
    first and which are the last. The rows displayed are the first 5
    returned by the RDBMS.

The function `as.data.table` executes the `dbi.table`’s underlying SQL
query and retrieves the result set as a `data.table`. Pro tip: calling
the extracts method (`[]`) with no arguments is a shortcut for
`as.data.table`.

``` r
#as.data.table(my_album)
my_album[]
```

    ##      AlbumId                                                        Title
    ##        <int>                                                       <char>
    ##   1:       1                        For Those About To Rock We Salute You
    ##   2:       2                                            Balls to the Wall
    ##   3:       3                                            Restless and Wild
    ##   4:       4                                            Let There Be Rock
    ##   5:       5                                                     Big Ones
    ##  ---                                                                     
    ## 343:     343                                       Respighi:Pines of Rome
    ## 344:     344 Schubert: The Late String Quartets & String Quintet (3 CD's)
    ## 345:     345                                          Monteverdi: L'Orfeo
    ## 346:     346                                        Mozart: Chamber Music
    ## 347:     347           Koyaanisqatsi (Soundtrack from the Motion Picture)
    ##      ArtistId
    ##         <int>
    ##   1:        1
    ##   2:        2
    ##   3:        2
    ##   4:        1
    ##   5:        3
    ##  ---         
    ## 343:      226
    ## 344:      272
    ## 345:      273
    ## 346:      274
    ## 347:      275

Since the result set is instantiated locally as a `data.table`, the row
numbers and the last 5 rows are displayed.

Note: by default, `as.data.table` (and the empty extracts shortcut)
fetch a maximum of 10,000 rows. To override this limit, either set the
option `dbi_table_max_fetch` or call `as.data.table` and provide the `n`
argument (e.g., `n = -1` to fetch the entire result set).

The `csql` utility displays the query.

``` r
csql(my_album)
```

    ## SELECT Album.AlbumId AS AlbumId,
    ##        Album.Title AS Title,
    ##        Album.ArtistId AS ArtistId
    ## 
    ##   FROM Album AS Album
    ## 
    ##  LIMIT 10000

The underlying SQL query of a newly created `dbi.table` selects all the
columns from the database table.

## 2.2 Manipulate a `dbi.table` using `data.table` Syntax

This table from `data.table`’s *Introduction to data.table* vignette
pretty much sums up what `dbi.table` does.

``` r
DT[i, j, by]

##   R:                 i                 j        by
## SQL:  where | order by   select | update  group by
```

In general, `dbi.table` should be able to handle basic `data.table`
syntax. SQL translation is done by `dbplyr::translate_sql_` which works
with a wide variety of R functions. However, complicated expressions
(e.g., custom functions in `j`, nested aggregation functions, most
special symbols) do not work.

Best practice is to use `dbi.table` to subset and wrangle on the
database, then `data.table` to fine tune locally.

The remainder of this section demonstrates how `i`, `j`, and `by`
manipulate a `dbi.table`’s underlying SQL query.

When `i` is a logical expression of the variables in the `dbi.table`
then it becomes the *WHERE* clause in the `dbi.table`’s underlying SQL
query.

``` r
csql(my_album[AlbumId == ArtistId + 1])
```

    ## SELECT Album.AlbumId AS AlbumId,
    ##        Album.Title AS Title,
    ##        Album.ArtistId AS ArtistId
    ## 
    ##   FROM Album AS Album
    ## 
    ##  WHERE Album.AlbumId = (Album.ArtistId + 1)
    ## 
    ##  LIMIT 10000

When `i` is a call to `order` (or `forder`), it becomes the *ORDER BY*
clause in the `dbi.table`’s underlying SQL query.

``` r
csql(my_album[order(nchar(Title), -AlbumId)])
```

    ## SELECT Album.AlbumId AS AlbumId,
    ##        Album.Title AS Title,
    ##        Album.ArtistId AS ArtistId
    ## 
    ##   FROM Album AS Album
    ## 
    ##  ORDER BY LENGTH(Album.Title), Album.AlbumId DESC
    ## 
    ##  LIMIT 10000

When `j` is a list of expressions of the variables in the `dbi.table`,
then `j` becomes the *SELECT* clause in the `dbi.table`’s underlying SQL
query.

``` r
csql(my_album[, .(AlbumId, Title)])
```

    ## SELECT Album.AlbumId AS AlbumId,
    ##        Album.Title AS Title
    ## 
    ##   FROM Album AS Album
    ## 
    ##  LIMIT 10000

When `by` is a list of expressions of the variables in the `dbi.table`,
then `by` becomes the *GROUP BY* clause in the `dbi.table`’s underlying
SQL query.

``` r
csql(my_album[, .("# of Albums" = .N), .(ArtistId)])
```

    ## SELECT Album.ArtistId AS ArtistId,
    ##        COUNT(*) AS "# of Albums"
    ## 
    ##   FROM Album AS Album
    ## 
    ##  GROUP BY Album.ArtistId
    ## 
    ##  LIMIT 10000

## 2.3 Attach a Schema to the Search Path

The `dbi.attach` function *attaches* a DBI connection to the search
path. That is, `dbi.attach` creates a `dbi.table` for each table and
each view in the schema associated with the DBI connection, then assigns
these `dbi.table`s to an environment on the search path.

``` r
dbi.attach(chinook)
```

A quick look at the search path shows the database attached in position
2.

``` r
head(search(), 3)
```

    ## [1] ".GlobalEnv"            "duckdb:chinook_duckdb" "package:dbi.table"

The tables and views in the database schema are queriable as
`dbi.table`s in the attached environment duckdb:chinook_duckdb.

``` r
ls("duckdb:chinook_duckdb")
```

    ##  [1] "Album"         "Artist"        "Customer"      "Employee"     
    ##  [5] "Genre"         "Invoice"       "InvoiceLine"   "MediaType"    
    ##  [9] "Playlist"      "PlaylistTrack" "Track"

Note: Attaching a DBI connection is intended for an interactive
exploratory analysis of a database (schema). For programatic use cases,
see the *Load a Database Catalog* section.

Merging two `dbi.table`s results in a SQL join that describes the same
result set as the associated `data.table` merge. That is,

``` r
merge(as.data.table(Album), as.data.table(Artist), by = "ArtistId")
```

and

``` r
as.data.table(merge(Album, Artist, by = "ArtistId"))
```

are the same `data.table` up to row order.

``` r
csql(merge(Album, Artist, by = "ArtistId"))
```

    ## SELECT Album.ArtistId AS ArtistId,
    ##        Album.AlbumId AS AlbumId,
    ##        Album.Title AS Title,
    ##        Artist."Name" AS "Name"
    ## 
    ##   FROM chinook_duckdb.main.Album AS Album
    ## 
    ##  INNER JOIN chinook_duckdb.main.Artist AS Artist
    ##     ON Album.ArtistId = Artist.ArtistId
    ## 
    ##  LIMIT 10000

When a DBI connection is attached to the search path, `dbi.attach` also
loads the schema’s relational meta data (whether this works depends on
how the underlying database implments an *information schema*). In
particular, *foreign key* constraints are used as the default `by` when
merging. In the previous example, the `ArtistId` column is a foreign key
referencing the `Album` table. For this example, when the `by` argument
is omitted, `dbi.table` still merges *by* `ArtistId`.

``` r
csql(merge(Album, Artist))
```

    ## SELECT Album.ArtistId AS ArtistId,
    ##        Album.AlbumId AS AlbumId,
    ##        Album.Title AS Title,
    ##        Artist."Name" AS "Name"
    ## 
    ##   FROM chinook_duckdb.main.Album AS Album
    ## 
    ##  INNER JOIN chinook_duckdb.main.Artist AS Artist
    ##     ON Album.ArtistId = Artist.ArtistId
    ## 
    ##  LIMIT 10000

When the `y` argument is omitted, `dbi.table`’s `merge` uses the foreign
key constraints that reference `x` to determin the `y` (or `y`s) to
merge with.

``` r
csql(merge(Track))
```

    ## SELECT Track.MediaTypeId AS MediaTypeId,
    ##        Track.GenreId AS GenreId,
    ##        Track.AlbumId AS AlbumId,
    ##        Track.TrackId AS TrackId,
    ##        Track."Name" AS "Name",
    ##        Track.Composer AS Composer,
    ##        Track."Milliseconds" AS "Milliseconds",
    ##        Track.Bytes AS Bytes,
    ##        Track.UnitPrice AS UnitPrice,
    ##        Album.Title AS "Album.Title",
    ##        Album.ArtistId AS "Album.ArtistId",
    ##        Genre."Name" AS "Genre.Name",
    ##        MediaType."Name" AS "MediaType.Name"
    ## 
    ##   FROM chinook_duckdb.main.Track AS Track
    ## 
    ##   LEFT OUTER JOIN chinook_duckdb.main.Album AS Album
    ##     ON Album.AlbumId = Track.AlbumId
    ## 
    ##   LEFT OUTER JOIN chinook_duckdb.main.Genre AS Genre
    ##     ON Genre.GenreId = Track.GenreId
    ## 
    ##   LEFT OUTER JOIN chinook_duckdb.main.MediaType AS MediaType
    ##     ON MediaType.MediaTypeId = Track.MediaTypeId
    ## 
    ##  LIMIT 10000

When the optional `recursive` argument is `TRUE`, `merge.dbi.table`
recursively merges on each of the just-merged tables. In this example,
`Track` has a foreign key that references `Album` and `Album` has a
foreign key that references `Artist`.

``` r
csql(merge(Track, recursive = TRUE))
```

    ## SELECT Album.ArtistId AS "Album.ArtistId",
    ##        Track.MediaTypeId AS MediaTypeId,
    ##        Track.GenreId AS GenreId,
    ##        Track.AlbumId AS AlbumId,
    ##        Track.TrackId AS TrackId,
    ##        Track."Name" AS "Name",
    ##        Track.Composer AS Composer,
    ##        Track."Milliseconds" AS "Milliseconds",
    ##        Track.Bytes AS Bytes,
    ##        Track.UnitPrice AS UnitPrice,
    ##        Album.Title AS "Album.Title",
    ##        Genre."Name" AS "Genre.Name",
    ##        MediaType."Name" AS "MediaType.Name",
    ##        Artist."Name" AS "Artist.Name"
    ## 
    ##   FROM chinook_duckdb.main.Track AS Track
    ## 
    ##   LEFT OUTER JOIN chinook_duckdb.main.Album AS Album
    ##     ON Album.AlbumId = Track.AlbumId
    ## 
    ##   LEFT OUTER JOIN chinook_duckdb.main.Genre AS Genre
    ##     ON Genre.GenreId = Track.GenreId
    ## 
    ##   LEFT OUTER JOIN chinook_duckdb.main.MediaType AS MediaType
    ##     ON MediaType.MediaTypeId = Track.MediaTypeId
    ## 
    ##   LEFT OUTER JOIN chinook_duckdb.main.Artist AS Artist
    ##     ON Artist.ArtistId = Album.ArtistId
    ## 
    ##  LIMIT 10000

## 2.4 Load a Database Catalog

As a best practice for programatic use, it is better to load the catalog
in order to avoid modifying the search path.

``` r
catalog <- dbi.catalog(chinook)
```

Printing the catalog lists its schemas.

``` r
catalog
```

    ## <Database Catalog> duckdb::chinook_duckdb (2 schemas containing 15 objects) 
    ## [1] "information_schema" "main"

Individual tables can be accessed using `catalog$schema$table` syntax.

``` r
catalog$main$Album
```

    ## <chinook_duckdb> Album 
    ##  AlbumId                                 Title ArtistId
    ##    <int>                                <char>    <int>
    ##        1 For Those About To Rock We Salute You        1
    ##        2                     Balls to the Wall        2
    ##        3                     Restless and Wild        2
    ##        4                     Let There Be Rock        1
    ##        5                              Big Ones        3
    ##  ---

When a catalog is loaded, all of its tables have access to the
relational data in the information schema.

``` r
merge(catalog$main$Album)
```

    ## <chinook_duckdb> Album + Artist 
    ##  ArtistId AlbumId                                 Title Artist.Name
    ##     <int>   <int>                                <char>      <char>
    ##         1       1 For Those About To Rock We Salute You       AC/DC
    ##         2       2                     Balls to the Wall      Accept
    ##         2       3                     Restless and Wild      Accept
    ##         1       4                     Let There Be Rock       AC/DC
    ##         3       5                              Big Ones   Aerosmith
    ##  ---

# 3 Scope

This section provides a brief explanation of what the `dbi.table`
package is trying to do.

Suppose that `x` is a `dbi.table` and that `e` is an expression
involving `x` that returns either a `dbi.table` or a `data.table`.

``` r
x <- dbi.table(chinook, DBI::Id("Album"))
e <- quote(x[, .("# of Albums" = .N), .(ArtistId)])
```

Since `dbi.table`’s syntax is a subset of `data.table`’s syntax, if `e`
can be evaluated successfully (i.e., `eval(e)` does not throw an error),
then `e` should also be able to be successfully evaluated when `x` is a
`data.table`. There are thus 2 paths to the final `data.table` result:

1.  evaluate `e` then coerce the result using `as.data.table`, or

2.  coerce `x` to a `data.table` then evaluate `e`.

Path 2 is referred to as the reference implementation and describes the
*correct* answer: the *reference result set*. The design goal of
`dbi.table` is to get the same result set as the reference result set,
up to row order.

``` r
result_set <- as.data.table(eval(e))
x <- as.data.table(x)
reference_result_set <- eval(e)
all.equal(reference_result_set, result_set, ignore.row.order = TRUE)
```

    ## [1] TRUE

The `dbi.table` package includes the function `reference.test` that
compares the result set to the reference result set in the more general
case where `expr` (the function’s first argument) is an expression
involving 1 or more `dbi.table`s.

``` r
x <- dbi.table(chinook, DBI::Id("Album"))
reference.test({
  x[, .("# of Albums" = .N), .(ArtistId)]
})
```

    ## [1] TRUE

This function is used extensively in `dbi.table`’s unit/regression
tests.

# 4 Cleaning Up

We used the `chinook.duckdb` function to open a DBI connection at the
beginning of this vignette and now it is up to us to close it.

``` r
DBI::dbDisconnect(chinook)
```

However, this leaves our R session in a wonky state. The environment
“duckdb:chinook_duckdb” is still attached and there are several
`dbi.table`s in the global environment - all of these `dbi.table`s are
associated with an invalid DBI connection.

``` r
#A dbi.table in the duckdb:chinook_duckdb environment
Genre
```

    ## Error in `dbSendQuery()`:
    ## ! rapi_prepare: Invalid connection

The R objects associated with our now-closed DBI connection need to be
cleaned up manually (or you could just restart R).

``` r
detach("duckdb:chinook_duckdb")
rm(catalog, my_album, x)
```

## 4.1 Connection Management

Alternatively, when using either `dbi.attach` or `dbi.catalog`, the
first arguement can be a zero-argument function that returns an open DBI
connection. When `dbi.table` uses a function to open the DBI connection,
then that connection belongs to `dbi.table` and `dbi.table` will take
care of closing it when it is no longer needed.

``` r
dbi.attach(chinook.duckdb)
```

When `dbi.table` is managing the connection, then all the user has to do
is detach (or delete if a catalog). The DBI connection will be closed
when the object is garbage collected.

``` r
detach("duckdb:chinook_duckdb")
```

Further, when `dbi.table` owns the connection, it is able to reconnect
in the event that the connection unexpectedly drops.
