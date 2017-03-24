# =============================================================================
#                           ECN Data Load
#
# Script to transform the RAW database observations and metadata into a SensorML 
#   representation of the sensors, and an O&M representation of their observations
# =============================================================================


# =============================================================================
# Libraries 
# =============================================================================

# Used to read larger csv files
library(readr)

# Used for data manipulation
library(dplyr)
library(reshape2)
library(stringr)
library(lubridate)

# Used to communicate with the SOS server
library(httr)

# Used to parallelise the http requests to the SOS server
library(doParallel)

# Used to remove the scientific representation of large numbers
options(scipen = 999)

# =============================================================================
# Initial RAW data loading 
# =============================================================================

# Set the directory with the csv files
setwd('~/Data/ECN_SWE_Data')

# Data loading
# ===========================================================

# Read the observational data
data_files <- c("T04_MoorHouse_UpperTeesdale.csv")

obs_data <- c()

for (dataf in data_files) {
  temp_data = read_csv(dataf)
  obs_data = rbind(obs_data, temp_data)
}

obs_data$FULL_TIMESTAMP <- 
  ymd_hms(obs_data$SDATE) + hours(obs_data$SHOUR)

obs_data$FIELDNAME[obs_data$FIELDNAME == 'DRYTMP_'] <- 'DRYTMP_RH'
obs_data$FIELDNAME[obs_data$FIELDNAME == 'SWATER'] <- 'SWATER_VWC'
obs_data$FIELDNAME[obs_data$FIELDNAME == 'SWATER_'] <- 'SWATER_VWC'

# Read the site data
site_data <- read_csv("~/Data/ECN_SWE_Data/m_site.csv")

site_data <- site_data %>%
  select(SITECODE:SHORTDESC)

# Read the site location data and select the columns
#  of interest
location_data <- read_csv('~/Data/ECN_SWE_Data/m_location.csv')

location_data <- location_data %>%
  select(LOCID, SITECODE, LAT_WGS84, LONG_WGS84, ALTREF)

# Read the sensor data and select the columns of 
#  interest
sensor_data <- read_csv('~/Data/ECN_SWE_Data/M_SENSOR.csv')

sensor_data <- sensor_data %>%
  select(FIELDNAME:MAKEMODEL)

# Set the SOS server URL 
url <- 'http://127.0.0.1:8080/observations/service'


# Data manipulation
# ===========================================================

# Set the observed property (the link to EnvThes definition is used,
#   but the preferred label is manually entered here for the input/output
#   textual names).
sensor_data$obs_prop <- NA
sensor_data$obs_pref_label <- NA

sensor_data$obs_prop[sensor_data$DESCRIPTION == 'Albedo (ground)'] <- 
  'http://vocabs.lter-europe.net/EnvThes/EnvEu_113'
sensor_data$obs_pref_label[sensor_data$DESCRIPTION == 'Albedo (ground)'] <- 
  'albedo'

sensor_data$obs_prop[sensor_data$DESCRIPTION == 'Albedo (sky)'] <- 
  'http://vocabs.lter-europe.net/EnvThes/EnvEu_113'
sensor_data$obs_pref_label[sensor_data$DESCRIPTION == 'Albedo (sky)'] <- 
  'albedo'

sensor_data$obs_prop[sensor_data$DESCRIPTION == 'Dry bulb temperature'] <- 
  'http://vocabs.lter-europe.net/EnvThes/USLterCV_22'
sensor_data$obs_pref_label[sensor_data$DESCRIPTION == 'Dry bulb temperature'] <- 
  'air temperature'

sensor_data$obs_prop[sensor_data$DESCRIPTION == 'Dry bulb temperature within the relative humidity sensor'] <- 
  'http://vocabs.lter-europe.net/EnvThes/USLterCV_22'
sensor_data$obs_pref_label[sensor_data$DESCRIPTION == 'Dry bulb temperature within the relative humidity sensor'] <- 
  'air temperature'

sensor_data$obs_prop[sensor_data$DESCRIPTION == 'Net radiation'] <- 
  'http://vocabs.lter-europe.net/EnvThes/EnvEu_107'
