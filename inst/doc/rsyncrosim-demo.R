# ********************************************
# rsyncrosim-demo.R - Demonstration of the rsyncrosim package (using the SyncroSim ST-Sim module)
# 
# **********************************************************

# *************************************************************
# File/Package Setup
# *************************************************************

library(rsyncrosim)
library(raster)      # raster package required to work with spatial data

# Get the filenames for the sample raster TIF files used in this script
stratumTif = system.file("extdata", "initial-stratum.tif", package = "rsyncrosim")
sclassTif = system.file("extdata", "initial-sclass.tif", package = "rsyncrosim")
ageTif = system.file("extdata", "initial-age.tif", package = "rsyncrosim")

# Set the name of the folder into which you installed SyncroSim  (i.e. this folder should contain the file SyncroSim.Console.exe)
programFolder = "C:/Program Files/SyncroSim"

# *************************************************************
# Start Session & Create Library
# *************************************************************

# Start a SyncroSim session & list the currently loaded modules
mySession = session(programFolder)
module(mySession)     # Corresponds to the 'Add-Ons' tab under the 'File-Library Properties' menu in SyncroSim


# Add the ST-Sim module to this session (& then check that it is now loaded)
stsimPackageFilename = paste(programFolder, "Packages/stsim.ssimpkg", sep="/")
addModule(stsimPackageFilename, mySession)
module(mySession)

# Create a new ST-Sim library in the current working directory (or load it if it already exists)
getwd()
myLibrary = ssimLibrary(name="Demonstration Library", model="stsim", session=mySession)

# Note that you can be helful to have this library open in the SyncroSim user interface at the same time you are modifying the library in R.
# This way, by periodically invoking the 'File-Refresh All Libraries' menu in SyncroSim, you can then see the latest changes you made in R

# Display internal names of all the library's datasheets - corresponds to the the 'File-Library Properties' menu in SyncroSim
(librarySheetNames = datasheet(myLibrary, summary=T))

# Modify library datasheet to include input spatial files in backups
sheetName = "SSim_Backup"
sheetData = datasheet(myLibrary, name=sheetName)                            # Get the current backup settings for the library
sheetData = addRow(sheetData, data.frame(IncludeInput=T, IncludeOutput=F))  # Add a new row to this dataframe
saveDatasheet(myLibrary, data=sheetData, name=sheetName)                    # Save the new dataframe back to the library
(datasheet(myLibrary, sheetName)) 
# Backup the library before making changes
backup(myLibrary)

# *************************************************************
# Create Project
# *************************************************************

# Create a new SyncroSim project (or open it if it already exists)
myProject = project(myLibrary, project="Simple forest landscape")

# Display internal names of all the project's datasheets
(projectSheetNames=datasheet(myProject, summary=T, optional=F))

# Edit the Project Definitions - corresponds to the 'Project-Properties' menu in SyncroSim

# Terminology
(sheetData = datasheet(myProject, "STSim_Terminology"))
str(sheetData)
sheetData$AmountUnits[1] = "Hectares"
sheetData$StateLabelX[1] = "Forest Type"
saveDatasheet(myProject, sheetData, "STSim_Terminology")
(sheetData = datasheet(myProject, "STSim_Terminology"))

# Stratum
sheetData = datasheet(myProject, "STSim_Stratum", empty=T)   # Returns empty dataframe with only required column(s)
sheetData = addRow(sheetData, "Entire Forest")
saveDatasheet(myProject, sheetData, "STSim_Stratum", force=T)
datasheet(myProject, "STSim_Stratum", optional=T)   # Returns entire dataframe, including optional columns

# First State Class Label (i.e. Forest Types)
forestTypes = c("Coniferous", "Deciduous", "Mixed")
saveDatasheet(myProject, data.frame(Name=forestTypes), "STSim_StateLabelX", force=T)

# Second State Label (not used)
saveDatasheet(myProject, data.frame(Name=c("All")), "STSim_StateLabelY", force=T)

# Transition Types
transitionTypes = data.frame(Name=c("Fire", "Harvest", "Succession"), ID=c(1,2,3))
saveDatasheet(myProject, transitionTypes, "STSim_TransitionType", force=T)

