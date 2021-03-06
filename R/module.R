# Copyright (c) 2017 Apex Resource Management Solution Ltd. (ApexRMS). All rights reserved.
# GPL v.3 License
#' @include AAAClassDefinitions.R
NULL

#' Installed modules
#'
#' Modules installed with this version of SyncroSim
#'
#' @param session Session.
#' @return A dataframe of modules
#' @export
setGeneric('module',function(session) standardGeneric('module'))
#' @rdname module
setMethod('module', signature(session="missingOrNULL"), function(session) {
  session=.session()
  return(module(session))
})
#' @rdname module
setMethod('module', signature(session="character"), function(session) {
  return(SyncroSimNotFound(session))
})
  
#' @rdname module
setMethod('module', signature(session="Session"), function(session) {
  tt = command(c("listmodules"),session,program="SyncroSim.ModuleManager.exe")
  if(tt[1]=="saved"){
    out=data.frame(name=NA,displayName=NA,version=NA)
    out=subset(out,!is.na(name))
  }else{
    out = .dataframeFromSSim(tt,colNames=c("name","displayName","version"),csv=F)
  }
  return(out)
})
