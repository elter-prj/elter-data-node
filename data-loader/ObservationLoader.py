from enum import Enum, unique
import json
import logging
import sys
import urllib.request
from urllib.error import HTTPError
import pandas as pd


# Define the meaning of the different result values
@unique
class ResultTypes(Enum):
    OBSERVATIONS_OK = 0
    MISSING_PARAMETERS = 1
    ENDPOINT_FAILURE = 2
    TEMPLATE_FAILURE = 3
    PARSE_FAILURE = 4


def prepare_observations(observations, procedure, obs_property, offering, template_metadata, endpoint):
    """Main entrypoint, takes in all the necessary parameters to save a set of observations.  It
    identifies a suitable result template at the endpoint if it exists, or creates one where
    necessary, then attempts to upload the observations as a set of results under the template.  It
    removes duplicate entries within the provided observations file, and doesn't provide feedback when
    individual observations cannot be uploaded due to an already saved observation being within the server.

    Note:
        Templates are assumed to be of the format: "ObservedPropertyValue-OfferingValue".  If they are not of this
        format the script needs updating, it is required that they be standardized in some way, using the parameters
        provided to this script.

    observations -- CSV file containing two columns in the following order: (datetime, value), where datetime is in
        the format %Y-%m-%dT%H:%M:%S, and value is numeric.
    procedure -- The procedure URI
    obs_property -- The property being observed
    offering -- The offering the procedure and property are under
    template_metadata -- A set of values necessary for registering an observation template (and an observation)
    endpoint -- The URI of the SOS service that listens for requests
    """

    try:
        # Attempt to get the URI of the template if it already exists
        logging.info("Checking if template already exists.")
        template_id = identify_template(obs_property, offering, endpoint)

        # If the template does not exist, attempt to create one
        if template_id is False:
            logging.info("Creating template.")
            template_id = create_template(procedure, obs_property, offering, template_metadata, endpoint)

        # Load the observations from the file, then remove any duplicates.  The first row should be the header.
        curr_obs = pd.read_csv(observations,
                               header=0)

        # Check that the observations conform to the expected format
        logging.info("Check observations parse OK.")
        check_observation_parse(curr_obs)

        logging.info("Drop duplicates from observations.")
        remove_duplicate_observations(curr_obs)

        # Send the observations to the function that inserts them using a ResultTemplate to batch in chunks.
        logging.info("Sending observations.")
        save_observations(curr_obs, template_id, endpoint, 200)

    except NotImplementedError:
        logging.error('The template did not exist and was unable to be registered.')
        return ResultTypes.TEMPLATE_FAILURE

    except ValueError:
        logging.error('The observation CSV column names were not correct, or too many columns, or wrong data type.')
        return ResultTypes.PARSE_FAILURE


def identify_template(obs_property, offering, endpoint):
    """Use the offering and obs_property parameters to identify whether a result template already
    exists for this observation stream.  If it does, return its identifier, if not, return False.

    Arguments:
        obs_property: The property being observed
        offering:  The offering under which the observations have been entered
        endpoint:  The URI of the SOS service that listens for requests

    Note:
        This assumes that a template has a single observed property, and that the columns
        have been registered as: (phenomenonTime, observation), so that the observation in
        the 'resultStructure' is the second entry.

    Returns:
        Either the result template string identifier, or False to indicate not found
    """

    data = {'request': 'GetResultTemplate',
                       'service': 'SOS',
                       'version': '2.0.0',
                       'offering': offering,
                       'observedProperty': obs_property}

    if send_request(data, 'exceptions', False, endpoint):
        return obs_property + "-" + offering
    else:
        return False


