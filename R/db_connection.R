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

# user_logins <- tbl(con, "EG_user_login_activity")
# print(user_logins)

# Load the request_request table
request_request <- tbl(con, "request_request")

# Filter and group the data by date
daily_statistics <- request_request %>%
  filter(path == "/api/v1/unicreditbank/cities/") %>%
  mutate(date = as.Date(time)) %>%
  group_by(date) %>%
  summarise(count = n())

# Print the daily statistics
glimpse(daily_statistics)

# Построение графика с использованием ggplot
ggplot(daily_statistics, aes(x = date, y = count)) +
  geom_line() +
  geom_point() +
  labs(
    title = "Ежедневное количество записей для /api/v1/unicreditbank/cities/",
    x = "Дата",
    y = "Количество записей"
  ) +
  theme_minimal()

# Рассчитаем интервалы времени между обращениями для каждого дня
# Сохраняем исходные значения interval для боксплота
request_intervals_full <- request_request %>%
  filter(path == "/api/v1/unicreditbank/cities/") %>%
  mutate(date = as.Date(time)) %>%
  group_by(date) %>%
  mutate(
    interval = sql("EXTRACT(EPOCH FROM (LEAD(time) OVER (PARTITION BY date ORDER BY time) - time))")
  ) %>%
  collect()  # Собираем все данные перед агрегацией

glimpse(request_intervals_full)

# Теперь создаём агрегированные данные для графиков средних и медианных значений
request_intervals <- request_intervals_full %>%
  summarise(
    avg_interval = mean(interval, na.rm = TRUE),
    median_interval = median(interval, na.rm = TRUE)
  ) %>%
  arrange(date)

# Выводим результаты
glimpse(request_intervals)


# Построение графика для средних и медианных интервалов
ggplot(request_intervals, aes(x = date)) +
  geom_line(aes(y = avg_interval, color = "Средний интервал"), linetype = "dashed", size = 1) +
  geom_line(aes(y = median_interval, color = "Медианный интервал"), size = 1) +
  labs(
    title = "Средние и медианные интервалы времени между обращениями",
    x = "Дата",
    y = "Интервал (в секундах)"
  ) +
  theme_minimal() +
  scale_color_manual(
    values = c("Средний интервал" = "blue", "Медианный интервал" = "red")
  )

# Построение боксплота с добавлением jitter
ggplot(request_intervals_full, aes(x = factor(date), y = interval)) +
  geom_boxplot(outlier.shape = NA) +  # Скрываем стандартные выбросы боксплота
  geom_jitter(width = 0.2, alpha = 0.5) +  # Добавляем jitter с небольшим смещением и прозрачностью
  labs(
    title = "Распределение интервалов времени между обращениями за день",
    x = "Дата",
    y = "Интервал (в секундах)"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


# Рассчитаем среднее, медиану и стандартное отклонение интервалов времени для каждого дня
request_intervals <- request_intervals_full %>%
  summarise(
    avg_interval = mean(interval, na.rm = TRUE),
    median_interval = median(interval, na.rm = TRUE),
    sd_interval = sd(interval, na.rm = TRUE)  # Вычисляем стандартное отклонение
  ) %>%
  arrange(date)

# Выводим результаты
print(request_intervals)
