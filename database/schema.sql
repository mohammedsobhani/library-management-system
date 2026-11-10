CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'STUDENT',
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS borrowers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'STUDENT',
  photo_url TEXT
);

CREATE TABLE IF NOT EXISTS books (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  isbn TEXT NOT NULL UNIQUE,
  author TEXT,
  publisher TEXT,
  total_quantity INTEGER NOT NULL DEFAULT 1 CHECK (total_quantity >= 0),
  available_quantity INTEGER NOT NULL DEFAULT 1 CHECK (available_quantity >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS borrow_records (
  id BIGSERIAL PRIMARY KEY,
  borrower_id TEXT NOT NULL REFERENCES borrowers(id),
  book_isbn TEXT NOT NULL REFERENCES books(isbn),
  book_title TEXT NOT NULL,
  borrowed_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  due_date TIMESTAMPTZ NOT NULL,
  returned_date TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'BORROWED'
    CHECK (status IN ('BORROWED', 'RETURNED'))
);

CREATE TABLE IF NOT EXISTS system_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  details TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS borrow_records_borrower_status_idx
  ON borrow_records (borrower_id, status);
CREATE INDEX IF NOT EXISTS borrow_records_borrowed_date_idx
  ON borrow_records (borrowed_date);
CREATE INDEX IF NOT EXISTS system_logs_created_at_idx
  ON system_logs (created_at DESC);
