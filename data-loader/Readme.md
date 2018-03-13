# Introduction

To create the Python environment, use the below command while in this folder:

`conda env create -f loader-env.yml`

Then run the following command to activate it:

`source activate loader-env`

Now you can run the unit-tests using:

`python unit-tests.py`

And call the script using, for example, the below:

`
python ObservationLoader.py 
        test-data.csv 
        http://www.52north.org/test/procedure/9
        http://www.52north.org/test/observableProperty/9_3
        http://www.52north.org/test/offering/9
        http://www.52north.org/test/featureOfInterest/9
        52North
        51
        7
        test_observable_property_9
        http://www.52north.org/test/observableProperty/9_3
        test_unit_9
        http://127.0.0.1:8080/observations/service
`

The values in the above correspond to:

    * Observation CSV file
    * Procedure URI
    * Property URI
    * Offering URI
    * Feature identifier
    * Feature name
    * Feature lat
    * Feature lon
    * Result name
    * Result definition
    * Result unit
    * SOS endpoint URI
