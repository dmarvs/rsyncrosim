# Copyright © 2017 Apex Resource Management Solution Ltd. (ApexRMS). All rights reserved.
# MIT License
#' @include AAAClassDefinitions.R
NULL

#' The name of a SyncroSim library, project or scenario.
#'
#' The name of an SsimLibrary, Project or Scenario.
#'
#' @param ssimObject SsimLibrary, Project, or Scenario.
#' @export
setGeneric('name',function(ssimObject) standardGeneric('name'))

#' Set ssimObject name.
#'
#' Set the name of a SyncroSim Project, Scenario or Library
#'
#' @param ssimObject Scenario/Project/SsimLibrary
#' @param value The new name.
#' @export
setGeneric('name<-',function(ssimObject,value) standardGeneric('name<-'))

setMethod('name', signature(ssimObject="SsimLibrary"), function(ssimObject) {
  #ssimObject=myLibrary
  cInfo = info(ssimObject)
  return(subset(cInfo,property=="Name:")$value)
})

setMethod('name', signature(ssimObject="Scenario"), function(ssimObject) {
  scnInfo = scenario(ssimObject,summary=T)
  return(scnInfo$name)
})

setMethod('name', signature(ssimObject="Project"), function(ssimObject) {
  info = project(ssimObject,summary=T)
  return(info$name)
})

setReplaceMethod(
  f='name',
  signature="SsimLibrary",
  definition=function(ssimObject,value){
    #x=myScenario;value="New Name"
    tt = command(list(setprop=NULL,lib=.filepath(ssimObject),name=value),.session(ssimObject))
    if(!identical(tt,"saved")){
      stop(tt)
    }
    return (ssimObject)
  }
)

setReplaceMethod(
  f='name',
  signature="Project",
  definition=function(ssimObject,value){
    #x=myProject;value="New Name"
    tt = command(list(setprop=NULL,lib=.filepath(ssimObject),pid=.projectId(ssimObject),name=value),.session(ssimObject))
    if(!identical(tt,"saved")){
      stop(tt)
    }
    return (ssimObject)
  }
)

setReplaceMethod(
  f='name',
  signature="Scenario",
  definition=function(ssimObject,value){
    #x=myScenario;value="New Name"
    tt = command(list(setprop=NULL,lib=.filepath(ssimObject),sid=.scenarioId(ssimObject),name=value),.session(ssimObject))
    if(!identical(tt,"saved")){
      stop(tt)
    }
    return (ssimObject)
  }
)