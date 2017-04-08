import { Observable } from 'rxjs';
import pgrx from 'pg-reactive';
import fs from 'fs';
import path from 'path';
import _ from 'lodash';
import config from 'config';

function escape(string) {
  if(!string) {
    return 'NULL';
  }

  return string.replace(/'/g, "''");
}

let src = 'pg://odd_admin:Bko9tu39@odd-main.cfoxcbrlgeta.us-east-1.rds.amazonaws.com:5432/odd';
let dest = config.get('database');

let srcDB = new pgrx(src);
let destDB = new pgrx(dest);
let rxReadFile = Observable.bindNodeCallback(fs.readFile);

let schemaFiles = [
  'sql/public/tables.sql',
  'sql/public/views.sql',
  'sql/public/indexes.sql',
  'sql/public/triggers.sql',
  'sql/search_engine/schema.sql',
  'sql/search_engine/material_views.sql',
  'sql/search_engine/indexes.sql'
];

let createSchema = Observable.of(...schemaFiles)
  .mergeMap((sqlPath) => rxReadFile(path.resolve(__dirname, sqlPath)))
  .reduce((schema, sql) => schema + sql, '')
  // .map((schema) => 'CREATE EXTENSION postgis;' + schema)
  .mergeMap((schema) => destDB.query(schema))
  .catch((error) => {
    console.log('Unable to set up schema.');
    throw error;
  });

let addPlatforms = srcDB.query('SELECT name, website FROM platform')
  .reduce((values, row) => {
    values.push(`('${row.name}', '${row.website}')`);
    return values;
  }, [])
  .map((values) => `INSERT INTO platform (name, url) VALUES ${values.join(',')};`)
  .mergeMap((sql) => destDB.query(sql))
  .catch((error) => {
    console.log('Unable to add platforms.');
    throw error;
  });

let sql = `
  SELECT i.name, i.url, i.description, p.name AS platform, r.name AS region FROM instance AS i
  LEFT JOIN platform AS p ON p.id = i.platform_id
  LEFT JOIN instance_region_xref AS irx ON irx.instance_id = i.id
  LEFT JOIN region AS r ON r.id = irx.region_id
  WHERE i.active
`;

let addPortals = srcDB.query(sql)
  .reduce((values, row) => {
    let value = `
      (
        '${escape(row.name)}',
        '${row.url}',
        '${escape(row.description)}',
        (SELECT id FROM platform WHERE name = '${row.platform}'),
        (SELECT id FROM region WHERE name = '${escape(row.region)}')
      )
    `;

    values.push(value);
    return values;
  }, [])
  .map((values) => `INSERT INTO portal (name, url, description, platform_id, region_id) VALUES ${values.join(',')};`)
  .mergeMap((sql) => destDB.query(sql))
  .catch((error) => {
    console.log('Unable to add portals.');
    throw error;
  });

sql = `
  SELECT jii.api_url, jii.api_key, i.url FROM junar_instance_info AS jii
  LEFT JOIN instance AS i ON i.id = jii.instance_id
  WHERE i.active
`;

let addJunarInfo = srcDB.query(sql)
  .reduce((values, row) => {
    values.push(`('${row.api_url}','${row.api_key}',(SELECT id FROM portal WHERE url = '${row.url}'))`);
    return values;
  }, [])
  .map((values) => `INSERT INTO junar_portal_info (api_url, api_key, portal_id) VALUES ${values.join(',')};`)
  .mergeMap((sql) => destDB.query(sql))
  .catch((error) => {
    console.log('Unable to add junar apis.');
    throw error;
  });

sql = `
  SELECT name, continent, country, province, region, city, ST_AsText(center) FROM region
`;

let addRegions = srcDB.query(sql)
  .mergeMap((region) => {
    let insertNewRegion = `
      INSERT INTO region (name, continent, country, province, region, city, location)
      VALUES ($1::text, $2::text, $3::text, $4::text, $5::text, $6::text, ST_GeomFromText($7::text, 5432))
      RETURNING id, name
    `;

    return destDB.query(insertNewRegion, [region.name, region.continent, region.country, region.province, region.region, region.city, region.center]);
  })
  .catch((error) => {
    console.log('Unable to add regions.');
    throw error;
  });

Observable.merge(createSchema, addPlatforms, addRegions, addPortals, addJunarInfo, 1)
  .subscribe(_.noop, null, () => {
    console.log('complete!');
    process.exit();
  });
