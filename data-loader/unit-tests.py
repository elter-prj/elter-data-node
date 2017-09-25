import json
import unittest
from unittest.mock import patch
from unittest.mock import MagicMock

import pandas as pd

import ObservationLoader as ObLo



class TestIdentifyTemplate(unittest.TestCase):
    def setUp(self):
        # Create the mock entries for the urlopen function
        # Mock stream object
        self.mock_url_stream = MagicMock(name='mock-stream')
        # Mock stream while-enter object
        self.mock_url_stream_open = MagicMock(name='url_mock')
        self.mock_url_stream.__enter__.return_value = self.mock_url_stream_open
        # Mock the info object
        self.mock_url_info = MagicMock(name='url_info')
        self.mock_url_info.get_content_charset.return_value = 'utf-8'
        self.mock_url_stream_open.info.return_value = self.mock_url_info

        # Create the patched urllib calls
        patch_urllib_request = patch('urllib.request.Request')
        patch_urllib_urlopen = patch('urllib.request.urlopen')

        # Start the patches and create the return value pointers to above mocks
        self.mock_request = patch_urllib_request.start()
        self.mock_open = patch_urllib_urlopen.start()
        self.mock_open.return_value = self.mock_url_stream

        self.addCleanup(patch_urllib_request.stop)
        self.addCleanup(patch_urllib_urlopen.stop)

    def test_template_exists(self):
        # Mock the read object
        self.mock_url_stream_open.read.return_value = json.dumps(
            {
                "request": "GetResultTemplate",
                "version": "2.0.0",
                "service": "SOS",
                "resultEncoding": {
                    "tokenSeparator": "#",
                    "blockSeparator": "@"
                },
                "resultStructure": {
                    "fields": [
                        {
                            "name": "phenomenonTime",
                            "definition": "http://www.opengis.net/def/property/OGC/0/PhenomenonTime",
                            "type": "time",
                            "uom": "http://www.opengis.net/def/uom/ISO-8601/0/Gregorian"
                        },
                        {
                            "name": "test_observable_property_9",
                            "definition": "http://www.52north.org/test/observableProperty/9_3",
                            "type": "quantity",
                            "uom": "test_unit_9"
                        }
                    ]
                }
            }
        ).encode('utf-8')
        # Make the call to identify the template
        template_id = ObLo.identify_template('test-property', 'test-offering', 'test-endpoint')

        # Check that the request sent to the SOS is correct
        data = json.dumps({'request': 'GetResultTemplate',
                           'service': 'SOS',
                           'version': '2.0.0',
                           'offering': 'test-offering',
                           'observedProperty': 'test-property'}).encode('utf-8')

        self.mock_request.assert_any_call(
            url='test-endpoint',
            data=data,
            headers={'Content-Type': 'application/json'},
            method='POST')

        # Check that the parsing of the SOS return value is correct
        self.assertTrue(template_id == 'test-property-test-offering')

    def test_template_does_not_exist(self):
        # Mock the read object
        self.mock_url_stream_open.read.return_value = json.dumps(
            {
                "version": "2.0.0",
                "exceptions": [
                    {
                        "code": "InvalidPropertyOfferingCombination",
                        "text": "For the requested combination offering (http://www.52north.org/test/offering/9) and observedProperty (http://www.52north.org/test/observableProperty/9_2) no SWE Common 2.0 encoded result values are available!"
                    }
                ]
            }
        ).encode('utf-8')
        # Make the call to identify the template
        template_id = ObLo.identify_template('test-property', 'test-offering', 'test-endpoint')

        # Check that the parsing of the SOS return value is correct
        self.assertTrue(template_id is False)