sensor_data$obs_pref_label[sensor_data$DESCRIPTION == 'Net radiation'] <- 
  'net solar radiation'

sensor_data$obs_prop[sensor_data$DESCRIPTION == 'Solar radiation'] <- 
  'http://vocabs.lter-europe.net/EnvThes/USLterCV_536'
sensor_data$obs_pref_label[sensor_data$DESCRIPTION == 'Solar radiation'] <- 
  'solar radiation'

sensor_data$obs_prop[sensor_data$DESCRIPTION == 'Rainfall'] <- 
  'http://vocabs.lter-europe.net/EnvThes/USLterCV_443'
sensor_data$obs_pref_label[sensor_data$DESCRIPTION == 'Rainfall'] <- 
  'precipitation'

sensor_data$obs_prop[sensor_data$DESCRIPTION == 'Relative humidity'] <- 
  'http://vocabs.lter-europe.net/EnvThes/USLterCV_463'
sensor_data$obs_pref_label[sensor_data$DESCRIPTION == 'Relative humidity'] <- 
  'relative humidity'

sensor_data$obs_prop[sensor_data$DESCRIPTION == 'Soil temperature at 10cm'] <- 
  'http://vocabs.lter-europe.net/EnvThes/USLterCV_530'
sensor_data$obs_pref_label[sensor_data$DESCRIPTION == 'Soil temperature at 10cm'] <- 
  'soil temperature'

sensor_data$obs_prop[sensor_data$DESCRIPTION == 'Soil temperature at 30cm'] <- 
  'http://vocabs.lter-europe.net/EnvThes/USLterCV_530'
sensor_data$obs_pref_label[sensor_data$DESCRIPTION == 'Soil temperature at 30cm'] <- 
  'soil temperature'

sensor_data$obs_prop[sensor_data$DESCRIPTION == 'Soil moisture -  gypsum block'] <- 
  'http://vocabs.lter-europe.net/EnvThes/USLterCV_525'
sensor_data$obs_pref_label[sensor_data$DESCRIPTION == 'Soil moisture -  gypsum block'] <- 
  'soil moisture'

sensor_data$obs_prop[sensor_data$DESCRIPTION == 'Soil moisture -  volumetric water content at 20cm'] <- 
  'http://vocabs.lter-europe.net/EnvThes/USLterCV_525'
sensor_data$obs_pref_label[sensor_data$DESCRIPTION == 'Soil moisture -  volumetric water content at 20cm'] <- 
  'soil moisture'

sensor_data$obs_prop[sensor_data$DESCRIPTION == 'Soil moisture -  theta probe at 20cm'] <- 
  'http://vocabs.lter-europe.net/EnvThes/USLterCV_525'
sensor_data$obs_pref_label[sensor_data$DESCRIPTION == 'Soil moisture -  theta probe at 20cm'] <- 
  'soil moisture'

sensor_data$obs_prop[sensor_data$DESCRIPTION == 'Soil moisture -  theta probe at 10cm'] <- 
  'http://vocabs.lter-europe.net/EnvThes/USLterCV_525'
sensor_data$obs_pref_label[sensor_data$DESCRIPTION == 'Soil moisture -  theta probe at 10cm'] <- 
  'soil moisture'

sensor_data$obs_prop[sensor_data$DESCRIPTION == 'Wind direction (degrees)'] <- 
  'http://vocabs.lter-europe.net/EnvThes/USLterCV_634'
sensor_data$obs_pref_label[sensor_data$DESCRIPTION == 'Wind direction (degrees)'] <- 
  'wind direction'

sensor_data$obs_prop[sensor_data$DESCRIPTION == 'Wind speed'] <- 
  'http://vocabs.lter-europe.net/EnvThes/USLterCV_635'
sensor_data$obs_pref_label[sensor_data$DESCRIPTION == 'Wind speed'] <- 
  'wind speed'

sensor_data$obs_prop[sensor_data$DESCRIPTION == 'Wet bulb temperature'] <- 
  'http://vocabs.lter-europe.net/EnvThes/USLterCV_22'
