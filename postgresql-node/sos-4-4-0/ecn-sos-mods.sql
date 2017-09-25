-- This file has been created for use with our 3.8.x databse that is being deployed
--  to SOS 4.4.0, following its updating.  The first four feature updates are data
--  orientated removing placeholders used when creating the data in the first instance.
--  The rest of the code is part of the 4.3.x to 4.4.0 migration - and is only
--  necessary for the existing filled observation database.
update featureofinterest set identifier = 'https://data.lter-europe.net/deims/site/bf78c96f-0763-4b31-b1a6-6eccef19edd1' where identifier = 'GetITWMSLinkPolygon';
update featureofinterest set identifier = 'moorhouse-point' where identifier = 'GetITWMSLinkPoint';
update featureofinterest set descriptionxml = replace(descriptionxml, 'GetITWMSLinkPolygon','https://data.lter-europe.net/deims/site/bf78c96f-0763-4b31-b1a6-6eccef19edd1');
update featureofinterest set descriptionxml = replace(descriptionxml, 'GetITWMSLinkPoint','moorhouse-point');