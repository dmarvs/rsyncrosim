# source("installRSyncroSim.R") # Install the most current version of rsyncrosim. See Readme-Development.txt for details.
# Copyright © 2017 Apex Resource Management Solution Ltd. (ApexRMS). All rights reserved.
# MIT License
#' @include AAAClassDefinitions.R
NULL

#' Get spatial inputs or outputs from a Scenario(s).
#'
#' Get spatial inputs or outputs from one or more SyncroSim scenarios.
#' @details
#'
#' The Color column of a rat table should have one of these formats:
#' \itemize{
#'   \item {R,G,B,alpha: } {4 numbers representing red, green, blue and alpha, separated by commas, and scaled between 0 and 255. See rgb() for details.}
#'   \item {R colour names: } {See colors() for options.}
#'   \item {hexadecimal colors: } {As returned by R functions such as rainbow(), heat.colors(), terrain.colors(), topo.colors(), gray(), etc.}
#' }
#'
#' The names() of the returned raster stack contain metadata.
#' For datasheets without Filename this is: paste0(<datasheet name>,".Scn",<scenario id>,".",<tif name>)
#' For datasheets containing Filename this is: paste0(<datasheet name>,".Scn",<scenario id>,".It",<iteration>,".Ts",<timestep>)
#'
#' @param ssimObject SsimLibrary/Project/Scenario or list of Scenarios. If SsimLibrary/Project, then scenario argument is required.
#' @param datasheet character string. The name of the datasheet containing the raster data.
#' @param column character string. The name of the column in the datasheet containing the filenames for raster data. If NULL then use the first column that contains raster filenames.
#' @param scenario character string, integer, or vector of these. The scenarios to include. Required if ssimObject is an SsimLibrary/Project, ignored if ssimObject is a list of Scenarios.
#' @param iteration integer, character string, or vector of integer/character strings. Iteration(s) to include. If NULL then all iterations are included. If no Iteration column in the datasheet, then ignored.
#' @param timestep integer, character string, or vector of integer/character string. Timestep(s) to include. If NULL then all timesteps are included.  If no Timestep column in the datasheet, then ignored.
#' @param subset logical expression. logical expression indicating datasheet rows to return. e.g. expression(grepl("Ts0001",Filename,fixed=T)). See subset() for details.
#' @param rat An (optional) raster attribute table. This is dataframe with ID, (optional) Color, and other columns. See raster::ratify() for details.
#' @param forceElements logical. If TRUE then returns a single raster as a RasterStack; otherwise returns a single raster as a RasterLayer directly.
#' @return A RasterLayer, RasterStack or RasterBrick object. See raster package documentation for details.
#' 
#' @examples 
#' 
#' datasheetRaster(myResult,datasheet="STSim_OutputSpatialState",subset=expression(grepl("Ts0001",Filename,fixed=T)))
#' @export
setGeneric('datasheetRaster',function(ssimObject,datasheet,column=NULL,scenario=NULL,iteration=NULL,timestep=NULL,subset=NULL,rat=NULL,forceElements=F) standardGeneric('datasheetRaster'))
setMethod('datasheetRaster', signature(ssimObject="list"), function(ssimObject,datasheet,column,scenario,iteration,timestep,subset,rat,forceElements) {
  # x= myResult; sheet="STSim_InitialConditionsSpatial";iterations=NULL;timesteps = NULL;rat=NULL
  if(class(ssimObject[[1]])!="Scenario"){
    stop("Expecting an SsimLibrary/Project/Scenario or list of Scenario objects.")
  }
  if(!is.null(scenario)){
    warning("scenario argument is ignored when ssimObject is a list of Scenarios")
    scenario=NULL
  }
  for(i in 1:length(ssimObject)){
    #i=1
    cScn = ssimObject[[i]]
    cOut = datasheetRaster(cScn,datasheet,column,scenario,iteration,timestep,subset,rat,forceElements)
    names(cOut)=paste0("scn",.scenarioId(cScn),".",names(cOut))
    if(i == 1){out=cOut}else{out=raster::stack(out,cOut)}
  }
  
  if((length(names(out))==1)&!forceElements){
    out=out[[1]]
  }
  return(out)
})

