# Copyright (c) 2017 Apex Resource Management Solution Ltd. (ApexRMS). All rights reserved.
# GPL v.3 License
#' @include AAAClassDefinitions.R
NULL

# @name SsimLibrary
# @rdname SsimLibrary-class
setMethod(f='initialize',signature="SsimLibrary",
    definition=function(.Object,name=NULL,model=NULL,session=NULL,addon=NULL,forceUpdate=F,create=T){
    #if a syncrosim session is not provided, make one
    enabled=NULL
    if(is.null(session)){
      session = .session()
    }
    if(is.character(session)){
      session=.session(session)
    }

    inName = name
    inModel=model
    if(is.null(name)){
      name="SsimLibrary.ssim"
    }
          
    if(is.null(model)){
      model=defaultModel(session) #assume validity of session object has already been checked.
    }else{
      modelOptions = model(session)
      if(!is.element(model,modelOptions$name)){
        stop(paste("Model type",model,"not recognized. Options are:",paste0(modelOptions$name,collapse=",")))
      }
    }
    
    if (identical(basename(name), name)) {
      path = file.path(getwd(), name)
    }else{path=name}
    if(!grepl(".ssim",path)) path=paste0(path,".ssim")

    #if library does not exist on disk, create it
    if(!file.exists(path)){
      if(!create){
        stop(paste0("Library not found: ",path))
      }
      if(is.null(model)){
        stop('Specify a model for the new library.')
      }
      pathBits = strsplit(path,"/")[[1]]
      dir.create(paste(head(pathBits,-1),collapse="/"),showWarnings=F)
      
      if(!exists("modelOptions")){
        modelOptions = model(session)
      }

      args = list(create=NULL,library=NULL,name=path,model=modelOptions$name[modelOptions$name==model])
      cStatus = command(args,session)
      if(cStatus[1]!="saved"){
        stop("Problem creating library: ",tt[1])
      }
    }

    #ensure the primaryModule specified matches the primaryModule on disk
    args = c("list","datasheets","csv",paste0("lib=",path))
    tt=command(args,session)
    if(grepl("The library has unapplied updates",tt[[1]])){
      if(is.null(inName)|forceUpdate){answer ="y"}else{
        answer <- readline(prompt=paste0("The library has unapplied updates. Do you want to update ",path,"? (y/n): "))
      }
      if(answer=="y"){
        updateMessage = command(list(update=NULL,lib=path),session)

        if(grepl("Update complete",updateMessage,fixed=T)){
          updateMessage = "saved"
        }

        if(!identical(updateMessage,"saved")){
          stop(updateMessage)
        }

      }else{
        stop("Cannot open a library with unapplied updates.")
      }
      tt = command(args,session)
    }else{
      if(grepl("The library ",tt[[1]])){
        stop("Problem loading library: ",tt[1]) 
      }    
    }

    datasheets = .dataframeFromSSim(tt,convertToLogical=c("isOutput","isSingle"))
    datasheets$scope = sapply(datasheets$scope,camel)

    if(!is.null(inModel)){
      args = list(list=NULL,library=NULL,csv=NULL,lib=path)
      tt = command(args,session)
      tt = .dataframeFromSSim(tt)
      if(ncol(tt)<2){
        stop(command(args,session))
      }
      
      if(!exists("modelOptions")){modelOptions=model(session)}
      expectedModule = modelOptions$name[modelOptions$name==model]
      if(!grepl(expectedModule,tt$value[tt$property=="Model Name:"])){
        stop(paste0("A library of that name and a different model type ",tt$value[tt$property=="Model Name:"]," already exists."))
      }
    }

    if(!is.null(addon)){
      tt = command(list(list=NULL,addons=NULL,csv=NULL,lib=path),session)
      tt = .dataframeFromSSim(tt)
      cAdds = subset(tt,enabled=="Yes")
      addon=setdiff(addon,cAdds$name,fixed=T)

      for(i in seq(length.out=length(addon))){
        #i=1
        tt = command(list(create=NULL,addon=NULL,lib=path,name=addon[i]),session)
        if(tt[[1]]!="saved"){
          stop("Problem with addon ",addon[i],": ",tt[[1]])
        }
      }
    }

    .Object@session=session
    .Object@filepath=path
    .Object@datasheetNames=datasheets
    return(.Object)
  }
)

setGeneric('.ssimLibrary', function(name = NULL, model = NULL, session = NULL, addon = NULL, forceUpdate = F, create = F) standardGeneric('.ssimLibrary'))

setMethod('.ssimLibrary',signature(name="missingOrNULLOrChar"),function(name,model,session,addon,forceUpdate,create) {
  return(new("SsimLibrary",name,model,session,addon,forceUpdate,create))
})

setMethod('.ssimLibrary', signature(name="SsimObject"), function(name,model,session,addon,forceUpdate,create) {
  if(class(name)=="SsimLibrary"){
    out=name
  }else{
    out = .ssimLibrary(name=.filepath(name),session=.session(name),create=F)
  }
  return(out)
})

