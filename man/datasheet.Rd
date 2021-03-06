% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/datasheet.R
\docType{methods}
\name{datasheet}
\alias{datasheet}
\alias{datasheet,list-method}
\alias{datasheet,character-method}
\alias{datasheet,SsimObject-method}
\title{Get a datasheet}
\usage{
datasheet(ssimObject, name = NULL, project = NULL, scenario = NULL,
  summary = NULL, optional = F, empty = F, lookupsAsFactors = T,
  sqlStatement = list(select = "SELECT *", groupBy = ""), forceElements = F)

\S4method{datasheet}{list}(ssimObject, name = NULL, project = NULL,
  scenario = NULL, summary = NULL, optional = F, empty = F,
  lookupsAsFactors = T, sqlStatement = list(select = "SELECT *", groupBy =
  ""), forceElements = F)

\S4method{datasheet}{character}(ssimObject, name = NULL, project = NULL,
  scenario = NULL, summary = NULL, optional = F, empty = F,
  lookupsAsFactors = T, sqlStatement = list(select = "SELECT *", groupBy =
  ""), forceElements = F)

\S4method{datasheet}{SsimObject}(ssimObject, name = NULL, project = NULL,
  scenario = NULL, summary = NULL, optional = F, empty = F,
  lookupsAsFactors = T, sqlStatement = list(select = "SELECT *", groupBy =
  ""), forceElements = F)
}
\arguments{
\item{ssimObject}{SsimLibrary/Project/Scenario, or list of objects. Note that all objects in a list must be of the same type, and belong to the same library.}

\item{name}{Character or vector of these. Sheet name(s). If NULL, all datasheets in the ssimObject will be returned. Note that setting summary=F and name=NULL pulls all datasheets, which is timeconsuming and not generally recommended.}

\item{project}{Character, numeric, or vector of these. One or more Project names, ids or objects. Note that integer ids are slightly faster.}

\item{scenario}{Character, numeric, or vector of these. One or more Scenario names, ids or objects. Note that integer ids are slightly faster.}

\item{summary}{Logical. If TRUE returns a dataframe of sheet names and other info. If FALSE returns dataframe or list of dataframes.}

\item{optional}{Logical. If summary=TRUE and optional=TRUE returns only scope, name and displayName. If summary=FALSE and optional=TRUE returns all of the datasheet's columns, including the optional columns. If summary=TRUE, optional=FALSE, returns only those columns that are mandatory and contain data (if empty=F). Ignored if summary=F, empty=F and lookupsAsFactors=F.}

\item{empty}{Logical. If TRUE returns empty dataframes for each datasheet. Ignored if summary=TRUE.}

\item{lookupsAsFactors}{Logical. If TRUE (default) dependencies returned as factors with allowed values (levels). Set FALSE to speed calculations. Ignored if summary=TRUE.}

\item{sqlStatement}{List returned by sqlStatement(). SELECT and GROUP BY SQL statements passed to SQLite database. Ignored if summary=TRUE.}

\item{forceElements}{Logical. If FALSE and name has a single element returns a dataframe; otherwise a list of dataframes. Ignored if summary=TRUE.}
}
\value{
If summary=T returns a dataframe of datasheet names and other info, otherwise returns a dataframe or list of these.
}
\description{
Gets Syncrosim datasheet.
}
\details{
If summary=T or summary=NULL and name=NULL a dataframe describing the datasheets is returned:
  If optional=T columns include: scope, module, name, displayName, isSingle, isOutput, data. 
  data only displayed for scenarios. dataInherited and dataSource columns added if a scenario has dependencies.
  If optional=F columns include: scope, name, displayName.
  All other arguments are ignored.

Otherwise, for each element in name a datasheet is returned as follows:
\itemize{
  \item {If lookupsAsFactors=T (default): }{Each column is given the correct data type, and dependencies returned as factors with allowed values (levels). A warning is issued if the lookup has not yet been set.}
  \item {If empty=T: }{Each column is given the correct data type. Fast (1 less console command)}
  \item {If empty=F and lookupsAsFactors=F: }{Column types are not checked, and the optional argument is ignored. Fast (1 less console command).}
  \item {If ssimObject is a list of Scenario or Project objects (output from run(), scenario() or project()): }{Adds ScenarioID/ProjectID column if appropriate.}
  \item {If scenario/project is a vector: }{Adds ScenarioID/ProjectID column as necessary.}
  \item {If requested datasheet has scenario scope and contains info from more than one scenario: }{ScenarioID/ScenarioName/ScenarioParent columns identify the scenario by name, id, and parent (if a result scenario)}
  \item {If requested datasheet has project scope and contains info from more than one project: }{ProjectID/ProjectName columns identify the project by name and id.}
}
}