# Transition Groups - make the Groups identical to the Types
transitionGroups = data.frame(Name=c("Fire", "Harvest", "Succession"))
saveDatasheet(myProject, transitionGroups, "STSim_TransitionGroup", force=T)

# Transition Types by Groups  - assign each Type to its Group
transitionTypesGroups = data.frame(TransitionTypeID=transitionTypes$Name, TransitionGroupID=transitionGroups$Name)
saveDatasheet(myProject, transitionTypesGroups, "STSim_TransitionTypeGroup", force=T)

# State Classes
stateClasses = data.frame(Name=forestTypes)
stateClasses$StateLabelXID = stateClasses$Name
stateClasses$StateLabelYID = "All"
stateClasses$ID = c(1,2,3)
saveDatasheet(myProject, stateClasses, "STSim_StateClass", force=T)

# Ages
ageFrequency = 1
ageMax = 101
ageGroups = c(20,40,60,80,100)
saveDatasheet(myProject, data.frame(Frequency=ageFrequency, MaximumAge=ageMax), "STSim_AgeType", force=T)
saveDatasheet(myProject, data.frame(MaximumAge=ageGroups), "STSim_AgeGroup", force=T)

# *************************************************************
# Create Scenarios
# *************************************************************

# Create/open a SyncroSim "No Harvest" scenario
myScenario = scenario(myProject, "No Harvest")

# Display the internal names of all the scenario datasheets - these correspond to the 'Scenario-Properties' menu in SyncroSim (when a Scenario is selected)
(scenarioSheetNames=subset(datasheet(myScenario, summary=T), scope=="scenario"))

# Edit the scenario datasheets:

# Run Control - Note that we will set this as a spatial run
sheetName = "STSim_RunControl"
sheetData = data.frame(MaximumIteration=7, MinimumTimestep=0, MaximumTimestep=50, isSpatial=T)
saveDatasheet(myScenario, sheetData, sheetName)

# States
sheetName = "STSim_DeterministicTransition"
sheetData = datasheet(myScenario, sheetName , optional=T, empty=T)
sheetData = addRow(sheetData, data.frame(StateClassIDSource="Coniferous:All",StateClassIDDest="Coniferous:All",AgeMin=21,Location="C1"))
sheetData = addRow(sheetData, data.frame(StateClassIDSource="Deciduous:All",StateClassIDDest="Deciduous:All",Location="A1"))
sheetData = addRow(sheetData, data.frame(StateClassIDSource="Mixed:All",StateClassIDDest="Mixed:All",AgeMin=11,Location="B1"))
saveDatasheet(myScenario, sheetData, sheetName)

# Probabilistic Transitions
sheetName = "STSim_Transition"
sheetData = datasheet(myScenario, sheetName , optional=T, empty=T)
sheetData = addRow(sheetData, data.frame(StateClassIDSource="Coniferous:All",StateClassIDDest="Deciduous:All", TransitionTypeID="Fire",Probability=0.01))
sheetData = addRow(sheetData, data.frame(StateClassIDSource="Coniferous:All",StateClassIDDest="Deciduous:All", TransitionTypeID="Harvest",Probability=1,AgeMin=40))
sheetData = addRow(sheetData, data.frame(StateClassIDSource="Deciduous:All",StateClassIDDest="Deciduous:All", TransitionTypeID="Fire",Probability=0.002))
sheetData = addRow(sheetData, data.frame(StateClassIDSource="Deciduous:All",StateClassIDDest="Mixed:All", TransitionTypeID="Succession",Probability=0.1,AgeMin=10))
sheetData = addRow(sheetData, data.frame(StateClassIDSource="Mixed:All",StateClassIDDest="Deciduous:All", TransitionTypeID="Fire",Probability=0.005))
sheetData = addRow(sheetData, data.frame(StateClassIDSource="Mixed:All",StateClassIDDest="Coniferous:All", TransitionTypeID="Succession",Probability=0.1,AgeMin=20))
saveDatasheet(myScenario, sheetData, sheetName)

