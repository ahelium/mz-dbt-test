{{ config(materialized='source',
    post_hook="CREATE VIEWS FROM SOURCE {{ this }} (items, users, purchases)") }}

CREATE MATERIALIZED SOURCE IF NOT EXISTS {{ this }}
	FROM POSTGRES
 	CONNECTION 'host=postgres port=5432 user=materialize password=materialize dbname=postgres'
	PUBLICATION 'mz_source'
