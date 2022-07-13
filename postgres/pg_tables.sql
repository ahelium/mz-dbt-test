CREATE TABLE IF NOT EXISTS users (
   id          SERIAL PRIMARY KEY,
   email       VARCHAR(255),
   is_vip      BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS items (
    id                      SERIAL PRIMARY KEY,
    item                    VARCHAR(100),
    price                   DECIMAL(7,2),
    inventory               INT
);

CREATE TABLE IF NOT EXISTS purchases (
    id              SERIAL PRIMARY KEY,
    user_id         BIGINT,
    item_id         BIGINT,
    status          INT DEFAULT 1,
    quantity        INT DEFAULT 1,
    purchase_price  DECIMAL(12,2),
    event_ts        TIMESTAMP
);

CREATE ROLE materialize REPLICATION LOGIN PASSWORD 'password';
GRANT SELECT ON users, items, purchases TO materialize;

ALTER TABLE users REPLICA IDENTITY FULL;
ALTER TABLE items REPLICA IDENTITY FULL;
ALTER TABLE purchases REPLICA IDENTITY FULL;

CREATE PUBLICATION mz_source FOR TABLE users, items, purchases;
