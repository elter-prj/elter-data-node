-- This file has been created for use with our 3.8.x databse that is being deployed
--  to SOS 4.4.0, following its updating.  The first four feature updates are data
--  orientated removing placeholders used when creating the data in the first instance.
--  The rest of the code is part of the 4.3.x to 4.4.0 migration - and is only
--  necessary for the existing filled observation database.
update featureofinterest set identifier = 'https://data.lter-europe.net/deims/site/bf78c96f-0763-4b31-b1a6-6eccef19edd1' where identifier = 'GetITWMSLinkPolygon';
update featureofinterest set identifier = 'moorhouse-point' where identifier = 'GetITWMSLinkPoint';
update featureofinterest set descriptionxml = replace(descriptionxml, 'GetITWMSLinkPolygon','https://data.lter-europe.net/deims/site/bf78c96f-0763-4b31-b1a6-6eccef19edd1');
update featureofinterest set descriptionxml = replace(descriptionxml, 'GetITWMSLinkPoint','moorhouse-point');

-- Update commands provided by Carsten Hollman from 52North
-- https://github.com/52North/sos/issues/557
ALTER TABLE featureofinterest ALTER hibernatediscriminator TYPE character varying(255);
ALTER TABLE featureofinterest ALTER hibernatediscriminator DROP NOT NULL;
ALTER TABLE observableproperty DROP COLUMN IF EXISTS hibernatediscriminator;
UPDATE featureofinterest SET hibernatediscriminator = null;

-- The code below was taken from
-- https://github.com/52North/sos/blob/develop/misc/db/PostgreSQL/series/PG_update_43_44_series_table.sql
-- From Carsten Hollman's advice:
-- https://github.com/52North/sos/issues/557

-- Copyright (C) 2012-2017 52°North Initiative for Geospatial Open Source
-- Software GmbH
--
-- This program is free software; you can redistribute it and/or modify it
-- under the terms of the GNU General Public License version 2 as published
-- by the Free Software Foundation.
--
-- If the program is linked with libraries which are licensed under one of
-- the following licenses, the combination of the program with the linked
-- library is not considered a "derivative work" of the program:
--
--     - Apache License, version 2.0
--     - Apache Software License, version 1.0
--     - GNU Lesser General Public License, version 3
--     - Mozilla Public License, versions 1.0, 1.1 and 2.0
--     - Common Development and Distribution License (CDDL), version 1.0
--
-- Therefore the distribution of the program linked with libraries licensed
-- under the aforementioned licenses, is permitted by the copyright holders
-- if the distribution is compliant with both the GNU General Public
-- License version 2 and the aforementioned licenses.
--
-- This program is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
-- Public License for more details.
--

-- This update script fills the offeringid values in the series table.
-- !!! This script only works in the case that a each observation belongs to only one offering!!!
-- If the offeringid column is still filled with values, this statement should be omitted
update public.series ser set offeringId = (Select distinct off.offeringId from public.offering off, public.observation o, public.observationhasoffering ohof where ser.seriesid = o.seriesid AND o.observationid = ohof.observationid AND ohof.offeringId = off.offeringId);

-- Update offeringid column to NOT NULL
alter table public.series alter column offeringId set not null;

-- Set seriestype from value tables
update public.series set seriestype = 'quantity' where seriesid in (select distinct o.seriesid from public.observation o inner join public.numericvalue v on o.observationid = v.observationid);
update public.series set seriestype = 'count' where seriesid in (select distinct o.seriesid from public.observation o inner join public.countvalue v on o.observationid = v.observationid);
update public.series set seriestype = 'text' where seriesid in (select distinct o.seriesid from public.observation o inner join public.textvalue v on o.observationid = v.observationid);
update public.series set seriestype = 'category' where seriesid in (select distinct o.seriesid from public.observation o inner join public.categoryvalue v on o.observationid = v.observationid);
update public.series set seriestype = 'boolean' where seriesid in (select distinct o.seriesid from public.observation o inner join public.booleanvalue v on o.observationid = v.observationid);
