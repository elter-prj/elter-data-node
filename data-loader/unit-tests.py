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
            {'datetime': '2015-01-01T00:00:00', 'value': 22},
            {'datetime': '2015-01-01T00:01:00', 'value': 23},
            {'datetime': '2015-01-01T00:02:00', 'value': 24},
            {'datetime': '2015-01-01T00:03:00', 'value': 25},
            {'datetime': '2015-01-01T00:04:00', 'value': 26},
            {'datetime': '2015-01-01T00:05:00', 'value': 27}
        ])

        self.bad_date = pd.DataFrame([
            {'datetime': '2015-01-01T00:00:00', 'value': 22},
            {'datetime': '2015-01-01T00:01:00', 'value': 23},
            {'datetime': '01-01-2015T00:02:00', 'value': 24},
            {'datetime': '2015-01-01T00:03:00', 'value': 25},
            {'datetime': '2015-01-01T00:04:00', 'value': 26},
            {'datetime': '2015-01-01T00:05:00', 'value': 27}
        ])

        self.bad_value = pd.DataFrame([
            {'datetime': '2015-01-01T00:00:00', 'value': 22},
            {'datetime': '2015-01-01T00:01:00', 'value': 23},
            {'datetime': '01-01-2015T00:02:00', 'value': "bad value"},
            {'datetime': '2015-01-01T00:03:00', 'value': 25},
            {'datetime': '2015-01-01T00:04:00', 'value': 26},
            {'datetime': '2015-01-01T00:05:00', 'value': 27}
        ])

        self.bad_columns_one = pd.DataFrame([
            {'datetimed': '2015-01-01T00:00:00', 'value': 22},
            {'datetime': '2015-01-01T00:01:00', 'value': 23},
            {'datetime': '01-01-2015T00:02:00', 'value': 24},
            {'datetime': '2015-01-01T00:03:00', 'value': 25},
            {'datetime': '2015-01-01T00:04:00', 'value': 26},
            {'datetime': '2015-01-01T00:05:00', 'value': 27}
        ])

        self.bad_columns_two = pd.DataFrame([
            {'datetime': '2015-01-01T00:00:00', 'value': 22, 'extra': 'test'},
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


class TestObservationDeduplication(unittest.TestCase):

    def setUp(self):

        self.ok_data = pd.DataFrame([
            {'datetime': '2015-01-01T00:00:00', 'value': 22},
            {'datetime': '2015-01-01T00:01:00', 'value': 23},
            {'datetime': '2015-01-01T00:02:00', 'value': 24},
            {'datetime': '2015-01-01T00:03:00', 'value': 25},
            {'datetime': '2015-01-01T00:04:00', 'value': 26},
            {'datetime': '2015-01-01T00:05:00', 'value': 27}
        ])

        self.duplicate_values = pd.DataFrame([
            {'datetime': '2015-01-01T00:00:00', 'value': 22},
            {'datetime': '2015-01-01T00:00:00', 'value': 23},
            {'datetime': '2015-01-01T00:02:00', 'value': 24},
            {'datetime': '2015-01-01T00:03:00', 'value': 25},
            {'datetime': '2015-01-01T00:04:00', 'value': 26},
            {'datetime': '2015-01-01T00:04:00', 'value': 27},
            {'datetime': '2015-01-01T00:05:00', 'value': 28}
        ])

    def test_observation_deduplication(self):

        # Check for no removal
        return_obs = ObLo.remove_duplicate_observations(self.ok_data)
        self.assertTrue(return_obs.shape[0] == 6)

        # Check for correct removal
        return_obs = ObLo.remove_duplicate_observations(self.duplicate_values)
        # Num obs correct
        self.assertTrue(return_obs.shape[0] == 5)
        # Values kept correct
        self.assertTrue(return_obs.loc[:, 'value'].tolist() == [23, 24, 25, 27, 28])


class TestObservationSaving(unittest.TestCase):
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

    def test_observation_send(self):
        # Mock the read object
        self.mock_url_stream_open.read.return_value = json.dumps(
            {
                "request": "InsertResult",
                "version": "2.0.0",
                "service": "SOS"
            }
        ).encode('utf-8')

        # Create the expected dictionary of the call to be made to the server
        self.insert_command = {
            "request": "InsertResult",
            "service": "SOS",
            "version": "2.0.0",
            "templateIdentifier": "http://test.template",
            "resultValues": "2017-09-27T09:00:00,22.2#2017-09-27T09:04:00,22.9#2017-09-27T09:08:00,23.5"
        }

        # Create the test set of observations
        test_dataset = pd.DataFrame([
            ["2017-09-27T09:00:00", 22.2],
            ["2017-09-27T09:04:00", 22.9],
            ["2017-09-27T09:08:00", 23.5]
        ])
        test_dataset.columns = ['datetime', 'value']

        # Send the observations to be saved
        ObLo.save_observations(test_dataset, "http://test.template", "127.0.0.1:8080/observations/service", 100)

        # Test that there was only a single call
        self.assertTrue(self.mock_request.call_count == 1)

        # Take the call and check the sent value are correct
        kall = self.mock_request.call_args
        args, kwargs = kall
        call_dict = json.loads(kwargs['data'].decode('utf-8'))

        self.assertTrue(call_dict['request'] == self.insert_command['request'])
        self.assertTrue(call_dict['service'] == self.insert_command['service'])
        self.assertTrue(call_dict['version'] == self.insert_command['version'])
        self.assertTrue(call_dict['templateIdentifier'] == self.insert_command['templateIdentifier'])
        self.assertTrue(call_dict['resultValues'] == self.insert_command['resultValues'])

        # Reset, and set side effects so that first call fails, and then three inserts are made, check all values.
        self.mock_request.reset_mock()
        self.mock_url_stream_open.reset_mock()
        bad_result = json.dumps(
            {
                "exceptions": "ManyOfThem",
                "request": "InsertResult",
                "version": "2.0.0",
                "service": "SOS"
            }
        ).encode('utf-8')

        ok_result = json.dumps(
            {
                "request": "InsertResult",
                "version": "2.0.0",
                "service": "SOS"
            }
        ).encode('utf-8')

        # Set the side effects of the mock url stream, so that the first insert fails, and the rest are OK.
        self.mock_url_stream_open.read.side_effect = [bad_result, ok_result, ok_result, ok_result, ok_result]
        ObLo.save_observations(test_dataset, "http://test.template", "127.0.0.1:8080/observations/service", 100)

        # Check for four calls, one that failed, and the three individual calls for the three observations
        self.assertTrue(self.mock_request.call_count == 4)

        # Check all the call args are correct for the first individual observation, then check the value of the second
        #  and third are correct.
        kall = self.mock_request.call_args_list[1]
        args, kwargs = kall
        call_dict = json.loads(kwargs['data'].decode('utf-8'))

        self.assertTrue(call_dict['request'] == self.insert_command['request'])
        self.assertTrue(call_dict['service'] == self.insert_command['service'])
        self.assertTrue(call_dict['version'] == self.insert_command['version'])
        self.assertTrue(call_dict['templateIdentifier'] == self.insert_command['templateIdentifier'])
        self.assertTrue(call_dict['resultValues'] == "2017-09-27T09:00:00,22.2")

        kall = self.mock_request.call_args_list[2]
        args, kwargs = kall
        call_dict = json.loads(kwargs['data'].decode('utf-8'))
        self.assertTrue(call_dict['resultValues'] == "2017-09-27T09:04:00,22.9")

        kall = self.mock_request.call_args_list[3]
        args, kwargs = kall
        call_dict = json.loads(kwargs['data'].decode('utf-8'))
        self.assertTrue(call_dict['resultValues'] == "2017-09-27T09:08:00,23.5")


if __name__ == '__main__':
    unittest.main()
