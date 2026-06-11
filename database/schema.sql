-- هيكل قاعدة البيانات PostgreSQL (محدّث)
-- متوافق تماماً مع الـ Models في lib/models/

CREATE TABLE bookings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    passenger_name  VARCHAR(150) NOT NULL,
    pnr             VARCHAR(20)  NOT NULL,
    ticket_number   VARCHAR(30)  NOT NULL UNIQUE,
    departure_city  VARCHAR(100) NOT NULL,
    arrival_city    VARCHAR(100) NOT NULL,
    flight_date     TIMESTAMPTZ  NOT NULL,
    status          VARCHAR(20)  NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('confirmed','cancelled','pending','refunded')),
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE finances (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id      UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    purchase_price  NUMERIC(12,2) NOT NULL CHECK (purchase_price >= 0),
    selling_price   NUMERIC(12,2) NOT NULL CHECK (selling_price >= 0),
    paid_amount     NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (paid_amount >= 0),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- المرتجعات: 4 مراحل
CREATE TABLE refunds (
    refund_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id      UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    customer_name   VARCHAR(150) NOT NULL,
    ticket_number   VARCHAR(30)  NOT NULL,
    refund_amount   NUMERIC(12,2) NOT NULL CHECK (refund_amount >= 0),
    refund_status   VARCHAR(30) NOT NULL DEFAULT 'requested'
                    CHECK (refund_status IN
                      ('requested','underReview','amountReceived','deliveredToCustomer')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- الحركات المالية (المحفظة)
CREATE TABLE transactions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type            VARCHAR(30) NOT NULL
                    CHECK (type IN ('payToSupplier','receiveFromCustomer','settlement')),
    amount          NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    note            TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_bookings_status  ON bookings(status);
CREATE INDEX idx_bookings_date    ON bookings(flight_date);
CREATE INDEX idx_finances_booking ON finances(booking_id);
CREATE INDEX idx_refunds_booking  ON refunds(booking_id);
CREATE INDEX idx_tx_created       ON transactions(created_at DESC);