setMethod('datasheetRaster', signature(ssimObject="SsimObject"), function(ssimObject,datasheet,column,scenario,iteration,timestep,subset,rat,forceElements) {
  if(is.null(scenario)){
    stop("If ssimObject is an SimLibrary or Project, one or more scenarios must be specified using the scenario argument.")
  }
  scnSet = .scenario(ssimObject)
  missingScns = scenario
  if(is.character(scenario)){
    missingScns = setdiff(scenario,scnSet$name)
  }
  if(is.numeric(scenario)){
    missingScns = setdiff(scenario,scnSet$scenarioId)
  }  
  if(length(missingScns)>0){
    stop("Scenarios not found in ssimObject: ",paste(missingScns,collapse=","))
  }
  
  scnList = .scenario(ssimObject,scenario=scenario)
  scenario=NULL
  
  return(datasheetRaster(scnList,datasheet,column,scenario,iteration,timestep,subset,rat,forceElements))
  
})

setMethod('datasheetRaster', signature(ssimObject="Scenario"), function(ssimObject,datasheet,column,scenario,iteration,timestep,subset,rat,forceElements) {
  # scenario= myResult[[2]]; datasheet="STSim_InitialConditionsSpatial";column="AgeFileName";iteration=NULL;timestep = NULL;rat=NULL;subset=NULL;forceElements=F

  if(!is.null(scenario)){
    warning("scenario argument is ignored when ssimObject is a scenario.")
  }
  
  x=ssimObject  
  cSheets = .datasheets(x)
  if(!is.element(datasheet,cSheets$name)){
    cSheets = .datasheets(x,refresh=T)
  }
  #cSheets=subset(cSheets,isSpatial)
  #if(!is.element(sheet,cSheets$name)){
  #  stop(sheet," is not a spatial data sheet.")
  #}
  
  #TO DO: make sure datasheet is spatial after opening
  cMeta = .datasheet(x,name=datasheet,optional=T)
  
  if(nrow(cMeta)==0){
    multiband(x,action="rebuild")
    cMeta = .datasheet(x,name=datasheet,optional=T)
  }
  tt = command(list(list=NULL,columns=NULL,allprops=NULL,sheet=datasheet,csv=NULL,lib=.filepath(x)),session=.session(x))
  cPropsAll = .dataframeFromSSim(tt)
  cPropsAll$isRaster = grepl("isRaster^True",cPropsAll$properties,fixed=T)
  #get a valid raster column
  if(is.null(column)){
    column = cPropsAll$name[cPropsAll$isRaster][1]
    if(is.na(column)){
      stop("No raster columns found in datasheet ",datasheet)
    }
  }else{
    if(!is.element(column,cPropsAll$name)){
      stop("Column ",column," not found in datasheet ",datasheet)
    }
  }
  cProps = subset(cPropsAll,name==column)
  if(!cProps$isRaster){
    stop(column," is not a raster column.")
  }
  
  tryCount = 0
  while(tryCount <=1){
    warningMsg = ""
    if(!is.null(timestep)&is.element("Timestep",names(cMeta))){
      timestep=as.numeric(timestep)
      missSteps = setdiff(timestep,cMeta$Timestep)
      if(length(missSteps)>0){
        warningMsg = paste0("Selected timesteps not available: ",paste(missSteps,collapse=","))
      }
      cMeta = subset(cMeta,is.element(Timestep,timestep))
    }
    
    if(!is.null(iteration)&is.element("Iteration",names(cMeta))){
      iteration=as.numeric(iteration)
      missSteps = setdiff(iteration,cMeta$Iteration)
      if(length(missSteps)>0){
        warningMsg = paste0(warningMsg," Selected iterations not available: ",paste(missSteps,collapse=","))
      }
      cMeta = subset(cMeta,is.element(Iteration,iteration))
    }
    
    if((nchar(warningMsg)>0)|(nrow(cMeta)==0)){
      if(tryCount == 1){
        if(nrow(cMeta)==0){stop("No data available.")}else{
          warning(warningMsg)
        }
      }else{
        multiband(x,action="rebuild")
        cMeta = .datasheet(x,name=datasheet,optional=T)
      }
    }
    tryCount = tryCount+1
  }
  
  if(grepl("bandColumn",cProps$properties,fixed=T)){
    propSplit = strsplit(cProps$properties,"!",fixed=T)[[1]]
    bandBit = propSplit[grepl("bandColumn",propSplit)]
    bandColumn = strsplit(bandBit,"^",fixed=T)[[1]][2]
    cMeta$bandColumn = cMeta[[bandColumn]]
  }else{
    cMeta$bandColumn=NA
  }
  cMeta$rasterColumn=cMeta[[column]]
  
  #subset rows using subset argument
  if(!is.null(subset)){
    #subset=expression(grepl("Ts0001",Filename,fixed=T))
    cMeta = .subset(cMeta,eval(subset))
  }

  #Now cMeta contains bandColumn, rasterColumn, and only rows to be exported
  cMeta$outName = gsub(".tif","",basename(cMeta$rasterColumn),fixed=T)
  if(is.element("Timestep",names(cMeta))){
    tsReplaceBits =cMeta$Timestep
    tsReplaceBits[tsReplaceBits<10]=paste0("Ts000",tsReplaceBits[tsReplaceBits<10],"-")
    tsReplaceBits[(10<=tsReplaceBits)&(tsReplaceBits<100)]=paste0("Ts00",tsReplaceBits[(10<=tsReplaceBits)&(tsReplaceBits<100)],"-")
    tsReplaceBits[(100<=tsReplaceBits)&(tsReplaceBits<1000)]=paste0("Ts0",tsReplaceBits[(100<=tsReplaceBits)&(tsReplaceBits<1000)],"-")
    tsReplaceBits[(1000<=tsReplaceBits)&(tsReplaceBits<10000)]=paste0("Ts",tsReplaceBits[(1000<=tsReplaceBits)&(tsReplaceBits<10000)],"-")
    for(i in seq(length.out=length(tsReplaceBits))){
      cMeta$outName = gsub(tsReplaceBits[i],"",cMeta$outName,fixed=T)
    }
    cMeta$outName=paste0(cMeta$outName,".ts",cMeta$Timestep)
  }

  if(is.element("Iteration",names(cMeta))&&(length(setdiff(cMeta$Iteration,c(NA)))>0)){
    tsReplaceBits =cMeta$Iteration
    tsReplaceBits[tsReplaceBits<10]=paste0("It000",tsReplaceBits[tsReplaceBits<10],"-")
    tsReplaceBits[(10<=tsReplaceBits)&(tsReplaceBits<100)]=paste0("It00",tsReplaceBits[(10<=tsReplaceBits)&(tsReplaceBits<100)],"-")
    tsReplaceBits[(100<=tsReplaceBits)&(tsReplaceBits<1000)]=paste0("It0",tsReplaceBits[(100<=tsReplaceBits)&(tsReplaceBits<1000)],"-")
    tsReplaceBits[(1000<=tsReplaceBits)&(tsReplaceBits<10000)]=paste0("It",tsReplaceBits[(1000<=tsReplaceBits)&(tsReplaceBits<10000)],"-")
    for(i in seq(length.out=length(tsReplaceBits))){
      cMeta$outName = gsub(tsReplaceBits[i],"",cMeta$outName,fixed=T)
    }
    cMeta$outName=paste0(cMeta$outName,".it",cMeta$Iteration)
  }
  if((length(setdiff(NA,unique(cMeta$Band)))>0)&length(intersect(names(cMeta),c("Timestep","Iteration")))==0){
    cMeta$outName=paste0(cMeta$outName,".b",cMeta$bandColumn)
  }

  nFiles = unique(cMeta$rasterColumn)
  if((length(nFiles)==1)&(nrow(cMeta)>1)){
    if(!file.exists(nFiles)){
      addPath = paste0(.filepath(x),".output/Scenario-",.scenarioId(x),"/",datasheet,"/",nFiles)
      if(!file.exists(addPath)){
        stop("Output not found: ",nFiles)
      }
      cMeta$rasterColumn=addPath
    }
    cStack=raster::brick(cMeta$rasterColumn[1])
    
    cMeta$layerName = paste0(strsplit(nFiles,".",fixed=T)[[1]][1],".",cMeta$Band)
    
    keepLayers = intersect(names(cStack),cMeta$layerName)
    cStack = raster::subset(cStack,keepLayers)
    missing=setdiff(cMeta$layerName,names(cStack))
    if(length(missing)>0){
      warning("Some layers not found: ",paste(cMeta$outName[is.element(cMeta$layerName,missing)]))
    }
    cMeta=subset(cMeta,is.element(layerName,names(cStack)))
    
    for(i in 1:nrow(cMeta)){
      #i =1
      
      cRow =cMeta[i,]
      cName = cRow$layerName
      
      if(!is.null(rat)){
        obsVals = freq(cStack[[cName]])[,"value"]
        missingVals = setdiff(obsVals,c(NA,rat$ID))
        if(length(missingVals)>0){
          stop("Raster values not found in rat$ID: ",paste(missingVals,collapse=","))
        }
        #NOTE raster objects have a legend class but methods not yet implemented, except can store a color table
        #See colortable() for details
        ssimRatify(cStack[[cName]])=rat
        
      }
      cStack[[cName]]@title = cRow$outName
      
      names(cStack)[names(cStack)==cRow$layerName]=cRow$outName
      
    }
    #cStack = raster::brick(cStack)
  }else{
    
    for(i in 1:nrow(cMeta)){
      #i =1
      
      #install.packages("rgdal")
      cRow =cMeta[i,]
      if(is.na(cRow$rasterColumn)){next}
      if(!file.exists(cRow$rasterColumn)){
        #TO DO: path should already be there...
        addPath = paste0(.filepath(x),".output/Scenario-",.scenarioId(x),"/",datasheet,"/",cRow$rasterColumn)
        if(!file.exists(addPath)){
          stop("Output not found: ",cRow$rasterColumn)
        }
        cRow$rasterColumn=addPath
      }
      if(is.na(cRow$bandColumn)){
        cRaster = raster::raster(cRow$rasterColumn)
      }else{
        cRaster= raster::raster(cRow$rasterColumn,band=cRow$bandColumn)
      }
      
      if(!is.null(rat)){
        obsVals = raster::freq(cRaster)[,"value"]
        missingVals = setdiff(obsVals,c(NA,rat$ID))
        if(length(missingVals)>0){
          stop("Raster values not found in rat$ID: ",paste(missingVals,collapse=","))
        }
        #NOTE raster objects have a legend class but methods not yet implemented, except can store a color table
        
        ssimRatify(cRaster)=rat
      }
      cRaster@title = cRow$outName
      if(i==1){
        cStack = raster::stack(cRaster)
        names(cStack) = c(cRow$outName)
      }else{
        oldNames = names(cStack)
        cStack = raster::addLayer(cStack,cRaster)
        names(cStack)=c(oldNames,cRow$outName)
      }
    }
  }
  
  if((length(names(cStack))==1)&!forceElements){
    cStack = cStack[[1]]
  }
  return(cStack)
})