#' Create or open a library.
#'
#' Creates or opens an \code{\link{SsimLibrary}} object representing a SyncroSim library.
#' If summary = T, returns library summary info. 
#' If summary = NULL, returns library summary info if ssimObject is an SsimLibrary, SsimLibrary object otherwise.
#'
#' @export
#' @details
#' 
#' \itemize{
#'   \item {If name is SyncroSim Project or Scenario: }{Returns the \code{\link{SsimLibrary}} associated with the Project or Scenario.}
#'   \item {If name is NULL: }{Create/open a SsimLibrary in the current working directory with the filename SsimLibrary.ssim.}
#'   \item {If name is a string: }{If string is not a valid path treat as filename in working directory. If no file suffix provided in string then add .ssim. Attempts to open a library of that name. If library does not exist creates a library of type model in the current working directory.}
#'   \item {If given a name and a model: }{Create/open a library called <name>.ssim. Returns an error if the library already exists but is a different type of model.}
#' }
#' @param name Character string, Project/Scenario/SsimLibrary. The path to a library or SsimObject. Optional.
#' @param summary logical. Default T
#' @param model Character. The model type. If NULL, defaultModel(session()) will be used.
#' @param session Session. If NULL, session() will be used.
#' @param addon Character or character vector. One or more addons. See addon() for options.
# @param backup Logical. If TRUE, a backup copy is made when an existing library is opened.
# @param backupName Character. Added to a library filepath to create a backup library.
# @param backupOverwrite Logical. If TRUE, the existing backup of a library (if any) will be overwritten.
#' @param forceUpdate Logical. If FALSE (default) user will be prompted to approve any required updates. If TRUE, required updates will be applied silently.
#' @return An \code{SsimLibrary} object representing a SyncroSim library.
#' @examples
#' #TODO - update examples
#' # See the installed models
#' model(session())
#'
#' # Create a library called <model>.ssim in the current working directory.
#' myLibrary = ssimLibrary()
#' session(myLibrary) #The SycroSim session
#' filepath(myLibrary) #Path to the file on disk.
#' info(myLibrary) #Model type and other library information.
#'
#' # Open an existing SyncroSim library in the current working directory - don't make a backup copy.
#' myLibrary = ssimLibrary()
#'
#' # Create a library with a name in the current working directory
#' mySecondLibrary = ssimLibrary(name="Lib2")
#'
#' # Create a library with a name in another directory
#' myThirdLibrary = ssimLibrary(name=paste0(getwd(),"/Temp/Lib3"))
#'
#' # Create or load a library using a specific session
#' mySession = session("C:/Program Files/SyncroSim/1/SyncroSim.Console.exe")
#' myLibrary = ssimLibrary(name="Lib2",session=mySession)
#'
#' # Add a project and get the library associated with that project
#' myProject = project(myLibrary,project="a project")
#' myLibrary = ssimLibrary(myProject)
#' @export
setGeneric('ssimLibrary',function(name=NULL,summary=NULL,model=NULL,session=NULL,addon=NULL,forceUpdate=F) standardGeneric('ssimLibrary'))

#' @rdname ssimLibrary
setMethod('ssimLibrary', signature(name="SsimObject"), function(name,summary,model,session,addon,forceUpdate) {
  if(class(name)=="SsimLibrary"){
    out=name
    if(is.null(summary)){summary=T}
  }else{
    out = .ssimLibrary(name=.filepath(name),session=.session(name),create=F)
    if(is.null(summary)){summary=F}
  }
  if(!summary){
    return(out)
  }
  return(info(out))
})

#' @rdname ssimLibrary
setMethod('ssimLibrary',signature(name="missingOrNULLOrChar"),function(name=NULL,summary=NULL,model,session,addon,forceUpdate) {
            
    if(is.null(session)){session=.session()}
    if((class(session)=="character")&&(session==SyncroSimNotFound(warn=F))){
      return(SyncroSimNotFound())
    }
            
    newLib = new("SsimLibrary",name,model,session,addon,forceUpdate,create=T)
    if(!is.null(summary)&&summary){
      return(info(newLib))
    }
    return(newLib)
})

# Information about an library
#
# Get basic information about a Library. 
# Use project(summary==T) and scenario(summary=T) to get similar information about Project/Scenario
#
# @param ssimLibrary SsimLibrary.
# @export
setGeneric('info', function(ssimLibrary) standardGeneric('info'))

setMethod('info', signature(ssimLibrary="SsimLibrary"), function(ssimLibrary) {
  args = list(list=NULL,library=NULL,csv=NULL,lib=.filepath(ssimLibrary))
  tt = command(args,.session(ssimLibrary))
  out = .dataframeFromSSim(tt,localNames=T)
  return(out)
})

# Delete Library - internal helper function
#
# Deletes a SyncroSim library. Note this is irreversable.
#
# @param ssimLibrary SsimLibrary or path to a library
# @param force Logical. If FALSE (default) prompt to confirm that the library should be deleted. This is irreversable.
# @return "saved" or failure message.
# @examples
#
# @export
setGeneric('deleteLibrary', function(ssimLibrary, force = F) standardGeneric('deleteLibrary'))

setMethod('deleteLibrary', signature(ssimLibrary="SsimLibrary"), function(ssimLibrary,force) {
  return(deleteLibrary(.filepath(ssimLibrary),force))
})

setMethod('deleteLibrary', signature(ssimLibrary="character"), function(ssimLibrary,force) {
  
  if(!file.exists(ssimLibrary)){
    return(paste0("Library not found: ",ssimLibrary))
  }
  if(force){
    answer="y"
  }else{
    answer <- readline(prompt=paste0("Do you really want to delete library ",ssimLibrary,"? (y/n): "))
  }
  if(answer=="y"){
    unlink(ssimLibrary)
    if(file.exists(ssimLibrary)){
      return(paste0("Failed to delete ",ssimLibrary))
    }
    
    unlink(paste0(ssimLibrary,".backup"),recursive=T,force=T)
    unlink(paste0(ssimLibrary,".input"),recursive=T,force=T)
    unlink(paste0(ssimLibrary,".output"),recursive=T,force=T)
    
    return("saved")
  }else{
    return("skipped")
  } 
})



