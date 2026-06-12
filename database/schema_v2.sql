-- ═══════════════════════════════════════════════════════════
-- Travel Agency ERP — PostgreSQL Schema v2.0
-- ═══════════════════════════════════════════════════════════

-- تفعيل UUID
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ───────────────────────────────────────────────────────────
-- جدول العملاء
-- ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS customers (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name         VARCHAR(150) NOT NULL,
    phone        VARCHAR(30),
    email        VARCHAR(150),
    balance      NUMERIC(14,2) NOT NULL DEFAULT 0, -- موجب = له علينا، سالب = عليه لنا
    notes        TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ───────────────────────────────────────────────────────────
-- جدول الموردين (شركات الطيران ومكاتب التذاكر)
-- ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS suppliers (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name         VARCHAR(150) NOT NULL,
    type         VARCHAR(30) NOT NULL DEFAULT 'airline'
                 CHECK (type IN ('airline','ticketing_office','gds','other')),
    phone        VARCHAR(30),
    email        VARCHAR(150),
    balance      NUMERIC(14,2) NOT NULL DEFAULT 0,
    notes        TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ───────────────────────────────────────────────────────────
-- جدول الحجوزات (مُطوَّر)
-- ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bookings (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- معلومات التذكرة
    pnr               VARCHAR(20) NOT NULL,
    ticket_number     VARCHAR(30) UNIQUE,
    airline           VARCHAR(100),
    flight_number     VARCHAR(20),
    -- مسار الرحلة
    departure_airport VARCHAR(10),  -- IATA code
    arrival_airport   VARCHAR(10),
    departure_date    TIMESTAMPTZ NOT NULL,
    return_date       TIMESTAMPTZ,
    -- المسافر
    passenger_name    VARCHAR(150) NOT NULL,
    passenger_phone   VARCHAR(30),
    -- الحسابات
    customer_id       UUID REFERENCES customers(id),
    supplier_id       UUID REFERENCES suppliers(id),
    -- الأسعار
    cost_price        NUMERIC(12,2) NOT NULL DEFAULT 0,
    sale_price        NUMERIC(12,2) NOT NULL DEFAULT 0,
    -- حالات الدفع والحجز
    payment_status    VARCHAR(20) NOT NULL DEFAULT 'unpaid'
                      CHECK (payment_status IN ('paid','partial','unpaid')),
    booking_status    VARCHAR(30) NOT NULL DEFAULT 'pending'
                      CHECK (booking_status IN (
                        'pending','issued','cancelled',
                        'refund_requested','refund_completed')),
    notes             TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ───────────────────────────────────────────────────────────
-- جدول المدفوعات (مرتبط بالحجوزات)
-- ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS payments (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id   UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    customer_id  UUID REFERENCES customers(id),
    amount       NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    method       VARCHAR(30) NOT NULL DEFAULT 'cash'
                 CHECK (method IN ('cash','bank_transfer','card','check')),
    notes        TEXT,
    paid_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ───────────────────────────────────────────────────────────
-- جدول المرتجعات (6 مراحل)
-- ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS refunds (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id            UUID NOT NULL REFERENCES bookings(id),
    customer_id           UUID REFERENCES customers(id),
    -- بيانات العرض
    passenger_name        VARCHAR(150) NOT NULL,
    pnr                   VARCHAR(20),
    ticket_number         VARCHAR(30),
    airline               VARCHAR(100),
    -- الأرقام المالية
    original_ticket_value NUMERIC(12,2) NOT NULL DEFAULT 0,
    cancellation_fees     NUMERIC(12,2) NOT NULL DEFAULT 0,
    refund_amount         NUMERIC(12,2) NOT NULL DEFAULT 0,
    -- حالة وأولوية
    refund_status         VARCHAR(30) NOT NULL DEFAULT 'requested'
                          CHECK (refund_status IN (
                            'requested','under_review','airline_approved',
                            'refund_received','paid_to_customer','closed')),
    priority              VARCHAR(20) NOT NULL DEFAULT 'normal'
                          CHECK (priority IN ('normal','urgent','overdue')),
    -- تواريخ SLA
    requested_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    deadline_at           TIMESTAMPTZ,
    closed_at             TIMESTAMPTZ,
    notes                 TEXT
);

-- ───────────────────────────────────────────────────────────
-- جدول قيود دفتر الأستاذ (Ledger)
-- ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ledger_entries (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- نوع العملية
    type            VARCHAR(40) NOT NULL CHECK (type IN (
                      'customer_payment','supplier_payment',
                      'refund_to_customer','refund_from_airline',
                      'commission','expense','cash_deposit',
                      'cash_withdrawal','adjustment')),
    -- المبلغ والاتجاه
    amount          NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    direction       VARCHAR(10) NOT NULL CHECK (direction IN ('debit','credit')),
    -- الروابط
    booking_id      UUID REFERENCES bookings(id),
    refund_id       UUID REFERENCES refunds(id),
    customer_id     UUID REFERENCES customers(id),
    supplier_id     UUID REFERENCES suppliers(id),
    -- التفاصيل
    description     TEXT NOT NULL,
    reference       VARCHAR(100),  -- رقم مرجعي خارجي
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ───────────────────────────────────────────────────────────
-- جدول سجل العمليات (Audit Log)
-- ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_logs (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name   VARCHAR(50) NOT NULL,
    record_id    UUID NOT NULL,
    action       VARCHAR(20) NOT NULL CHECK (action IN ('insert','update','delete')),
    old_data     JSONB,
    new_data     JSONB,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════
-- الفهارس لتسريع الاستعلامات
-- ═══════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_bookings_customer    ON bookings(customer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_supplier    ON bookings(supplier_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status      ON bookings(booking_status);
CREATE INDEX IF NOT EXISTS idx_bookings_date        ON bookings(departure_date);
CREATE INDEX IF NOT EXISTS idx_bookings_pnr         ON bookings(pnr);
CREATE INDEX IF NOT EXISTS idx_bookings_passenger   ON bookings(passenger_name);
CREATE INDEX IF NOT EXISTS idx_payments_booking     ON payments(booking_id);
CREATE INDEX IF NOT EXISTS idx_refunds_booking      ON refunds(booking_id);
CREATE INDEX IF NOT EXISTS idx_refunds_status       ON refunds(refund_status);
CREATE INDEX IF NOT EXISTS idx_refunds_priority     ON refunds(priority);
CREATE INDEX IF NOT EXISTS idx_ledger_type          ON ledger_entries(type);
CREATE INDEX IF NOT EXISTS idx_ledger_customer      ON ledger_entries(customer_id);
CREATE INDEX IF NOT EXISTS idx_ledger_supplier      ON ledger_entries(supplier_id);
CREATE INDEX IF NOT EXISTS idx_ledger_created       ON ledger_entries(created_at DESC);

-- ═══════════════════════════════════════════════════════════
-- دالة تحديث updated_at تلقائياً
-- ═══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_bookings_updated
  BEFORE UPDATE ON bookings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER trg_customers_updated
  BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
