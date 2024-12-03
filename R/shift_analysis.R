library(dplyr)
library(dbplyr)
library(RPostgres)
library(ggplot2)

con <- dbConnect(
  RPostgres::Postgres(),
  dbname = Sys.getenv("DB_NAME"),
  host = Sys.getenv("DB_HOST"),
  port = as.integer(Sys.getenv("DB_PORT")),
  user = Sys.getenv("DB_USER"),
  password = Sys.getenv("DB_PASSWORD")
)

user_logins <- tbl(con, "EG_user_login_activity")
print(user_logins)

# Load the request_request table
request_request <- tbl(con, "request_request")

# Filter and group the data by date
daily_statistics_login <- request_request %>%
  filter(path == "/api/auth/login", method == "POST", referer == "https://tegf.netlify.app/") %>%
  mutate(date = as.Date(time)) %>%
  group_by(date) %>%
  summarise(count = n())

# Print the daily statistics
glimpse(daily_statistics_login)

# Построение графика с использованием ggplot
ggplot(daily_statistics_login, aes(x = date, y = count)) +
  geom_line() +
  geom_point() +
  labs(
    title = "Ежедневное количество записей для /api/auth/login/",
    x = "Дата",
    y = "Количество записей"
  ) +
  theme_minimal()

shift_table <- tbl(con, "EG_shift_status_history")

glimpse(shift_table)

daily_shift_statistics <- shift_table %>%
  mutate(timestamp = as.Date(timestamp)) %>%
  group_by(timestamp) %>%
  summarise(count = n())

glimpse(daily_shift_statistics)


ggplot(daily_shift_statistics, aes(x = timestamp, y = count)) +
  geom_line() +
  geom_point() +
  labs(
    title = "Ежедневное количество записей для смен",
    x = "Дата",
    y = "Количество записей"
  ) +
  theme_minimal()