sensor_data$obs_pref_label[sensor_data$DESCRIPTION == 'Wet bulb temperature'] <- 
  'air temperature'

sensor_data$obs_prop[sensor_data$DESCRIPTION == 'Surface wetness (no. minutes in the hour that surface is wet)'] <- 
  'http://vocabs.lter-europe.net/EnvThes/USLterCV_525'
sensor_data$obs_pref_label[sensor_data$DESCRIPTION == 'Surface wetness (no. minutes in the hour that surface is wet)'] <- 
  'soil moisture'

sensor_data$obs_prop[sensor_data$DESCRIPTION == 'Surface wetness (number of minutes in the hour that surface is wet)'] <- 
  'http://vocabs.lter-europe.net/EnvThes/USLterCV_525'
sensor_data$obs_pref_label[sensor_data$DESCRIPTION == 'Surface wetness (number of minutes in the hour that surface is wet)'] <- 
  'soil moisture'

sensor_data <- sensor_data %>%
  filter(DESCRIPTION != '')

# Set the units
sensor_data$UNIT[sensor_data$UNIT == 'degrees'] <- 'deg'
sensor_data$UNIT[sensor_data$UNIT == 'mins'] <- 'min'
sensor_data$UNIT[sensor_data$UNIT == 'oC'] <- 'Cel'

# Create the site/sensor matrix, by = SITECODE to merge on the
#  column like an inner join
site_timeseries_matrix <- merge(site_data, sensor_data, 
                                by = 'SITECODE')

site_timeseries_matrix <- merge(site_timeseries_matrix,
                                location_data,
                                by = 'SITECODE')

# GMLID
gmlid <- str_c('ECN_',site_timeseries_matrix$SITECODE,
               '_',
               site_timeseries_matrix$FIELDNAME,
               site_timeseries_matrix$RID)

# Uses the full sitename and sensor description
desc <- str_c(site_timeseries_matrix$SITECODE,
              ', ',
              site_timeseries_matrix$DESCRIPTION)

# The sensorid is created using the site and the field name
id <- str_c('/ECN/',
            site_timeseries_matrix$SITECODE,
            '/',
            site_timeseries_matrix$FIELDNAME,
            '/',
            site_timeseries_matrix$RID)

# Offering is the id+ /raw/
offering <- str_c(id,'/raw/')

# Format the input and also output values
input_name <- str_replace_all(site_timeseries_matrix$obs_pref_label,
                              ' ',
                              '')

input_op_definition <- site_timeseries_matrix$obs_prop
input_label <- input_op_definition

output_name <- input_name
output_op_definition <- input_op_definition
output_label <- input_label

# The sensor id and input name is used as the sensor name
name <- str_c(id,' (',input_name,')')

# Units vector
units <- site_timeseries_matrix$UNIT

# Make/Model for the long/short name
model <- str_extract(
  site_timeseries_matrix$MAKEMODEL,'[a-zA-Z0-9 ]*'
)

site_timeseries_matrix$MAKEMODEL[
  is.na(site_timeseries_matrix$MAKEMODEL) &
   site_timeseries_matrix$FIELDNAME == "SWATER"
  ]  = "Gypsum block bar (No make)"

site_timeseries_matrix$MAKEMODEL[
  is.na(site_timeseries_matrix$MAKEMODEL) &
    site_timeseries_matrix$FIELDNAME == "SWATER_T"
  ]  = "Theta probe (No make)"

site_timeseries_matrix$MAKEMODEL[
  is.na(site_timeseries_matrix$MAKEMODEL) &
    site_timeseries_matrix$FIELDNAME == "SWATER_T10"
  ]  = "Theta probe (No make)"

make <- str_split(site_timeseries_matrix$MAKEMODEL,
                  '\\(')


make <- sapply(make,function(i){str_extract(i[[2]],'[a-zA-Z0-9 &]*')})

model <- sub('&','and',model)
make <- sub('&','and',make)

