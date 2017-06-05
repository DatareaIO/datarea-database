import { Observable } from 'rxjs';
import { sync } from 'glob';
import pgrx from 'pg-reactive';
import fs from 'fs';
import path from 'path';
import _ from 'lodash';
import config from 'config';
import 'rx-from-csv';

let dest = config.get('database');
let destDB = new pgrx(dest);

destDB.tx((t) => {

  /**
   * Create database schema
   */

  let schemaFiles = [
    'sql/public/tables.sql',
    'sql/public/views.sql',
    'sql/public/material_views.sql',
    'sql/public/indexes.sql',
    'sql/public/triggers.sql',
    // 'sql/search_engine/schema.sql',
    // 'sql/search_engine/material_views.sql',
    // 'sql/search_engine/indexes.sql'
    'sql/legacy/schema.sql',
    'sql/legacy/tables.sql',
    'sql/legacy/indexes.sql',
    'sql/report/schema.sql',
    'sql/report/tables.sql',
    'sql/report/views.sql'
  ];

  let createSchema = Observable.of(...schemaFiles)
    .map((sqlPath) => fs.readFileSync(path.resolve(__dirname, sqlPath), 'utf8'))
    .reduce((schema, sql) => schema + sql, '')
    .mergeMap((schema) => t.query(schema))
    .catch((error) => {
      console.log('Unable to set up schema.');
      throw error;
    });

  /**
   * Add platforms
   */

  let addPlatforms = Observable.fromCSV(path.resolve(__dirname, 'data/platforms.csv'))
    .reduce((values, row) => {
      values.push(`('${row.name}', '${row.url}')`);
      return values;
    }, [])
    .map((values) => `INSERT INTO platform (name, url) VALUES ${values.join(',')};`)
    .mergeMap((sql) => t.query(sql))
    .catch((error) => {
      console.log('Unable to add platforms.');
      throw error;
    });

  /**
   * Add locations
   */

  let addRegions = Observable.of(...sync(path.resolve(__dirname, 'data/locations/*.geojson')))
    .map((path) => JSON.parse(fs.readFileSync(path, 'utf8')))
    .mergeMap((geojson) => {
      let feature = geojson.features[0];
      let properties = feature.properties;
      let insertNewRegion = `
        INSERT INTO location (name, continent, country, province, region, city, geom)
        VALUES ($1::text, $2::text, $3::text, $4::text, $5::text, $6::text, ST_SetSRID(ST_GeomFromGeoJSON($7::text), 4326))
        RETURNING id, name
      `;

      return t.query(insertNewRegion, [
        properties.name,
        properties.continent,
        properties.country,
        properties.province,
        properties.region,
        properties.city,
        JSON.stringify(feature.geometry)
      ]);
    })
    .catch((error) => {
      console.log('Unable to add regions.');
      throw error;
    });

  /**
   * Add portals
   */

  let addPortals = Observable.fromCSV(path.resolve(__dirname, 'data/portals.csv'))
    .reduce((values, row) => {
      let value = `
        (
          '${escape(row.name)}',
          '${row.url}',
          '${escape(row.description)}',
          (SELECT id FROM platform WHERE name = '${row.platform}'),
          (SELECT id FROM location WHERE name = '${escape(row.location)}')
        )
      `;

      values.push(value);
      return values;
    }, [])
    .map((values) => `INSERT INTO portal (name, url, description, platform_id, location_id) VALUES ${values.join(',')};`)
    .mergeMap((sql) => t.query(sql))
    .catch((error) => {
      console.log('Unable to add portals.');
      throw error;
    });

  /**
   * Add Junar portal information
   */

  let addJunarInfo = Observable.fromCSV(path.resolve(__dirname, 'data/junar_api.csv'))
    .reduce((values, row) => {
      values.push(`('${row.api_url}','${row.api_key}',(SELECT id FROM portal WHERE url = '${row.portal_url}'))`);
      return values;
    }, [])
    .map((values) => `INSERT INTO junar_portal_info (api_url, api_key, portal_id) VALUES ${values.join(',')};`)
    .mergeMap((sql) => t.query(sql))
    .catch((error) => {
      console.log('Unable to add junar apis.');
      throw error;
    });

  return Observable.merge(createSchema, addPlatforms, addRegions, addPortals, addJunarInfo, 1);
})
.subscribe(_.noop, null, () => {
  console.log('complete!');
  destDB.end();
  process.exit();
});

function escape(string) {
  if(!string) {
    return 'NULL';
  }

  return string.replace(/'/g, "''");
}
