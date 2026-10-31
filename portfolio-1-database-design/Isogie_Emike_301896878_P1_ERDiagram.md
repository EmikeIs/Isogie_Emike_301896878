# Ride-Hailing Trip and Payment Records — ER diagram

```mermaid
erDiagram
    direction LR
    rider {
        bigint rider_id PK
        text display_name
        date joined_on
    }
    driver {
        bigint driver_id PK
        text display_name
        text vehicle_class
        boolean enabled
    }
    trip {
        bigint trip_id PK
        bigint rider_id FK
        bigint driver_id FK "Optional"
        timestamptz requested_at
        text pickup_zone
        text dropoff_zone
        numeric fare
        text status
    }
    payment {
        bigint payment_id PK
        bigint trip_id FK,UK
        numeric amount
        timestamptz paid_at
        text method
        text payment_status
    }
    rider ||--o{ trip : "rider_id"
    driver o|--o{ trip : "driver_id"
    trip ||--o| payment : "trip_id"
```

PK identifies a record; FK links to another table; UK marks a single-field unique value. The relationship ends show exactly one, zero or one, or zero or many records. Composite unique keys and conditional rules are listed in the schema and design.

[Diagram image](../images/Isogie_Emike_301896878_ERDiagram.png)
