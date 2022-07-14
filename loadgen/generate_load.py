import json
import math
import os
import random
import time
from datetime import datetime, timedelta

import barnum
import psycopg2
from kafka import KafkaProducer

# CONFIG
userSeedCount = 1000
purchaseGenCount = 50000
purchaseGenEveryMS = 100
pageviewMultiplier = 10  
itemInventoryMin = 1000
itemInventoryMax = 5000
itemPriceMin = 5
itemPriceMax = 500
kafkaHostPort = os.getenv("KAFKA_ADDR", "kafka:9092")
kafkaTopic = "pageviews"
debeziumHostPort = "debezium:8083"
channels = ["organic search", "paid search", "referral", "social", "display"]
items = [
    "A",
    "B",
    "C",
    "D"
]

# INSERT TEMPLATES
item_insert = (
    "INSERT INTO public.items (item, price, inventory) VALUES ( %s, %s, %s )"
)
user_insert = "INSERT INTO public.users (email, is_vip) VALUES ( %s, %s)"
purchase_insert = "INSERT INTO public.purchases (user_id, item_id, quantity, purchase_price, event_ts) VALUES ( %s, %s, %s, %s, %s )"


# Initialize Kafka
producer = KafkaProducer(
    bootstrap_servers=[kafkaHostPort],
    value_serializer=lambda x: json.dumps(x).encode("utf-8"),
)


def generatePageview(viewer_id, user_email, target_id, page_type):
    return {
        "user_id": viewer_id,
        "email": user_email,
        "url": f"/{page_type}/{target_id}",
        "channel": random.choice(channels),
        "received_at": int(time.time()),
    }


try:
    with psycopg2.connect(
        host="postgres", port=5432, dbname="postgres", user="postgres"
    ) as connection:
        connection.autocommit = True
        with connection.cursor() as cursor:
            print("Seeding data...")
            cursor.executemany(
                item_insert,
                [
                    (
                        item,
                        random.randint(itemPriceMin * 100, itemPriceMax * 100) / 100,
                        random.randint(itemInventoryMin, itemInventoryMax),
                    )
                    for item in items
                ],
            )

            cursor.executemany(
                user_insert,
                [
                    (barnum.create_email(), (random.randint(0, 10) > 8))
                    for i in range(userSeedCount)
                ],
            )
            connection.commit()

            print("Getting item ID and PRICEs...")
            cursor.execute("SELECT id, price FROM items")
            item_prices = [(row[0], row[1]) for row in cursor]

            print("Getting users emails...")
            cursor.execute("SELECT id, email FROM users")

            users = cursor.fetchall()
            user_dict = {}
            for row in users:
                user_dict[row[0]] = row[1]

            print("Preparing to loop + seed kafka pageviews and purchases")
            start_ts = datetime.now()

            for i in range(purchaseGenCount):
                # Get a user and item to purchase
                purchase_item = random.choice(item_prices)
                purchase_user = random.randint(1, userSeedCount - 1)
                purchase_quantity = random.randint(1, 5)
                email = user_dict[purchase_user]
                print(email)

                # Write purchaser pageview
                producer.send(
                    kafkaTopic,
                    key=str(purchase_user).encode("ascii"),
                    value=generatePageview(purchase_user, email, purchase_item[0], "products"),
                )

                # Write random pageviews to products or profiles
                pageviewOscillator = int(
                    pageviewMultiplier + (math.sin(time.time() / 1000) * 50)
                )
                for i in range(pageviewOscillator):
                    rand_user = random.randint(1, userSeedCount)

                    rand_page_type = random.choice(["products", "profiles"])

                    if datetime.now() >= start_ts + timedelta(minutes=4):
                        email = ''
                    else:
                        email = user_dict[rand_user]

                    target_id_max_range = (
                        len(items) if rand_page_type == "products" else userSeedCount
                    )
                    producer.send(
                        kafkaTopic,
                        key=str(rand_user).encode("ascii"),
                        value=generatePageview(
                            rand_user,
                            email,
                            random.randint(1, target_id_max_range),
                            rand_page_type,
                        ),
                    )

                # Write purchase row
                cursor.execute(
                    purchase_insert,
                    (
                        purchase_user,
                        purchase_item[0],
                        purchase_quantity,
                        purchase_item[1] * purchase_quantity,
                        datetime.now()
                    ),
                )
                connection.commit()

                # Pause
                time.sleep(purchaseGenEveryMS / 1000)

    connection.close()

except Exception as e:
    print(e)