def create_template(procedure, obs_property, offering, template_metadata, endpoint):
    """If a template does not already exist within the SOS server, there is an attempt to create it
    in this function.  The template is encoded, sent, and if successful its ID value is returned,
    else an error is raised, as without a template this script cannot work.

    Arguments:
        procedure:  The procedure URI
        obs_property:  The property being observed
        offering:  The offering the procedure and property are under
        template_metadata:  A set of values necessary for registering an observation template (and an observation)
        endpoint:  The URI of the SOS service that listens for requests

    Raises:
        NotImplementedError:  If a template cannot be created/implemented, then this error is raised to indicate it.

    Returns:
        The result template string identifier
    """

    # Create a unique template ID - as observations can only be added through the interface, this naming convention
    #  should be OK.  It needs to involve the obs_property and offering, as these uniquely identify a template
    template_id = obs_property + "-" + offering

    template = {
        "request": "InsertResultTemplate",
        "service": "SOS",
        "version": "2.0.0",
        "identifier": template_id,
        "offering": offering,
        "observationTemplate": {
            "type": "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_Measurement",
            "procedure": procedure,
            "observedProperty": obs_property,
            "featureOfInterest": {
                "identifier": {
                    "value": template_metadata['feature_identifier'],
                    "codespace": "http://www.opengis.net/def/nil/OGC/0/unknown"
                },
                "name": [
                    {
                        "value": template_metadata['feature_name'],
                        "codespace": "http://www.opengis.net/def/nil/OGC/0/unknown"
                    }
                ],
                "sampledFeature": [
                    "http://www.52north.org/test/featureOfInterest/world"
                ],
                "geometry": {
                    "type": "Point",
                    "coordinates": [
                        template_metadata['feature_lat'],
                        template_metadata['feature_lon']
                    ],
                    "crs": {
                        "type": "name",
                        "properties": {
                            "name": "EPSG:4326"
                        }
                    }
                }
            },
            "phenomenonTime": "template",
            "resultTime": "template",
            "result": ""
        },
        "resultStructure": {
            "fields": [
                {
                    "type": "time",
                    "name": "phenomenonTime",
                    "definition": "http://www.opengis.net/def/property/OGC/0/PhenomenonTime",
                    "uom": "http://www.opengis.net/def/uom/ISO-8601/0/Gregorian"
                },
                {
                    "type": "quantity",
                    "name": template_metadata['result_name'],
                    "definition": template_metadata['result_definition'],
                    "uom": template_metadata['result_unit']
                }
            ]
        },
        "resultEncoding": {
            "tokenSeparator": ",",
            "blockSeparator": "#"
        }
    }

    if send_request(template, 'acceptedTemplate', True, endpoint):
        return template_id
    else:
        raise NotImplementedError("The template could not be created.")


def check_observation_parse(curr_obs):
    """Checks that the datetime values are OK and in the correct format, and check that all the
    observations are either numeric or null.

    Arguments:
        curr_obs:  A pandas dataframe holding the observation data

    Raises:
        ValueError:  If a value within the file does not conform to the expected types, a ValueError is raised
    """
    try:
        _ = pd.to_numeric(curr_obs['value'], errors='raise')
        _ = pd.to_datetime(curr_obs['datetime'],
                           errors='raise',
                           format='%Y-%m-%dT%H:%M:%S',
                           exact=True)
        if set(curr_obs.columns) != {'datetime', 'value'}:
            raise ValueError('The observation file has the wrong column names, or wrong columns, expects: datetime, value.')
    except Exception:
        raise ValueError('Values within the observation file do not conform to their expected type.')


def remove_duplicate_observations(curr_obs):
    """Removes observations that have duplicate timestamps, with the last observation of duplicates being the one that
    is kept.  Only the timestamp is checked, not the value, as a single sensor cannot have more than one value for the
    same sensor/property.

    Arguments:
        curr_obs:  A pandas dataframe holding the observation data

    Returns:
        A similar dataframe to that past as curr_obs, with the duplicates removed
    """
    curr_obs.drop_duplicates('datetime', keep='last', inplace=True)
    return curr_obs