class TestTemplateCreation(unittest.TestCase):
    def setUp(self):
        # Create the mock entries for the urlopen function
        # Mock stream object
        self.mock_url_stream = MagicMock(name='mock-stream')
        # Mock stream while-enter object
        self.mock_url_stream_open = MagicMock(name='url_mock')
        self.mock_url_stream.__enter__.return_value = self.mock_url_stream_open
        # Mock the info object
        self.mock_url_info = MagicMock(name='url_info')
        self.mock_url_info.get_content_charset.return_value = 'utf-8'
        self.mock_url_stream_open.info.return_value = self.mock_url_info

        # Create the patched urllib calls
        patch_urllib_request = patch('urllib.request.Request')
        patch_urllib_urlopen = patch('urllib.request.urlopen')

        # Start the patches and create the return value pointers to above mocks
        self.mock_request = patch_urllib_request.start()
        self.mock_open = patch_urllib_urlopen.start()
        self.mock_open.return_value = self.mock_url_stream

        self.addCleanup(patch_urllib_request.stop)
        self.addCleanup(patch_urllib_urlopen.stop)

    def test_template_create(self):
        # Mock the read object
        self.mock_url_stream_open.read.return_value = json.dumps(
            {
                "request": "InsertResultTemplate",
                "version": "2.0.0",
                "service": "SOS",
                "acceptedTemplate": "test-property-test-offering"
            }
        ).encode('utf-8')

        # Make the call to identify the template
        template_metadata = {'feature_identifier': 'test-feature',
                             'feature_name': 'test-feature-name',
                             'feature_lat': 22,
                             'feature_lon': 22,
                             'result_name': 'test-result-name',
                             'result_definition': 'test-result-definition',
                             'result_unit': 'm'}

        template_id = ObLo.create_template('test-procedure',
                                           'test-property',
                                           'test-offering',
                                           template_metadata,
                                           'test-endpoint')

        # Check that the parsing of the SOS return value is correct
        self.assertTrue(template_id == 'test-property-test-offering')

        # Check that the correct template was created
        data = json.dumps({
            "request": "InsertResultTemplate",
            "service": "SOS",
            "version": "2.0.0",
            "identifier": "test-property-test-offering",
            "offering": "test-offering",
            "observationTemplate": {
                "type": "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_Measurement",
                "procedure": "test-procedure",
                "observedProperty": "test-property",
                "featureOfInterest": {
                    "identifier": {
                        "value": "test-feature",
                        "codespace": "http://www.opengis.net/def/nil/OGC/0/unknown"
                    },
                    "name": [
                        {
                            "value": "test-feature-name",
                            "codespace": "http://www.opengis.net/def/nil/OGC/0/unknown"
                        }
                    ],
                    "sampledFeature": [
                        "http://www.52north.org/test/featureOfInterest/world"
                    ],
                    "geometry": {
                        "type": "Point",
                        "coordinates": [
                            22,
                            22
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
                        "name": "test-result-name",
                        "definition": "test-result-definition",
                        "uom": "m"
                    }
                ]
            },
            "resultEncoding": {
                "tokenSeparator": ",",
                "blockSeparator": "#"
            }
        }).encode('utf-8')

        self.mock_request.assert_any_call(
            url='test-endpoint',
            data=data,
            headers={'Content-Type': 'application/json'},
            method='POST')


class TestObservationParse(unittest.TestCase):

    def setUp(self):

        self.ok_data = pd.DataFrame([
            {'datetime': '2015-01-01T00:00:00','value': 22},
            {'datetime': '2015-01-01T00:01:00', 'value': 23},
            {'datetime': '2015-01-01T00:02:00', 'value': 24},
            {'datetime': '2015-01-01T00:03:00', 'value': 25},
            {'datetime': '2015-01-01T00:04:00', 'value': 26},
            {'datetime': '2015-01-01T00:05:00', 'value': 27}
        ])

        self.bad_date = pd.DataFrame([
            {'datetime': '2015-01-01T00:00:00','value': 22},
            {'datetime': '2015-01-01T00:01:00', 'value': 23},
            {'datetime': '01-01-2015T00:02:00', 'value': 24},
            {'datetime': '2015-01-01T00:03:00', 'value': 25},
            {'datetime': '2015-01-01T00:04:00', 'value': 26},
            {'datetime': '2015-01-01T00:05:00', 'value': 27}
        ])

        self.bad_value = pd.DataFrame([
            {'datetime': '2015-01-01T00:00:00','value': 22},
            {'datetime': '2015-01-01T00:01:00', 'value': 23},
            {'datetime': '01-01-2015T00:02:00', 'value': "bad value"},
            {'datetime': '2015-01-01T00:03:00', 'value': 25},
            {'datetime': '2015-01-01T00:04:00', 'value': 26},
            {'datetime': '2015-01-01T00:05:00', 'value': 27}
        ])

        self.bad_columns_one = pd.DataFrame([
            {'datetimed': '2015-01-01T00:00:00','value': 22},
            {'datetime': '2015-01-01T00:01:00', 'value': 23},
            {'datetime': '01-01-2015T00:02:00', 'value': 24},
            {'datetime': '2015-01-01T00:03:00', 'value': 25},
            {'datetime': '2015-01-01T00:04:00', 'value': 26},
            {'datetime': '2015-01-01T00:05:00', 'value': 27}
        ])

        self.bad_columns_two = pd.DataFrame([
            {'datetime': '2015-01-01T00:00:00','value': 22, 'extra': 'test'},
            {'datetime': '2015-01-01T00:01:00', 'value': 23, 'extra': 'test'},
            {'datetime': '01-01-2015T00:02:00', 'value': 24, 'extra': 'test'},
            {'datetime': '2015-01-01T00:03:00', 'value': 25, 'extra': 'test'},
            {'datetime': '2015-01-01T00:04:00', 'value': 26, 'extra': 'test'},
            {'datetime': '2015-01-01T00:05:00', 'value': 27, 'extra': 'test'}
        ])

    def test_observation_parse(self):

        # No need to check, as if the function returns with no exception then OK
        ObLo.check_observation_parse(self.ok_data)

        with self.assertRaises(ValueError):
            ObLo.check_observation_parse(self.bad_date)

        with self.assertRaises(ValueError):
            ObLo.check_observation_parse(self.bad_value)

        with self.assertRaises(ValueError):
            ObLo.check_observation_parse(self.bad_columns_one)

        with self.assertRaises(ValueError):
            ObLo.check_observation_parse(self.bad_columns_two)


# class TestObservationSaving(unittest.TestCase):
#     def setUp(self):
#         # Create the mock entries for the urlopen function
#         # Mock stream object
#         self.mock_url_stream = MagicMock(name='mock-stream')
#         # Mock stream while-enter object
#         self.mock_url_stream_open = MagicMock(name='url_mock')
#         self.mock_url_stream.__enter__.return_value = self.mock_url_stream_open
#         # Mock the info object
#         self.mock_url_info = MagicMock(name='url_info')
#         self.mock_url_info.get_content_charset.return_value = 'utf-8'
#         self.mock_url_stream_open.info.return_value = self.mock_url_info
#
#         # Create the patched urllib calls
#         patch_urllib_request = patch('urllib.request.Request')
#         patch_urllib_urlopen = patch('urllib.request.urlopen')
#
#         # Start the patches and create the return value pointers to above mocks
#         self.mock_request = patch_urllib_request.start()
#         self.mock_open = patch_urllib_urlopen.start()
#         self.mock_open.return_value = self.mock_url_stream
#
#         self.addCleanup(patch_urllib_request.stop)
#         self.addCleanup(patch_urllib_urlopen.stop)
#
#     def test_observation_send(self):
#
#

if __name__ == '__main__':
    unittest.main()
