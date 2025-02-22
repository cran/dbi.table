% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dbi.table.R
\name{dbi.table-package}
\alias{dbi.table-package}
\alias{dbi.table}
\alias{[.dbi.table}
\title{DBI Table}
\usage{
dbi.table(conn, id)

\method{[}{dbi.table}(x, i, j, by, nomatch = NA, on = NULL)
}
\arguments{
\item{conn}{A \code{\link[DBI:DBIConnection-class]{DBIConnection}} object, as
returned by \code{\link[DBI]{dbConnect}}. Alternatively, a
\code{\link{dbi.catalog}} or a \code{dbi.table}, in which case the new
\code{dbi.table} will use the connection embedded in the provided object.}

\item{id}{An \code{Id}, a character string (which will be converted to
an \code{Id} by \code{\link[DBI]{Id}}), or a \code{\link[DBI]{SQL}} object
(advanced) identifying a database object (e.g., table or view) on
\code{conn}.}

\item{x}{A \code{dbi.table}.}

\item{i}{A logical expression of the columns of \code{x}, a \code{dbi.table},
  or a \code{data.frame}. Use \code{i} to select a subset of the rows of
  \code{x}. Note: unlike \code{data.table}, \code{i} \emph{cannot} be a
  vector.

  When \code{i} is a logical expression, the rows where the expression is
  \code{TRUE} are returned. If the expression contains a symbol \code{foo}
  that is not a column name of \code{x} but that is present in the calling
  scope, then the value of \code{foo} will be substituted into the expression
  if \code{foo} is a scalar, or if \code{foo} is a vector and is the
  right-hand-side argument to \code{\%in\%} or \code{\%chin\%} (substitution
  occurs when the extract (\code{[}) method is evaluated).

  When \code{i} inherits from \code{data.frame}, it is coerced to a
  \code{dbi.table}.

  When \code{i} is a \code{dbi.table}, the rows of \code{x} that match
  (according to the condition specificed in \code{on}) the rows
  of \code{i} are returned. When \code{nomatch == NA}, all rows of \code{i}
  are returned (right outer join); when \code{nomatch == NULL}, only the rows
  of \code{i} that match a row of \code{x} are returned (inner join).}

\item{j}{A list of expressions, a literal character vector of column names of
\code{x}, an expression of the form \code{start_name:end_name}, or a
literal numeric vector of integer values indexing the columns of \code{x}.
Use \code{j} to select (and optionally, transform) the columns of \code{x}.}

\item{by}{A list of expressions, a literal character vector of column names of
\code{x}, an expression of the form \code{start_name:end_name}, or a
literal numeric vector of integer values indexing the columns of \code{x}.
Use \code{by} to control grouping when evaluating \code{j}.}

\item{nomatch}{Either \code{NA} or \code{NULL}.}

\item{on}{\itemize{
    \item An unnamed character vector, e.g., \code{x[i, on = c("a", "b")]},
          used when columns \code{a} and \code{b} are common to both \code{x}
          and \code{i}.

    \item Foreign key joins: As a named character vector when the join
          columns have different names in \code{x} and \code{i}. For example,
          \code{x[i, on = c(x1 = "i1", x2 = "i2")]} joins \code{x} and
          \code{i} by matching columns \code{x1} and \code{x2} in \code{x}
          with columns \code{i1} and \code{i2} in \code{i}, respectively.

    \item Foreign key joins can also use the binary operator \code{==}, e.g.,
          \code{x[i, on = c("x1 == i1", "x2 == i2")]}.

    \item It is also possible to use \code{.()} syntax as
          \code{x[i, on = .(a, b)]}.

    \item Non-equi joins using binary operators \code{>=}, \code{>},
          \code{<=}, \code{<} are also possible, e.g.,
          \code{x[i, on = c("x >= a", "y <= b")]}, or
          \code{x[i, on = .(x >= a, y <= b)]}.
  }}
}
\value{
A \code{dbi.table}.
}
\description{
A dbi.table is a data structure that describes a SQL query (called the
  dbi.table's \emph{underlying SQL query}). This query can be manipulated
  using \code{\link[data.table]{data.table}}'s \code{[i, j, by]} syntax.
}
\examples{
  # open a connection to the Chinook example database using duckdb
  duck <- chinook.duckdb()

  # create a dbi.table corresponding to the Album table on duck
  Album <- dbi.table(duck, DBI::Id(table_name = "Album"))

  # the print method displays a 5 row preview
  # print(Album)
  Album

  # 'id' can also be 'SQL'; use the same DBI connection as Album
  Genre <- dbi.table(Album, DBI::SQL("chinook_duckdb.main.Genre"))

  # use the extract (\code{[}) method to subset the dbi.table
  Album[AlbumId < 5, .(Title, nchar = paste(nchar(Title), "characters"))]

  # use csql to see the underlying SQL query
  csql(Album[AlbumId < 5, #WHERE
             .(Title, #SELECT
               nchar = paste(nchar(Title), "characters"))])

  \dontshow{DBI::dbDisconnect(duck)}

}
\seealso{
\itemize{
    \item \code{\link{as.data.frame}} to retrieve the
          \emph{results set} as a \code{data.frame},
    \item \code{\link{csql}} to see the underlying SQL query.
  }
}