model <- str_replace_all(str_trim(model),' ','-')
make <- str_replace_all(str_trim(make),' ','-')

# Sampling feature details
sampling_gmlid <- str_c('ECN_',site_timeseries_matrix$SITECODE)
sampling_id <- str_c('/ECN/',site_timeseries_matrix$SITECODE)
sampling_name <- site_timeseries_matrix$SITENAME

# LAT/LON taken from KMZ file rather than database coordinates,
#  difference of around 750 metres in location, change of ~ 10 metres
#  in height.
lat <- site_timeseries_matrix$LAT_WGS84
lon <- site_timeseries_matrix$LONG_WGS84


# Taken from height reading at lat/lon point on OS map
height <- site_timeseries_matrix$ALTREF

sampling_point <- str_c(lat, 
                        ' ', 
                        lon)

obs_pref_label <- site_timeseries_matrix$obs_pref_label

site_short_name = site_timeseries_matrix$SITEABBR
site_long_name = site_timeseries_matrix$SITENAME
site_domain_feature = 'http://getit-link-to-domain-feature'

# Do we change the position based on depth/height of particular sensors
#  or do we just have one set of coords and let the user infer from those?
sensors <- data.frame(cbind(gmlid, desc, id, name, offering, 
                            input_name, input_op_definition, input_label,
                            output_name, output_op_definition, output_label, units,
                            sampling_gmlid, sampling_id, sampling_name, sampling_point,
                            make, model,lat,lon,height,obs_pref_label,
                            site_short_name, site_long_name))

# This is weird, in that model has 27 NA values, but, if the model code is run again, it's fine.
sum(is.na(sensors))

# SOS server upload - sensors and templates
# ===========================================================

set.seed(1)