def save_observations(curr_obs, result_template, endpoint, chunk_size):
    """Takes the observations parameter and opens the CSV file it represents, then inserts
    these observations against the endpoint.

    Arguments:
        curr_obs:  A Pandas DataFrame of the current set of observations to be saved
        result_template:  The template ID value to insert the observations against
        endpoint:  The endpoint URI to send requests to
        chunk_size:  The number of observations to be inserted in the same request

    """

    # Create an iterator over the observations by chunk_size
    for start_offset in range(0, curr_obs.shape[0], chunk_size):
        # Retrieve the subset of observations to put into the template, format as expected, and create template
        # Use -1 for the chunk size as difference in how list slicing and .loc slicing work with the rhs value
        curr_results = curr_obs.loc[start_offset:start_offset + (chunk_size-1), :]
        result_string = '#'.join([str(curr_ob[0]) + "," + str(curr_ob[1]) for curr_ob in curr_results.values])

        curr_template = {"request": "InsertResult",
                         "service": "SOS",
                         "version": "2.0.0",
                         "templateIdentifier": result_template,
                         "resultValues": result_string
                         }

        # If the request is successful, log and then continue iterating over the observations
        if send_request(curr_template, 'exceptions', False, endpoint):
            logging.info('Result observations inserted OK.')
        # If the request fails, it is likely due to a duplicate observation within the SOS, so the observations
        #  are attempted to be sent again but this time in chunks of 1, so only the duplicate observations are missed
        else:
            logging.info('Failed batch insert of between: {} and {}.'.format(start_offset, start_offset + chunk_size))
            # Send as results of size 1, so that any non-duplicates are added OK - only if this hasn't already been done
            if chunk_size > 1:
                save_observations(curr_results, result_template, endpoint, 1)


def send_request(data, target_key, key_status, endpoint):
    """Send the request to the sos endpoint, and check for the key_status of the key

    Arguments:
        data: an object able to be serialized into a JSON object
        target_key: the json key to look for in the return object
        key_status: whether the target_key needs to be present (True), or not (False) for this method to return True
        endpoint: the URI of the SOS server to send the request to

    Returns:
        Boolean value to indicate whether the target_key corresponded to the key_status when analyzing the return from
        the server.
    """

    # Create the custom header for the JSON content, create and encode the JSON payload
    custom_header = {'Content-Type': 'application/json'}
    data = json.dumps(data).encode('utf-8')

    # Create the request
    req = urllib.request.Request(url=endpoint, data=data, headers=custom_header, method='POST')

    try:
        # Open the request,
        with urllib.request.urlopen(req) as url_stream:
            # Retrieve the encoding and use to decode the result
            result_encoding = url_stream.info().get_content_charset('utf-8')
            result_json = json.loads(url_stream.read().decode(result_encoding))
            if (target_key in result_json) is key_status:
                return True
            else:
                return False
    except HTTPError:
        return False


if __name__ == '__main__':
    """An example entrypoint, when using the 52N SOS example InsertSensor would be:
    python ObservationLoader.py test-data.csv http://www.52north.org/test/procedure/9 
    http://www.52north.org/test/observableProperty/9_3 http://www.52north.org/test/offering/9 
    http://www.52north.org/test/featureOfInterest/9 52North 51 7 test_observable_property_9 
    http://www.52north.org/test/observableProperty/9_3 test_unit_9 
    http://127.0.0.1:8080/observations/service"""

    logging.basicConfig(level=logging.INFO)
    # It is expected that the same arguments will be provided with every file even when it is
    #  known that a template already exists
    if len(sys.argv) == 13:
        # The file with the observations inside
        observation_file = sys.argv[1]
        # The main metadata about the property and procedure used
        procedure_uri = sys.argv[2]
        property_uri = sys.argv[3]
        offering_uri = sys.argv[4]
        # Template based information
        metadata = {
            # Feature details for adding when a result template must be created
            "feature_identifier": sys.argv[5],
            "feature_name": sys.argv[6],
            "feature_lat": float(sys.argv[7]),
            "feature_lon": float(sys.argv[8]),
            # Result details for adding when a result template must be created
            "result_name": sys.argv[9],
            "result_definition": sys.argv[10],
            "result_unit": sys.argv[11]
        }

        sos_uri = sys.argv[12]

        sys.exit(
            prepare_observations(observation_file,
                                 procedure_uri,
                                 property_uri,
                                 offering_uri,
                                 metadata,
                                 sos_uri)
        )
    else:
        sys.exit(ResultTypes.MISSING_PARAMETERS)
