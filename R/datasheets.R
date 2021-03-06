# Copyright (c) 2017 Apex Resource Management Solution Ltd. (ApexRMS). All rights reserved.
# GPL v.3 License
#' @include AAAClassDefinitions.R
NULL

# This is a helper function - not exported in the NAMESPACE, but used internally
# datasheets
#
# Gets datasheet summary info from an SsimLibrary, Project or Scenario.
#
# @details
# See \code{\link{datasheet}} for discussion of optional/empty/sheetName/lookupsAsFactors arguments.
# \itemize{
#   \item {If x/project/scenario identify a scenario: }{Returns library, project, and scenario scope datasheets.}
#   \item {If x/project/scenario identify a project (but not a scenario): }{Returns library and project scope datasheets.}
#   \item {If x/project/scenario identify a library (but not a project or scenario): }{Returns library scope datasheets.}
# }
#
# @param x An SsimLibrary, Project or Scenario object. Or a path to a SyncroSim library on disk.
# @param project Project name or id. Ignored if x is a Project. 
# @param scenario Scenario name or id. Ignored if x is a Scenario.
# @param scope "scenario","project", "library", "all", or NULL.
# @param refresh If FALSE (default) names are retrieved from x@datasheetNames. If TRUE names are retrieved using a console call (slower).
# @return A dataframe of datasheet names.
# @examples
#
# @export
#Note: this function is now internal. Should now only be called from datasheet.
datasheets<-function(x,project=NULL,scenario=NULL,scope=NULL,refresh=F){
  if(!inherits(x,"SsimObject")){
    stop("expecting SsimObject.")
  }

  x = .getFromXProjScn(x,project,scenario)
  
  #Get datasheet dataframe
  if(!refresh){
    datasheets=x@datasheetNames
  }else{
    tt=command(c("list","datasheets","csv",paste0("lib=",.filepath(x))),.session(x))
    if(grepl("The library has unapplied updates",tt[[1]])){
      stop(tt)
    }
    datasheets = .dataframeFromSSim(tt,convertToLogical=c("isOutput","isSingle"))
    datasheets$scope = sapply(datasheets$scope,camel)
    #TO DO - export this info from SyncroSim
  }
  datasheets$order=seq(1,nrow(datasheets))
  if(!is.null(scope)&&(scope=="all")){
    datasheets$order=NULL
    return(datasheets)
  }
  if(is.element(class(x),c("Project","SsimLibrary"))){
    datasheets = subset(datasheets,scope!="scenario")
  }
  if(is.element(class(x),c("SsimLibrary"))){
    datasheets = subset(datasheets,scope!="project")
  }
  if(!is.null(scope)){
    if(!is.element(scope,c("scenario","project","library"))){
      stop("Invalid scope ",scope,". Valid scopes are 'scenario', 'project', 'library' and NULL.")
    }
    cScope=scope
    datasheets=subset(datasheets,scope==cScope)
  }
  datasheets=datasheets[order(datasheets$order),];datasheets$order=NULL
  return(datasheets)
}
