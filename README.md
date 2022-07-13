### Materialize to _the test_
#### or: Real Time Data Quality Checks Using dbt and Materialize

To run the demo set up:

```bash
docker-compose up -d
```

Connect to materialize: 
```
psql -U materialize -h localhost -p 6875 materialize
```

Connect to postgres:
```sql
psql -h localhost -p 5432 postgres postgres
```
View the prometheus metrics at http://localhost:80/

View the grafana dashboard at http://localhost:3000/

Note: I've ripped the load generator from Materialize's great ecommerce demo, [here](https://github.com/MaterializeInc/demos/tree/main/ecommerce), with the help of some work [seth](https://github.com/sjwiesman) did to translate it to postgres.