# There are two options for setting initial conditions: either spatial or non-spatial
# In this example we will use spatial initial conditions; however we demonstrate below how also to set initial conditions non-spatially

# Initial Conditions: Option 1 - Spatial

# Load sample rasters (for initial conditions)
rStratum = raster(stratumTif)
rSclass = raster(sclassTif)
rAge = raster(ageTif)
plot(rStratum)
plot(rSclass)
plot(rAge)

# Put these rasters in the SyncroSim library for this scenario
sheetName = "STSim_InitialConditionsSpatial"
sheetData = data.frame(StratumFileName=stratumTif, StateClassFileName=sclassTif, AgeFileName=ageTif)
saveDatasheet(myScenario, sheetData, sheetName)
datasheet(myScenario, sheetName)

# Check rasters correcly loaded
rStratumTest = datasheetRaster(myScenario, sheetName, "StratumFileName")
rSclassTest = datasheetRaster(myScenario, sheetName, "StateClassFileName")
rAgeTest = datasheetRaster(myScenario, sheetName, "AgeFileName")
plot(rStratumTest)
plot(rSclassTest)
plot(rAgeTest)

# Initial Conditions: Option 2 - Non-spatial

sheetName = "STSim_InitialConditionsNonSpatial"
sheetData = data.frame(TotalAmount=100, NumCells=100, CalcFromDist=F)
saveDatasheet(myScenario, sheetData, sheetName)
datasheet(myScenario, sheetName)

sheetName = "STSim_InitialConditionsNonSpatialDistribution"
sheetData = data.frame(StratumID="Entire Forest", StateClassID="Coniferous:All", RelativeAmount=1)
saveDatasheet(myScenario, sheetData, sheetName)
datasheet(myScenario, sheetName)

# Transition targets - set harvest to 0 for this scenario
saveDatasheet(myScenario, data.frame(TransitionGroupID="Harvest", Amount=0), "STSim_TransitionTarget")

# Output options
datasheet(myScenario, "STSim_OutputOptions")
sheetData = data.frame(SummaryOutputSC=T, SummaryOutputSCTimesteps=1,
                       SummaryOutputTR=T, SummaryOutputTRTimesteps=1,
                       RasterOutputSC=T, RasterOutputSCTimesteps=1,
                       RasterOutputTR=T, RasterOutputTRTimesteps=1,
                       RasterOutputAge=T, RasterOutputAgeTimesteps=1)
saveDatasheet(myScenario, sheetData, "STSim_OutputOptions")

# Create a second "Harvest" scenario that is a copy of the first scenario, but with a harvest level of 20 acres/timestep
myScenarioHarvest = scenario(myProject, scenario="Harvest", sourceScenario=myScenario)
saveDatasheet(myScenarioHarvest, data.frame(TransitionGroupID="Harvest", Amount=20), "STSim_TransitionTarget")

# Show the harvest levels for both scenarios
datasheet(myProject, scenario = c("Harvest", "No Harvest"), name= "STSim_TransitionTarget")

# *************************************************************
# Run Scenarios & Get Results
# *************************************************************

# Run both scenarios - each Monte Carlo iteration is run in parallel as a separate multiprocessing job
(resultSummary = run(myProject, scenario=c("Harvest", "No Harvest"), jobs=7, summary=T))

# Get the scenario IDs of the 2 result scenarios
resultIDNoHarvest = subset(resultSummary, parentID==scenarioId(myScenario))$scenarioId
resultIDHarvest = subset(resultSummary, parentID==scenarioId(myScenarioHarvest))$scenarioId

# Get a dataframe of the state class tabular output (for both scenarios combined)
outputStratumState = datasheet(myProject, scenario=c(resultIDNoHarvest,resultIDHarvest), name="STSim_OutputStratumState")
str(outputStratumState)
head(outputStratumState)

# Get state class raster output (for the Harvest scenario only)
myRastersTimestep5 = datasheetRaster(myProject, scenario=resultIDHarvest, "STSim_OutputSpatialState", timestep=5)
myRastersTimestep5
plot(myRastersTimestep5)
