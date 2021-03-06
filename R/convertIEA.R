#' Convert IEA
#' 
#' Convert IEA energy data to data on ISO country level.
#' 
#' 
#' @param x MAgPIE object containing IEA values at IEA mixed country-region
#' resolution
#' @param subtype data subtype. Either "EnergyBalances" or "CHPreport"
#' @return IEA data as MAgPIE object aggregated to country level
#' @author Anastasis Giannousakis, Renato Rodrigues
 
convertIEA <- function(x,subtype) {

  if(subtype == "EnergyBalances"){
    # aggregate Kosovo to Serbia
    x1 <- x["KOS",,]
    getRegions(x1) <- c("SRB")
    x["SRB",,] <- x["SRB",,] + x1
    x <- x[c("KOS"),,,invert=TRUE]
    # convert electricity outputs (unit conversion between ktoe and GWh)
    x[,,c("ELOUTPUT","ELMAINE","ELAUTOE","ELMAINC","ELAUTOC")] <- x[,,c("ELOUTPUT","ELMAINE","ELAUTOE","ELMAINC","ELAUTOC")] * 0.0859845
    # disaggregating Other Africa (IAF), Other non-OECD Americas (ILA) and Other non-OECD Asia (IAS) regions to countries
    mappingfile <- toolMappingFile("regional","regionmappingIEA.csv")
    mapping <- read.csv2(mappingfile)
    wp <- calcOutput("Population",aggregate=F,FiveYearSteps = F)[as.vector(mapping[[1]]),2010,"pop_SSP2"]
    wg <- calcOutput("GDPppp",aggregate=F,FiveYearSteps = F)[as.vector(mapping[[1]]),2010,"gdp_SSP2"]
    wp <- wp/max(wp);getNames(wp)<-"SSP2"
    wg <- wg/max(wg);getNames(wg)<-"SSP2"
    xadd <- toolAggregate(x[levels(mapping[[2]]),,],mappingfile,weight=wp+wg)
    x <- x[setdiff(getRegions(x),as.vector(unique(mapping[[2]]))),,]
    x <- mbind(x,xadd)
    # dealing with extinct countries 
    ISOhistorical <- read.csv2(system.file("extdata","ISOhistorical.csv",package = "moinput"),stringsAsFactors = F)
    x[is.na(x)] <- 0
    x <- toolISOhistorical(x,mapping=ISOhistorical[!ISOhistorical$toISO=="SCG",])
    # filling missing country data
    x<-toolCountryFill(x,0)
  } else if (subtype == "CHPreport") {
    # adjust the share for some region to avoid infeasibilities in the initial year
    x["RUS",,] <- 70
    x[c("BGR","CZE","POL","ROU","SVK"),,] <- 70
    x[c("BEL","LUX","NLD"),,] <- 40
  }
  
  
  return(x)
}  