# Insert every site/sensor combination to the SOS server
insert_sensor_output <- sapply(1:dim(sensors)[1], function(x){
  
  xml_request <- str_c('<?xml version="1.0" encoding="UTF-8"?>
                       <swes:InsertSensor service="SOS" version="2.0.0"
                        xmlns:swes="http://www.opengis.net/swes/2.0"
                        xmlns:sos="http://www.opengis.net/sos/2.0"
                         xmlns:swe="http://www.opengis.net/swe/2.0"
                         xmlns:sml="http://www.opengis.net/sensorml/2.0"
                         xmlns:gml="http://www.opengis.net/gml/3.2"
                         xmlns:xlink="http://www.w3.org/1999/xlink"
                         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                         xmlns:gco="http://www.isotc211.org/2005/gco"
                         xmlns:gmd="http://www.isotc211.org/2005/gmd" xsi:schemaLocation="http://www.opengis.net/sos/2.0 http://schemas.opengis.net/sos/2.0/sosInsertSensor.xsd   http://www.opengis.net/swes/2.0 http://schemas.opengis.net/swes/2.0/swes.xsd">
                          <swes:procedureDescriptionFormat>http://www.opengis.net/sensorml/2.0</swes:procedureDescriptionFormat>
                            <swes:procedureDescription>
                              <sml:PhysicalSystem gml:id="',sensors$gmlid[x],'">
                                <gml:description>',sensors$desc[x],'</gml:description>
                                  <gml:identifier codeSpace="uniqueID">http://sp7.irea.cnr.it/sensors/getit.lter-europe.net/procedure',
                                    sensors$id[x],'/',sensors$make[x],'/',sensors$model[x],
                                    '/NA/2016-06-20T14:08:00/',round(runif(1,1,100)),'</gml:identifier>
                                  <gml:name>',sensors$name[x],'</gml:name>
                                  <sml:keywords>
                                    <sml:KeywordList>
                                      <sml:keyword>ECN</sml:keyword>
                                      <sml:keyword>CEH</sml:keyword>
                                      <sml:keyword>Meteorological</sml:keyword>
                                      <sml:keyword>',sensors$obs_pref_label[x],'</sml:keyword>
                                      <sml:keyword>',sensors$site_long_name[x],'</sml:keyword>
                                    </sml:KeywordList>
                                  </sml:keywords>
                                  <sml:identification>
                                    <sml:IdentifierList>
                                      <sml:identifier>
                                        <sml:Term definition="urn:ogc:def:identifier:OGC:1.0:longname">
                                          <sml:label>Long Name</sml:label>
                                          <sml:value>',str_c(sensors$make[x],': ',sensors$model[x]),'</sml:value>
                                        </sml:Term>
                                      </sml:identifier>
                                      <sml:identifier>
                                        <sml:Term definition="urn:ogc:def:identifier:OGC:1.0:shortname">
                                          <sml:label>Short Name</sml:label>
                                          <sml:value>',sensors$model[x],'</sml:value>
                                        </sml:Term>
                                      </sml:identifier>
                                    </sml:IdentifierList>
                                  </sml:identification>
                                  <sml:classification>
                                    <sml:ClassifierList>
                                      <sml:classifier>
                                        <sml:Term definition="http://sensorml.com/ont/swe/property/SensorType">
                                          <sml:label>Sensor Type</sml:label>
                                          <sml:value>',sensors$obs_pref_label[x],' sensor</sml:value>
                                        </sml:Term>
                                      </sml:classifier>
                                    </sml:ClassifierList>
                                  </sml:classification>
                                <sml:capabilities name="offerings">
                                  <sml:CapabilityList>
                                    <sml:capability name="offeringID">
                                      <swe:Text definition="urn:ogc:def:identifier:OGC:offeringID">
                                        <swe:label>offeringID</swe:label>
                                        <swe:value>',sensors$offering[x],'</swe:value>
                                      </swe:Text>
                                    </sml:capability>
                                  </sml:CapabilityList>
                                </sml:capabilities>
                                <sml:contacts>
                                  <sml:ContactList>
                                    <sml:contact xlink:title="pointOfContact" xlink:arcrole="http://inspire.ec.europa.eu/metadata-codelist/ResponsiblePartyRole/pointOfContact">
                                     <gmd:CI_ResponsibleParty>
                                       <gmd:organisationName>
                                          <gco:CharacterString>Centre for Ecology and Hydrology</gco:CharacterString>
                                       </gmd:organisationName>
                                       <gmd:contactInfo>
                                        <gmd:CI_Contact>
                                          <gmd:phone>
                                            <gmd:CI_Telephone>
                                              <gmd:voice>
                                                <gco:CharacterString>+44 (0)1524 595800</gco:CharacterString>
                                              </gmd:voice>                                        
                                            </gmd:CI_Telephone>
                                          </gmd:phone>
                                          <gmd:address>
                                            <gmd:CI_Address>
                                              <gmd:city>
                                                <gco:CharacterString>Lancaster</gco:CharacterString>
                                              </gmd:city>
                                              <gmd:postalCode>
                                                <gco:CharacterString>LA1 4AP</gco:CharacterString>
                                              </gmd:postalCode>
                                              <gmd:country>
                                                <gco:CharacterString>United Kingdom</gco:CharacterString>
                                              </gmd:country>
                                              <gmd:electronicMailAddress>
                                                <gco:CharacterString>enquiries@ceh.ac.uk</gco:CharacterString>
                                              </gmd:electronicMailAddress>
                                            </gmd:CI_Address>
                                          </gmd:address>
                                          <gmd:onlineResource>
                                            <gmd:CI_OnlineResource>
                                              <gmd:linkage>
                                                <gmd:URL>
                                                  http://www.ceh.ac.uk/lancaster
                                                </gmd:URL>
                                              </gmd:linkage>
                                            </gmd:CI_OnlineResource>
                                          </gmd:onlineResource>
                                        </gmd:CI_Contact>
                                      </gmd:contactInfo>
                                      <gmd:role>
                                        <gmd:CI_RoleCode 
                                          codeList="http://standards.iso.org/ittf/PubliclyAvailableStandards/ISO_19139_Schemas/resources/Codelist/gmxCodelists.xml#CI_RoleCode" 
                                          codeListValue="pointOfContact">
                                        </gmd:CI_RoleCode>
                                      </gmd:role>
                                    </gmd:CI_ResponsibleParty>
                                  </sml:contact>
                                </sml:ContactList>
                              </sml:contacts>
                       
                              <sml:featuresOfInterest>
                                <sml:FeatureList definition="http://www.opengis.net/def/featureOfInterest/identifier">
                                  <sml:feature xlink:href="',sensors$site_domain_feature,'"
                                    xlink:title="',sensors$site_short_name[x],'">
                                      <swe:label>',sensors$site_long_name[x],'</swe:label>
                                  </sml:feature>
                                </sml:FeatureList>
                              </sml:featuresOfInterest>
                       
                              <sml:inputs>
                                <sml:InputList>
                                  <sml:input name="',sensors$input_name[x],'">
                                    <sml:ObservableProperty definition="',sensors$input_op_definition[x],'">
                                      <swe:label>',sensors$obs_pref_label[x],'</swe:label>
                                    </sml:ObservableProperty>
                                  </sml:input>
                                </sml:InputList>    
                              </sml:inputs>
                       
                              <sml:outputs>
                                <sml:OutputList>
                                  <sml:output name="',sensors$output_name[x],'">
                                    <swe:Quantity definition="',sensors$output_op_definition[x],'">
                                      <swe:label>',sensors$obs_pref_label[x],'</swe:label>
                                      <swe:uom code="',sensors$units[x],'"/>
                                    </swe:Quantity>
                                  </sml:output>
                                </sml:OutputList>
                              </sml:outputs>
                       
                              <sml:position>
                                <swe:Vector referenceFrame="http://www.opengis.net/def/crs/EPSG/0/4979">
                                  <swe:coordinate name="northing">
                                    <swe:Quantity definition="latitude" axisID="Lat">
                                      <swe:uom xlink:href="http://vocabs.lter-europe.net/EnvThes/EUUnits_4" code="deg"/>
                                      <swe:value>',sensors$lat[x],'</swe:value>
                                    </swe:Quantity>
                                  </swe:coordinate>
                                  <swe:coordinate name="easting">
                                    <swe:Quantity definition="longitude" axisID="Lon">
                                      <swe:uom xlink:href="http://vocabs.lter-europe.net/EnvThes/EUUnits_4" code="deg"/>
                                      <swe:value>',sensors$lon[x],'</swe:value>
                                    </swe:Quantity>
                                  </swe:coordinate>
                                  <swe:coordinate name="altitude">
                                    <swe:Quantity definition="ellipsoidal height" axisID="Alt">
                                      <swe:uom xlink:href="http://vocabs.lter-europe.net/EnvThes/EUUnits_110" code="m"/>
                                      <swe:value>',sensors$height[x],'</swe:value>
                                    </swe:Quantity>
                                  </swe:coordinate>
                                </swe:Vector>
                              </sml:position>
                       
                            </sml:PhysicalSystem>
                          </swes:procedureDescription>
                          <!-- multiple values possible -->
                          <swes:observableProperty>',sensors$output_op_definition[x],'</swes:observableProperty>   
                            <swes:metadata>
                              <sos:SosInsertionMetadata>
                                <sos:observationType>http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_Measurement</sos:observationType>
                                  <!-- multiple values possible -->
                                <sos:featureOfInterestType>http://www.opengis.net/def/samplingFeatureType/OGC-OM/2.0/SF_SamplingPoint</sos:featureOfInterestType>
                              </sos:SosInsertionMetadata>
                            </swes:metadata>
                          </swes:InsertSensor>')
  
  r <- POST(url, body = xml_request, content_type('application/xml;charset=UTF-8'))
  
  print(content(r))
  print(r$status_code)
  r$status_code
  
}, simplify = TRUE, USE.NAMES = FALSE)

set.seed(1)

# Insert the result template for each sensor
insert_template_output <- sapply(1:dim(sensors)[1], function(x){
  xml_request <- str_c('<?xml version="1.0" encoding="UTF-8"?>
                       <sos:InsertResultTemplate service="SOS" version="2.0.0"
                         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                         xmlns:swes="http://www.opengis.net/swes/2.0"
                         xmlns:sos="http://www.opengis.net/sos/2.0"
                         xmlns:swe="http://www.opengis.net/swe/2.0"
                         xmlns:sml="http://www.opengis.net/sensorML/1.0.1"
                         xmlns:gml="http://www.opengis.net/gml/3.2"
                         xmlns:xlink="http://www.w3.org/1999/xlink"
                         xmlns:om="http://www.opengis.net/om/2.0"
                         xmlns:sams="http://www.opengis.net/samplingSpatial/2.0"
                         xmlns:sf="http://www.opengis.net/sampling/2.0"
                         xmlns:xs="http://www.w3.org/2001/XMLSchema" xsi:schemaLocation="http://www.opengis.net/sos/2.0 http://schemas.opengis.net/sos/2.0/sosInsertResultTemplate.xsd http://www.opengis.net/om/2.0 http://schemas.opengis.net/om/2.0/observation.xsd  http://www.opengis.net/samplingSpatial/2.0 http://schemas.opengis.net/samplingSpatial/2.0/spatialSamplingFeature.xsd">
                         <sos:proposedTemplate>
                           <!-- Before using this example, make sure that all preconditions are fulfilled, 
                           e.g. perform InsertSensor example. -->
                           <sos:ResultTemplate>
                            <swes:identifier>',sensors$id[x],'/template/1</swes:identifier>
                            <sos:offering>',sensors$offering[x],'</sos:offering>
                            <sos:observationTemplate>
                              <om:OM_Observation gml:id="',sensors$gmlid[x],'_template_1">
                                <om:type xlink:href="http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_Measurement"/>
                                <om:phenomenonTime nilReason="template"/>
                                <om:resultTime nilReason="template"/>
                                <om:procedure xlink:href="http://sp7.irea.cnr.it/sensors/getit.lter-europe.net/procedure',
                                  sensors$id[x],'/',sensors$make[x],'/',sensors$model[x],
                                  '/NA/2016-06-20T14:08:00/',round(runif(1,1,100)),'"/>
                                <om:observedProperty xlink:href="',sensors$output_op_definition[x],'"/>
                                <om:featureOfInterest>
                                  <sams:SF_SpatialSamplingFeature gml:id="',sensors$site_short_name[x],"PointParent",'">
                                    <gml:identifier codeSpace="">GetITWMSLinkPoint</gml:identifier>
                                    <gml:name>',sensors$site_long_name[x],'</gml:name>
                                    <sf:type xlink:href="http://www.opengis.net/def/samplingFeatureType/OGC-OM/2.0/SF_SamplingPoint"/>
                                    <sf:sampledFeature xlink:href="GetITWMSLinkPolygon"/>
                                      <sams:shape>
                                        <gml:Point gml:id="',sensors$site_short_name[x],"Point",'">
                                          <gml:pos srsName="http://www.opengis.net/def/crs/EPSG/0/4326">',sampling_point[x],'</gml:pos>
                                      </gml:Point>
                                    </sams:shape>
                                  </sams:SF_SpatialSamplingFeature>
                                </om:featureOfInterest>
                                <om:result/>
                              </om:OM_Observation>
                            </sos:observationTemplate>
                            <sos:resultStructure>
                              <swe:DataRecord>
                                <swe:field name="phenomenonTime">
                                  <swe:Time definition="http://www.opengis.net/def/property/OGC/0/PhenomenonTime">
                                    <swe:uom xlink:href="http://www.opengis.net/def/uom/ISO-8601/0/Gregorian"/>
                                  </swe:Time>
                                </swe:field>
                                <swe:field name="',sensors$output_name[x],'">
                                  <swe:Quantity definition="',sensors$output_op_definition[x],'">
                                   <swe:uom code="',sensors$units[x],'"/>
                                  </swe:Quantity>
                                </swe:field>
                              </swe:DataRecord>
                            </sos:resultStructure>
                            <sos:resultEncoding>
                              <swe:TextEncoding tokenSeparator="#" blockSeparator="@"/>
                            </sos:resultEncoding>
                          </sos:ResultTemplate>
                        </sos:proposedTemplate>
                      </sos:InsertResultTemplate>')
  
  r <- POST(url, body = xml_request, content_type('application/xml;charset=UTF-8'))
  
  print(r$status_code)
  print(content(r))
  r$status_code

}, simplify = TRUE, USE.NAMES = FALSE)


# SOS server upload - observations
# ===========================================================
# For every site iterate through the sensors per site in 
#  groups of #cores, with each group's sensor observations
#  sent in a different process.

start.time <- Sys.time()

for (i in 1:length(site_data$SITECODE)) {
  
  # Select the subset of sensors for the particular site
  sensor_subset <- sensor_data  %>%
    filter(SITECODE == site_data$SITECODE[i])
  
  if (dim(sensor_subset)[1] > 0) {
    
    # Split the sensors into groups of n, and for each group
    #  run n parallel processes to load the data into the
    #  system
    numCores <- 1
    sensor_seque <- seq(from = 1, to = length(sensor_subset$FIELDNAME), by = numCores)
    
    for (s in sensor_seque) {
      
      # Linux based parallelisation
      #registerDoParallel(cores = numCores)
      
      foreach(j = s:(s + (numCores - 1))) %do% {      
        sensor_obs_data <- obs_data %>%
          filter(FIELDNAME == sensor_subset$FIELDNAME[j])
        
        if (dim(sensor_obs_data)[1] > 0) {
          
          seque <- seq(from = 1,to = dim(sensor_obs_data)[1], by = 200)
          
          for (k in 1:length(seque)) {
            
            to_send <- sensor_obs_data[seque[k]:(seque[k] + 199),]
            
            na_vals <- is.na(to_send$FIELDNAME) | is.na(to_send$VALUE)
            to_send <- to_send[!na_vals,]
            
            to_send <- to_send %>%
              select(FULL_TIMESTAMP, VALUE)
            
            resVal <- paste(format(to_send$FULL_TIMESTAMP, 
                                   '%Y-%m-%dT%H:%M:%S'), 
                            '#', 
                            to_send$VALUE, 
                            '@', 
                            collapse = '',
                            sep = '')
            
            body <- list(request = "InsertResult",
                         service = "SOS",
                         version = "2.0.0",
                         templateIdentifier = str_c('/ECN/',
                                                    site_data$SITECODE[i],
                                                    '/',
                                                    sensor_subset$FIELDNAME[j],
                                                    '/',
                                                    sensor_subset$RID[j],
                                                    '/template/1'),
                         resultValues = resVal)
            
            # Attempt to send the observations up to five times, and write the output
            #  to a file as a record of what has been sent, successful or not.
            r <- NULL
            nullCount <- 0
            
            while (is.null(r) & nullCount < 5) {
              
              tryCatch({
                r <- POST(url, body = body, encode = "json",
                          timeout(180))  
                if (!is.null(r)) { 
                  if (r$status != 200) {
                    nullCount <- nullCount + 1
                    r <- NULL
                    print(str_c('Null count inc (reply): ',nullCount))
                  }else{
                    print('Observations inserted')
                  }
                }else{
                  nullCount <- nullCount + 1
                  print(str_c('Null count inc (no reply): ',nullCount))
                }
              }, error = function(e){ nullCount <- nullCount + 1},
              finally = function(){})
            }
            
            # Save the return codes into the temporary structure that will
            #  be written to disk on completion
            returnCodes <-   cbind(
              site_data$SITECODE[i],
              sensor_subset$FIELDNAME[j],
              k,
              length(seque),
              dim(to_send)[1],
              r$status_code,
              Sys.time() - start.time,
              start.time,
              Sys.time()
            )
            
            # Write out the return values for anlaysis.
            write.table(returnCodes,
                        str_c('InsertSensor',j,'.csv'),
                        append = TRUE,
                        sep = ',',
                        row.names = FALSE,
                        col.names = FALSE
            )
          } 
        }
      }
    }
  }
}