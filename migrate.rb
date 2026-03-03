require 'pg'

conn = PG.connect(
  host:     ENV['DB_HOST'],
  port:     ENV['DB_PORT'].to_i,
  user:     ENV['DB_USER'],
  password: ENV['DB_PASS'],
  dbname:   ENV['DB_NAME']
)

conn.exec(<<~SQL)
  CREATE TABLE IF NOT EXISTS greetings (
    id      INTEGER PRIMARY KEY,
    message TEXT    NOT NULL
  );
  INSERT INTO greetings (id, message)
    VALUES (1, 'Hello from Zerops!')
    ON CONFLICT (id) DO NOTHING;
SQL

puts 'Migration completed successfully'
conn.close
