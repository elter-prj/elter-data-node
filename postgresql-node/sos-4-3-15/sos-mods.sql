update featureofinterest set identifier = 'https://data.lter-europe.net/deims/site/bf78c96f-0763-4b31-b1a6-6eccef19edd1' where identifier = 'GetITWMSLinkPolygon';
update featureofinterest set identifier = 'moorhouse-point' where identifier = 'GetITWMSLinkPoint';
update featureofinterest set descriptionxml = replace(descriptionxml, 'GetITWMSLinkPolygon','https://data.lter-europe.net/deims/site/bf78c96f-0763-4b31-b1a6-6eccef19edd1');
update featureofinterest set descriptionxml = replace(descriptionxml, 'GetITWMSLinkPoint','moorhouse-point');


